#!/bin/bash
# Remove OTel Java agent auto-injection.
# Cleans up JAVA_TOOL_OPTIONS from system-wide config.
set -euo pipefail

echo "=== Removing JAVA_TOOL_OPTIONS setup ==="

# Remove profile script
sudo rm -f /etc/profile.d/otel-java.sh
echo "Removed /etc/profile.d/otel-java.sh"

# Remove from /etc/environment
if grep -q "JAVA_TOOL_OPTIONS" /etc/environment 2>/dev/null; then
  sudo sed -i '/JAVA_TOOL_OPTIONS/d' /etc/environment
  echo "Removed JAVA_TOOL_OPTIONS from /etc/environment"
fi

# Unset in current session
unset JAVA_TOOL_OPTIONS 2>/dev/null

echo ""
echo "=== Cleanup complete ==="
echo "Restart Java applications to stop the OTel agent from loading."
echo "The agent JAR at /opt/otel/opentelemetry-javaagent.jar is NOT deleted."
