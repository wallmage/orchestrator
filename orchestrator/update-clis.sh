#!/bin/sh
# Update every CLI in the table below, then report.
# Table: one CLI per line, fields split on ' :: ' (commands may contain | and ;):
#   <bin> :: <doc> :: <update cmd> :: <help cmd>[; <cmd>] :: <models cmd> :: <changelog cmd>
#   doc = file in this dir; 'file#Heading' = only that section (to the next '##'). models/changelog optional; changelog sees $OLD $NEW.
# Sections per CLI: VERSION, HELP-DIFF, MODELS-DIFF, DRIFT, CHANGELOG.
# Drift = backticked --flag in the CLI's doc region no longer in its help.
#
# AGENT PROCEDURE (after running):
# 1. `weekly` unset → ask once "Auto-run weekly? yes/no", store via `weekly <answer>`; yes → create_scheduled_task id `update-clis`, cron `0 9 * * 1`, prompt "update the CLIs".
# 2. Inspect per CLI: HELP-DIFF, MODELS-DIFF, DRIFT, CHANGELOG. Unknown subcommand/flag → run its --help.
#    BROKEN: DRIFT hit or doc runner/flag/slug removed → must fix. RELEVANT: new headless/resume/schema/sandbox/model capability → propose. NOISE → drop.
# 3. Propose unified diff vs instruction files, ≤1 line reason per hunk.
# 4. User approves per hunk. Unattended → stop, notify "CLIs updated: <versions>; <N> doc changes proposed".
# 5. Apply approved hunks. Commit. Sync installed copy. Notice: versions before→after, ≤5 bullets.
#
#   sh update-clis.sh           run
#   sh update-clis.sh weekly    print yes|no|unset
#   sh update-clis.sh weekly yes|no

CLIS=$(cat <<'EOF'
codex :: codex-cli.md :: codex update :: codex exec --help; codex exec resume --help; codex exec review --help :: jq -r '.models[].slug' ~/.codex/models_cache.json :: gh release list -R openai/codex --exclude-pre-releases -L 30 --json tagName -q '.[].tagName' | grep '^rust-v' | while read t; do [ "$t" = "rust-v${OLD##* }" ] && break; echo "## $t"; gh release view "$t" -R openai/codex --json body -q .body | grep -E '^- ' | grep -viE '^- #[0-9]'; done
codebuddy :: codebuddy-cli.md :: codebuddy update :: codebuddy --help :: codebuddy --help | grep -o 'Currently supported: ([^)]*)' :: awk -v o="$OLD" '/^## \[[0-9]/{if(index($0,o))exit; p=1} p' "$(npm root -g)/@tencent-ai/codebuddy-code/CHANGELOG.md"
grok :: SKILL.md#Grok Build CLI :: grok update :: grok --help :: grok models | grep -oE 'grok-[0-9.]+' | sort -u
EOF
)

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MARK="$HOME/.cache/orchestrator/update-clis.weekly"
if [ "$1" = weekly ]; then
  if [ -n "$2" ]; then mkdir -p "$(dirname "$MARK")"; echo "$2" > "$MARK"; fi
  cat "$MARK" 2>/dev/null || echo unset; exit 0
fi

T=${TMPDIR:-/tmp}/update-clis.$$; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
field() { printf '%s' "$1" | sed 's/ :: /\
/g' | sed -n "$2p" | sed 's/^ *//; s/ *$//'; }
flags() { grep -oE -- '(^|[^A-Za-z0-9_-])--?[A-Za-z][A-Za-z0-9-]*' "$1" | sed 's/^[^-]*//' | sort -u; }

printf '%s\n' "$CLIS" | while IFS= read -r line; do
  [ -n "$line" ] || continue
  cli=$(field "$line" 1); doc=$(field "$line" 2); upd=$(field "$line" 3); help=$(field "$line" 4)
  models=$(field "$line" 5); chlog=$(field "$line" 6)
  file="$DIR/${doc%%#*}"; sect=${doc#*#}; [ "$sect" = "$doc" ] && sect=""
  echo "=== $cli ($doc)"
  if ! command -v "$cli" >/dev/null 2>&1; then echo "SKIP: not installed"; continue; fi
  snap() { : > "$T/$cli.$1.help"; printf '%s\n' "$help" | tr ';' '\n' | while IFS= read -r c; do [ -n "$c" ] && sh -c "$c" >> "$T/$cli.$1.help" 2>&1; done
           [ -n "$models" ] && sh -c "$models" > "$T/$cli.$1.models" 2>&1; }
  OLD=$("$cli" --version 2>&1 | head -1); snap before
  sh -c "$upd" > "$T/$cli.upd" 2>&1 || echo "UPDATE FAILED (exit $?): $(tail -3 "$T/$cli.upd" | tr '\n' ' ')"
  NEW=$("$cli" --version 2>&1 | head -1); snap after
  echo "VERSION: $OLD -> $NEW"
  flags "$T/$cli.before.help" > "$T/a"; flags "$T/$cli.after.help" > "$T/b"
  add=$(comm -13 "$T/a" "$T/b" | tr '\n' ' '); rem=$(comm -23 "$T/a" "$T/b" | tr '\n' ' ')
  echo "HELP-DIFF: added [${add% }] removed [${rem% }]"
  [ -n "$models" ] && echo "MODELS-DIFF: $(diff "$T/$cli.before.models" "$T/$cli.after.models" | grep '^[<>]' | tr '\n' ' ')"
  if [ -n "$sect" ]; then region=$(awk -v h="$sect" 'p && /^##+ /{exit} index($0,"# "h)==2||index($0,"# "h)==3{p=1;next} p' "$file"); else region=$(cat "$file"); fi
  { printf '%s\n' "$region" | grep -oE '`-[^`]*`' | tr -d '`'; printf '%s\n' "$region" | grep -E "^$cli " | cut -d';' -f1; } | tr '/' '\n' | grep -oE '(^|[^A-Za-z0-9_-])--?[A-Za-z][A-Za-z0-9-]*' | sed 's/^[^-]*//' | sort -u | while read -r f; do
    grep -qE -- "(^|[^A-Za-z0-9-])$f([^A-Za-z0-9-]|$)" "$T/$cli.after.help" || echo "DRIFT: $f in $doc not in help"
  done
  [ -n "$chlog" ] && [ "$OLD" != "$NEW" ] && { echo "CHANGELOG:"; OLD="$OLD" NEW="$NEW" sh -c "$chlog" 2>&1 | head -80; }
done
exit 0
