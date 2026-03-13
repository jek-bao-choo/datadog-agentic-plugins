#!/bin/bash
# TaskCompleted hook: prompt task documentation before completing
# Uses stdin's stop_hook_active field to prevent infinite loops

INPUT=$(cat)

# If hook already fired once for this task, allow completion
HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Block completion and ask Claude to document the task
cat >&2 <<'MSG'
Before completing this task, ask the user: 'Would you like me to document the steps taken for this task?' If yes, append a concise entry to ./datadog-poc-notes.md with: a timestamp header, tech stack (languages/versions/frameworks), steps taken, problem (if any), solution, and limitations. Keep each section to 1-3 bullet points. If the task was not Datadog-related or the user declines, skip gracefully and complete the task.
MSG
exit 2
