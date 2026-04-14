#!/usr/bin/env bash
# enable-jmx-metrics.sh — Add JMX metric collection to existing JAVA_TOOL_OPTIONS
# Usage: sudo ./enable-jmx-metrics.sh [custom-yaml-path]
#
# What it does:
#   1. Copies camel-jmx-metrics.yaml to /opt/otel/
#   2. Adds -Dotel.jmx.target.system=tomcat,camel,jetty to JAVA_TOOL_OPTIONS
#   3. Adds -Dotel.jmx.config=/opt/otel/camel-jmx-metrics.yaml to JAVA_TOOL_OPTIONS
#   4. Updates both /etc/profile.d/otel-java.sh and /etc/environment
#
# After running: restart your Java application for changes to take effect.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
YAML_SRC="${1:-${SCRIPT_DIR}/../references/camel-jmx-metrics.yaml}"
YAML_DEST="/opt/otel/camel-jmx-metrics.yaml"
PROFILE_SCRIPT="/etc/profile.d/otel-java.sh"
ENV_FILE="/etc/environment"

JMX_FLAGS='-Dotel.jmx.target.system=tomcat,camel,jetty -Dotel.jmx.config=/opt/otel/camel-jmx-metrics.yaml -Dspring.jmx.enabled=true -Dserver.tomcat.mbeanregistry.enabled=true'

# ── Step 1: Deploy custom YAML ────────────────────────────────────
echo "==> Deploying camel-jmx-metrics.yaml to /opt/otel/"
if [ -f "$YAML_SRC" ]; then
    cp "$YAML_SRC" "$YAML_DEST"
    echo "    Copied from: $YAML_SRC"
else
    echo "    WARNING: $YAML_SRC not found — skipping custom YAML deployment"
    echo "    You can create it manually at $YAML_DEST"
    JMX_FLAGS='-Dotel.jmx.target.system=tomcat,camel,jetty -Dspring.jmx.enabled=true -Dserver.tomcat.mbeanregistry.enabled=true'
fi

# ── Step 2: Update /etc/profile.d/otel-java.sh ────────────────────
echo "==> Updating $PROFILE_SCRIPT"
if [ -f "$PROFILE_SCRIPT" ]; then
    # Check if JMX flags are already present
    if grep -q 'otel.jmx.target.system' "$PROFILE_SCRIPT"; then
        echo "    JMX flags already present in $PROFILE_SCRIPT — skipping"
    else
        # Append JMX flags to the existing JAVA_TOOL_OPTIONS value (before closing quote)
        sed -i 's|"$| '"${JMX_FLAGS}"'"|' "$PROFILE_SCRIPT"
        echo "    Added JMX flags to JAVA_TOOL_OPTIONS"
    fi
else
    echo "    ERROR: $PROFILE_SCRIPT not found"
    echo "    Run springboot3x-otel-java-tool-opt first to set up JAVA_TOOL_OPTIONS"
    exit 1
fi

# ── Step 3: Update /etc/environment ────────────────────────────────
echo "==> Updating $ENV_FILE"
if grep -q 'JAVA_TOOL_OPTIONS' "$ENV_FILE" 2>/dev/null; then
    if grep -q 'otel.jmx.target.system' "$ENV_FILE"; then
        echo "    JMX flags already present in $ENV_FILE — skipping"
    else
        sed -i 's|"$| '"${JMX_FLAGS}"'"|' "$ENV_FILE"
        echo "    Added JMX flags to JAVA_TOOL_OPTIONS"
    fi
else
    echo "    WARNING: JAVA_TOOL_OPTIONS not found in $ENV_FILE — skipping"
fi

# ── Step 4: Source updated profile ─────────────────────────────────
echo "==> Sourcing $PROFILE_SCRIPT"
# shellcheck disable=SC1090
source "$PROFILE_SCRIPT"

echo ""
echo "Done. JMX metrics enabled."
echo ""
echo "Current JAVA_TOOL_OPTIONS:"
echo "$JAVA_TOOL_OPTIONS" | tr ' ' '\n' | sed 's/^/    /'
echo ""
echo "Next step: restart your Java application for JMX metrics to take effect."
