#!/usr/bin/env bash
# disable-jmx-metrics.sh — Remove JMX metric flags from JAVA_TOOL_OPTIONS
# Usage: sudo ./disable-jmx-metrics.sh
#
# What it does:
#   1. Removes -Dotel.jmx.target.system=... from JAVA_TOOL_OPTIONS
#   2. Removes -Dotel.jmx.config=... from JAVA_TOOL_OPTIONS
#   3. Deletes /opt/otel/camel-jmx-metrics.yaml
#   4. Updates both /etc/profile.d/otel-java.sh and /etc/environment
#
# After running: restart your Java application for changes to take effect.

set -euo pipefail

YAML_DEST="/opt/otel/camel-jmx-metrics.yaml"
PROFILE_SCRIPT="/etc/profile.d/otel-java.sh"
ENV_FILE="/etc/environment"

# ── Step 1: Remove JMX flags from /etc/profile.d/otel-java.sh ─────
echo "==> Removing JMX flags from $PROFILE_SCRIPT"
if [ -f "$PROFILE_SCRIPT" ]; then
    # Remove -Dotel.jmx.target.system=... flag
    sed -i 's| -Dotel\.jmx\.target\.system=[^ "]*||g' "$PROFILE_SCRIPT"
    # Remove -Dotel.jmx.config=... flag
    sed -i 's| -Dotel\.jmx\.config=[^ "]*||g' "$PROFILE_SCRIPT"
    # Remove -Dspring.jmx.enabled=... flag
    sed -i 's| -Dspring\.jmx\.enabled=[^ "]*||g' "$PROFILE_SCRIPT"
    # Remove -Dserver.tomcat.mbeanregistry.enabled=... flag
    sed -i 's| -Dserver\.tomcat\.mbeanregistry\.enabled=[^ "]*||g' "$PROFILE_SCRIPT"
    echo "    Removed JMX and MBean registration flags from $PROFILE_SCRIPT"
else
    echo "    $PROFILE_SCRIPT not found — skipping"
fi

# ── Step 2: Remove JMX flags from /etc/environment ────────────────
echo "==> Removing JMX flags from $ENV_FILE"
if [ -f "$ENV_FILE" ]; then
    sed -i 's| -Dotel\.jmx\.target\.system=[^ "]*||g' "$ENV_FILE"
    sed -i 's| -Dotel\.jmx\.config=[^ "]*||g' "$ENV_FILE"
    sed -i 's| -Dspring\.jmx\.enabled=[^ "]*||g' "$ENV_FILE"
    sed -i 's| -Dserver\.tomcat\.mbeanregistry\.enabled=[^ "]*||g' "$ENV_FILE"
    echo "    Removed JMX and MBean registration flags from $ENV_FILE"
else
    echo "    $ENV_FILE not found — skipping"
fi

# ── Step 3: Delete custom YAML ────────────────────────────────────
echo "==> Removing custom YAML"
if [ -f "$YAML_DEST" ]; then
    rm -f "$YAML_DEST"
    echo "    Deleted $YAML_DEST"
else
    echo "    $YAML_DEST not found — already removed"
fi

# ── Step 4: Source updated profile ─────────────────────────────────
echo "==> Sourcing $PROFILE_SCRIPT"
if [ -f "$PROFILE_SCRIPT" ]; then
    # shellcheck disable=SC1090
    source "$PROFILE_SCRIPT"
fi

echo ""
echo "Done. JMX metrics disabled."
echo ""
echo "Current JAVA_TOOL_OPTIONS:"
echo "${JAVA_TOOL_OPTIONS:-<not set>}" | tr ' ' '\n' | sed 's/^/    /'
echo ""
echo "Next step: restart your Java application to stop JMX metric collection."
