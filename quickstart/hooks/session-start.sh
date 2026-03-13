#!/bin/bash
cat <<'EOF'
{"systemMessage": "Welcome the user to Datadog PoC Quickstart. Display this brief message:\n\n**Datadog PoC Quickstart** is ready.\n\n- Type `/quickstart:menu` to see the full use case menu\n- Or just describe what you need — I'll find the right Datadog docs\n- Type `/resume` to continue a previous task\n\nDo NOT display the full 26-item menu. Just show the brief welcome above and wait for the user."}
EOF
