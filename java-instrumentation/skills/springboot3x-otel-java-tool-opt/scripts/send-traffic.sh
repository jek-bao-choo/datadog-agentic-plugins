#!/bin/bash
# Send test traffic to Component C (Camel ESB mock) with 10-second intervals.
# Usage: ./send-traffic.sh [base-url]
set -euo pipefail

BASE_URL="${1:-http://localhost:8083}"
TOTAL=10
INTERVAL=10

echo "=== Sending ${TOTAL} JSON requests to ${BASE_URL}/jek-process ==="
echo "=== Interval: ${INTERVAL}s ==="
echo ""

for i in $(seq 1 ${TOTAL}); do
  TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${BASE_URL}/jek-process" \
    -H "Content-Type: application/json" \
    -H "transaction_id: TX-CAMEL-${i}" \
    -d "{\"transaction_id\": \"TX-CAMEL-${i}\", \"airway_bill_id\": \"AWB-CAMEL-${i}\"}")

  echo "[${TIMESTAMP}] Request ${i}/${TOTAL}: HTTP ${CODE}"

  if [ "${i}" -lt "${TOTAL}" ]; then
    sleep ${INTERVAL}
  fi
done

echo ""
echo "=== Done. Check Datadog APM > Traces ==="
