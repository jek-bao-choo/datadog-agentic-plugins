#!/bin/bash
# Run the Spring Boot app with OTel Java agent + XML attribute extractor extension.
# Usage: ./run-with-extension.sh [jar-path] [service-name] [port]
set -euo pipefail

JAR_PATH="${1:-/opt/cargostream/component-d/target/springboot3x-0.0.1-SNAPSHOT.jar}"
SERVICE_NAME="${2:-jek-otel-java-springboot3x}"
PORT="${3:-8084}"
OTEL_AGENT="/opt/otel/opentelemetry-javaagent.jar"
EXTENSIONS_DIR="/opt/otel/extensions"

# Verify prerequisites
[ -f "${OTEL_AGENT}" ] || { echo "ERROR: OTel agent not found at ${OTEL_AGENT}"; exit 1; }
[ -f "${EXTENSIONS_DIR}/otel-extension-xml-attributes-1.0.jar" ] || { echo "ERROR: Extension JAR not found at ${EXTENSIONS_DIR}/otel-extension-xml-attributes-1.0.jar"; exit 1; }
[ -f "${JAR_PATH}" ] || { echo "ERROR: App JAR not found at ${JAR_PATH}"; exit 1; }

echo "=== Starting ${SERVICE_NAME} on port ${PORT} ==="
echo "  OTel agent: ${OTEL_AGENT}"
echo "  Extension:  ${EXTENSIONS_DIR}/otel-extension-xml-attributes-1.0.jar"
echo "  App JAR:    ${JAR_PATH}"

java -javaagent:${OTEL_AGENT} \
  -Dloader.path=${EXTENSIONS_DIR}/ \
  -Dotel.service.name=${SERVICE_NAME} \
  -Dotel.resource.attributes=deployment.environment=sandbox,service.version=1.0.0 \
  -Dotel.exporter.otlp.endpoint=http://127.0.0.1:4318 \
  -Dotel.exporter.otlp.protocol=http/protobuf \
  -Dotel.logs.exporter=otlp \
  -Dotel.metrics.exporter=otlp \
  -jar "${JAR_PATH}" --server.port=${PORT}
