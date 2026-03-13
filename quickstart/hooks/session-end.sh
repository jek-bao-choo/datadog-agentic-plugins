#!/bin/bash
cat <<'EOF'
{"systemMessage": "Ask the user: 'Would you like me to review the PoC notes before ending this session?' If the user agrees, read the PoC notes markdown file (default: ./datadog-poc-notes.md, or the path configured in .claude/quickstart.local.md). Review for completeness and conciseness — suggest any missing information (e.g., versions not noted, limitations not documented) while keeping the file concise. Do not add verbose explanations. If the file does not exist or the session had no Datadog-related work, skip gracefully."}
EOF
