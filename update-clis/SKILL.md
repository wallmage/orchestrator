---
name: update-clis
description: Update every CLI the orchestrator has instructions for, inspect changes, propose instruction edits. Use on "/update-clis" or "update the CLIs".
---

Claude Code wrapper. Skill dir = `~/.claude/skills/orchestrator`. Follow `update-clis.md` there.

Weekly (step 1) here: `yes` → `create_scheduled_task` taskId `update-clis`, cron `0 9 * * 1`, prompt `/update-clis`, description "Weekly CLI update + instruction drift check". Args `weekly on|off` → write marker, create/delete the task.
