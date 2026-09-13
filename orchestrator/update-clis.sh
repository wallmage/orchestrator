#!/bin/sh
# Update every CLI that has an instruction header in this dir's *.md, then report.
# Header (one per CLI, anywhere in a .md):
#   <!-- cli: <bin> :: update: <cmd> :: help: <cmd>[; <cmd>] :: models: <cmd> :: changelog: <cmd> -->
#   fields split on ' :: ' (commands may contain | and ;). models/changelog optional; changelog sees $OLD $NEW.
# Output = stdout only. Sections per CLI: VERSION, HELP-DIFF, MODELS-DIFF, DRIFT, CHANGELOG.
# Drift = backticked --flag in the CLI's doc region no longer in its help.
#   *-cli.md → whole file; SKILL.md → from header to next '##' heading.
#
#   sh update-clis.sh           run
#   sh update-clis.sh weekly    print yes|no|unset
#   sh update-clis.sh weekly yes|no

DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
MARK="$HOME/.cache/orchestrator/update-clis.weekly"
if [ "$1" = weekly ]; then
  if [ -n "$2" ]; then mkdir -p "$(dirname "$MARK")"; echo "$2" > "$MARK"; fi
  cat "$MARK" 2>/dev/null || echo unset; exit 0
fi

T=${TMPDIR:-/tmp}/update-clis.$$; mkdir -p "$T"; trap 'rm -rf "$T"' EXIT
field() { printf '%s' "$1" | sed 's/<!-- *//; s/ *-->//; s/ :: /\
/g' | sed -n "s/^ *$2: *//p" | sed 's/ *$//'; }
flags() { grep -oE -- '(^|[^A-Za-z0-9_-])--?[A-Za-z][A-Za-z0-9-]*' "$1" | sed 's/^[^-]*//' | sort -u; }

grep -Hn '<!-- cli:' "$DIR"/*.md | while IFS= read -r line; do
  file=${line%%:*}; rest=${line#*:}; lno=${rest%%:*}; hdr=${rest#*:}
  cli=$(field "$hdr" cli); upd=$(field "$hdr" update); help=$(field "$hdr" help)
  models=$(field "$hdr" models); chlog=$(field "$hdr" changelog)
  echo "=== $cli ($(basename "$file"))"
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
  case $(basename "$file") in
    *-cli.md) region=$(cat "$file") ;;
    *) region=$(awk -v s="$lno" 'NR>s && /^##+ /{exit} NR>=s' "$file") ;;
  esac
  printf '%s\n' "$region" | grep -oE '`-[^`]*`' | tr -d '`' | tr '/' '\n' | grep -oE '^--?[A-Za-z][A-Za-z0-9-]*' | sort -u | while read -r f; do
    grep -q -- "$f" "$T/$cli.after.help" || echo "DRIFT: $f in $(basename "$file") not in help"
  done
  [ -n "$chlog" ] && [ "$OLD" != "$NEW" ] && { echo "CHANGELOG:"; OLD="$OLD" NEW="$NEW" sh -c "$chlog" 2>&1 | head -80; }
done
