#!/bin/bash
# Send 10 requests to the Spring Boot app with 10-second intervals.
# This ensures traces are spread over ~100 seconds for visible distribution in Datadog,
# even when sampling is enabled.
# Usage: ./send-traffic.sh [base-url]
set -euo pipefail

BASE_URL="${1:-http://localhost:8084}"
TOTAL=10
INTERVAL=10

echo "=== Sending ${TOTAL} requests to ${BASE_URL}/jek-receive-xml ==="
echo "=== Interval: ${INTERVAL}s between requests ==="
echo ""

for i in $(seq 1 ${TOTAL}); do
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/jek-receive-xml" \
    -H "Content-Type: application/xml" \
    -d "<shipment><transaction_id>tx-traffic-${i}</transaction_id><airway_bill_id>awb-traffic-${i}</airway_bill_id><houseway_bill_id>hwb-traffic-${i}</houseway_bill_id><timestamp>${TIMESTAMP}</timestamp><source>send-traffic</source></shipment>")

  echo "[${TIMESTAMP}] Request ${i}/${TOTAL}: HTTP ${CODE}"

  if [ "${i}" -lt "${TOTAL}" ]; then
    sleep ${INTERVAL}
  fi
done

echo ""
echo "=== Done. ${TOTAL} requests sent over $((TOTAL * INTERVAL - INTERVAL))s ==="
echo "Check Datadog APM > Traces: service:jek-otel-java-springboot3x"
