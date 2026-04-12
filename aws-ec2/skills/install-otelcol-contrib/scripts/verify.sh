#!/bin/bash
# Verify OpenTelemetry Collector Contrib is running and exporting to Datadog
set -euo pipefail

echo "=== 1. Service status ==="
sudo systemctl status otelcol-contrib --no-pager -l || {
  echo "FAIL: otelcol-contrib is not running"
  exit 1
}

echo ""
echo "=== 2. Health check ==="
HEALTH=$(curl -sf http://localhost:13133/ 2>/dev/null) && {
  echo "OK: ${HEALTH}"
} || {
  echo "FAIL: Health check endpoint not responding"
  exit 1
}

echo ""
echo "=== 3. Sending test trace ==="
TIMESTAMP_NS=$(date +%s)000000000
TIMESTAMP_END_NS=$(( $(date +%s) + 1 ))000000000

curl -sf -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{
    "resourceSpans": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "jek-otel-test"}
        }]
      },
      "scopeSpans": [{
        "spans": [{
          "traceId": "5B8EFFF798038103D269B633813FC60C",
          "spanId": "EEE19B7EC3C1B174",
          "name": "test-span-verify",
          "kind": 1,
          "startTimeUnixNano": "'"${TIMESTAMP_NS}"'",
          "endTimeUnixNano": "'"${TIMESTAMP_END_NS}"'",
          "status": {}
        }]
      }]
    }]
  }' && {
  echo "OK: Test trace sent to collector"
} || {
  echo "FAIL: Could not send test trace to OTLP endpoint"
  exit 1
}

echo ""
echo "=== 4. Recent collector logs ==="
sudo journalctl -u otelcol-contrib --no-pager -n 10

echo ""
echo "=== Verification complete ==="
echo "Check Datadog APM > Traces for service 'jek-otel-test' within 1-2 minutes"
echo "Check Datadog Infrastructure > Host Map for host metrics within 2-3 minutes"
