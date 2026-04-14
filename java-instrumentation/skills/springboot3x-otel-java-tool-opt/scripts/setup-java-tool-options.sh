#!/bin/bash
# Setup OTel Java agent auto-injection via JAVA_TOOL_OPTIONS.
# This is the OTel equivalent of Dynatrace's LD_PRELOAD injection.
# After running this, any Java process on the host picks up the OTel agent automatically.
#
# Usage: sudo ./setup-java-tool-options.sh [collector-endpoint]
set -euo pipefail

OTEL_AGENT_VERSION="2.26.1"
OTEL_AGENT_PATH="/opt/otel/opentelemetry-javaagent.jar"
COLLECTOR_ENDPOINT="${1:-http://127.0.0.1:4318}"

echo "=== Step 1: Download OTel Java agent v${OTEL_AGENT_VERSION} ==="
sudo mkdir -p /opt/otel
if [ -f "${OTEL_AGENT_PATH}" ]; then
  echo "Agent already exists at ${OTEL_AGENT_PATH}"
else
  sudo curl -L -o "${OTEL_AGENT_PATH}" \
    "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_AGENT_VERSION}/opentelemetry-javaagent.jar"
  echo "Downloaded to ${OTEL_AGENT_PATH}"
fi
ls -lh "${OTEL_AGENT_PATH}"

echo ""
echo "=== Step 2: Create system-wide JAVA_TOOL_OPTIONS ==="

# For login shells (ssh, terminal)
sudo tee /etc/profile.d/otel-java.sh > /dev/null <<EOF
# OTel Java agent auto-injection — equivalent to Dynatrace LD_PRELOAD
# Every Java process on this host picks up the agent automatically.
# Per-app service name: set OTEL_SERVICE_NAME env var or spring.application.name property.
export JAVA_TOOL_OPTIONS="-javaagent:${OTEL_AGENT_PATH} -Dotel.javaagent.extensions=/opt/otel/extensions/otel-dsm-extension-1.0.jar -Dloader.path=/opt/otel/extensions/ -Dotel.exporter.otlp.endpoint=${COLLECTOR_ENDPOINT} -Dotel.exporter.otlp.protocol=http/protobuf -Dotel.logs.exporter=otlp -Dotel.metrics.exporter=otlp -Dotel.instrumentation.http.server.capture-request-headers=transaction_id -Dotel.instrumentation.http.server.capture-response-headers=transaction_id"
EOF

# For non-login shells (systemd services)
if ! grep -q "JAVA_TOOL_OPTIONS" /etc/environment 2>/dev/null; then
  echo "JAVA_TOOL_OPTIONS=\"-javaagent:${OTEL_AGENT_PATH} -Dotel.javaagent.extensions=/opt/otel/extensions/otel-dsm-extension-1.0.jar -Dloader.path=/opt/otel/extensions/ -Dotel.exporter.otlp.endpoint=${COLLECTOR_ENDPOINT} -Dotel.exporter.otlp.protocol=http/protobuf -Dotel.logs.exporter=otlp -Dotel.metrics.exporter=otlp -Dotel.instrumentation.http.server.capture-request-headers=transaction_id -Dotel.instrumentation.http.server.capture-response-headers=transaction_id\"" | sudo tee -a /etc/environment > /dev/null
fi

echo ""
echo "=== Setup complete ==="
echo ""
echo "JAVA_TOOL_OPTIONS is now set system-wide."
echo "Restart any Java application to pick up the OTel agent."
echo ""
echo "To set the service name per app, use one of:"
echo "  export OTEL_SERVICE_NAME=my-service"
echo "  -Dotel.service.name=my-service (in JAVA_OPTS)"
echo "  spring.application.name=my-service (in application.properties)"
echo ""
echo "To verify: start any Java process and look for:"
echo "  'Picked up JAVA_TOOL_OPTIONS: -javaagent:/opt/otel/...'"
