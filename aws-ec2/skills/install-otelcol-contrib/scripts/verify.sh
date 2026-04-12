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
echo "=== 4. Sending test log ==="
TIMESTAMP_LOG_NS=$(date +%s)000000000

curl -sf -X POST http://localhost:4318/v1/logs \
  -H "Content-Type: application/json" \
  -d '{
    "resourceLogs": [{
      "resource": {
        "attributes": [{
          "key": "service.name",
          "value": {"stringValue": "jek-otel-test"}
        }]
      },
      "scopeLogs": [{
        "logRecords": [{
          "timeUnixNano": "'"${TIMESTAMP_LOG_NS}"'",
          "severityNumber": 9,
          "severityText": "INFO",
          "body": {"stringValue": "Test log from OTel Collector verify script"},
          "attributes": [{
            "key": "log.source",
            "value": {"stringValue": "verify-script"}
          }]
        }]
      }]
    }]
  }' && {
  echo "OK: Test log sent to collector"
} || {
  echo "FAIL: Could not send test log to OTLP endpoint"
  exit 1
}

echo ""
echo "=== 5. Recent collector logs ==="
sudo journalctl -u otelcol-contrib --no-pager -n 10

echo ""
echo "=== Verification complete ==="
echo "Check Datadog APM > Traces for service 'jek-otel-test' within 1-2 minutes"
echo "Check Datadog Logs for service 'jek-otel-test' within 1-2 minutes"
echo "Check Datadog Infrastructure > Host Map for host metrics within 2-3 minutes"
