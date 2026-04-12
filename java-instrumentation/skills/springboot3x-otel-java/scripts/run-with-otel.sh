#!/bin/bash
# Run a Spring Boot 3.x application with the OTel Java agent for auto-instrumentation.
# Usage: ./run-with-otel.sh <path-to-jar> [service-name] [port]
set -euo pipefail

JAR_PATH="${1:?Usage: ./run-with-otel.sh <path-to-jar> [service-name] [port]}"
SERVICE_NAME="${2:-jek-otel-java-springboot3x}"
PORT="${3:-8084}"
OTEL_AGENT="/opt/otel/opentelemetry-javaagent.jar"
OTEL_AGENT_VERSION="2.26.1"

# Download agent if not present
if [ ! -f "${OTEL_AGENT}" ]; then
  echo "=== Downloading OTel Java agent v${OTEL_AGENT_VERSION} ==="
  mkdir -p /opt/otel
  curl -L -o "${OTEL_AGENT}" \
    "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_AGENT_VERSION}/opentelemetry-javaagent.jar"
fi

echo "=== Starting ${SERVICE_NAME} on port ${PORT} with OTel Java agent ==="

java -javaagent:${OTEL_AGENT} \
  -Dotel.service.name=${SERVICE_NAME} \
  -Dotel.resource.attributes=deployment.environment=sandbox,service.version=1.0.0 \
  -Dotel.exporter.otlp.endpoint=http://localhost:4318 \
  -Dotel.exporter.otlp.protocol=http/protobuf \
  -Dotel.logs.exporter=otlp \
  -Dotel.metrics.exporter=otlp \
  -jar "${JAR_PATH}" --server.port=${PORT}
