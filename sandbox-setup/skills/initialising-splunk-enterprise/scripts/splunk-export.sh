#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# splunk-export.sh — Export Splunk data via REST API with hourly chunking
#
# Uses the /services/search/v2/jobs/export endpoint so results stream back
# without needing to create and poll a search job.  The overall time range is
# split into 1-hour windows to avoid timeouts on large result sets.
# ---------------------------------------------------------------------------

SPLUNK_URL="${SPLUNK_URL:-https://localhost:8089}"
SPLUNK_USER="${SPLUNK_USER:-admin}"
SPLUNK_PASS="${SPLUNK_PASS:-ChangedPassword123!}"
CHUNK_SECONDS=3600  # 1 hour

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -s, --search  QUERY        SPL search query (default: "search index=main")
  -e, --earliest TIMESTAMP   Start time in epoch seconds (default: 24 hours ago)
  -l, --latest   TIMESTAMP   End time in epoch seconds   (default: now)
  -o, --output   FILE        Output file (default: splunk_export.json)
  -h, --help                 Show this help message

Environment variables:
  SPLUNK_URL   Base URL of Splunk management port (default: https://localhost:8089)
  SPLUNK_USER  Splunk username                    (default: admin)
  SPLUNK_PASS  Splunk password                    (default: ChangedPassword123!)

Examples:
  # Export the last 24 hours of index=main (defaults)
  ./splunk-export.sh

  # Custom query and time range
  ./splunk-export.sh -s "search index=main sourcetype=test_logs" \\
    -e \$(date -v-7d +%s) -l \$(date +%s)

  # Export to a specific file
  ./splunk-export.sh -o my_export.json
EOF
  exit 0
}

# -- Defaults ---------------------------------------------------------------
SEARCH="search index=main"
EARLIEST=""
LATEST=""
OUTPUT="splunk_export.json"

# -- Parse arguments --------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--search)   SEARCH="$2";   shift 2 ;;
    -e|--earliest) EARLIEST="$2"; shift 2 ;;
    -l|--latest)   LATEST="$2";   shift 2 ;;
    -o|--output)   OUTPUT="$2";   shift 2 ;;
    -h|--help)     usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

# Resolve defaults that depend on the current time
if [[ -z "$EARLIEST" ]]; then
  EARLIEST=$(date -v-24H +%s 2>/dev/null || date -d '24 hours ago' +%s)
fi
if [[ -z "$LATEST" ]]; then
  LATEST=$(date +%s)
fi

# -- Validate ---------------------------------------------------------------
if [[ "$EARLIEST" -ge "$LATEST" ]]; then
  echo "Error: earliest ($EARLIEST) must be before latest ($LATEST)" >&2
  exit 1
fi

# -- Prepare output file ----------------------------------------------------
> "$OUTPUT"  # truncate / create

TOTAL_EVENTS=0
CHUNK_NUM=0
CHUNK_START="$EARLIEST"

echo "Splunk Export"
echo "  URL:      $SPLUNK_URL"
echo "  Search:   $SEARCH"
echo "  Range:    $(date -r "$EARLIEST" 2>/dev/null || date -d "@$EARLIEST") -> $(date -r "$LATEST" 2>/dev/null || date -d "@$LATEST")"
echo "  Output:   $OUTPUT"
echo "  Chunk:    ${CHUNK_SECONDS}s (1 hour)"
echo ""

while [[ "$CHUNK_START" -lt "$LATEST" ]]; do
  CHUNK_END=$((CHUNK_START + CHUNK_SECONDS))
  if [[ "$CHUNK_END" -gt "$LATEST" ]]; then
    CHUNK_END="$LATEST"
  fi

  CHUNK_NUM=$((CHUNK_NUM + 1))
  RANGE_START=$(date -r "$CHUNK_START" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -d "@$CHUNK_START" '+%Y-%m-%d %H:%M:%S')
  RANGE_END=$(date -r "$CHUNK_END" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -d "@$CHUNK_END" '+%Y-%m-%d %H:%M:%S')
  printf "  Chunk %d: %s -> %s ... " "$CHUNK_NUM" "$RANGE_START" "$RANGE_END"

  # Stream results directly to a temp file so we can count lines
  TMPFILE=$(mktemp)
  HTTP_CODE=$(curl -s -k -o "$TMPFILE" -w "%{http_code}" \
    -u "${SPLUNK_USER}:${SPLUNK_PASS}" \
    -d "search=${SEARCH}" \
    -d "earliest_time=${CHUNK_START}" \
    -d "latest_time=${CHUNK_END}" \
    -d "output_mode=json" \
    "${SPLUNK_URL}/services/search/v2/jobs/export")

  if [[ "$HTTP_CODE" -ne 200 ]]; then
    echo "FAILED (HTTP $HTTP_CODE)"
    cat "$TMPFILE" >&2
    rm -f "$TMPFILE"
    CHUNK_START="$CHUNK_END"
    continue
  fi

  # Count non-empty lines (each line is a JSON object)
  CHUNK_EVENTS=$(grep -c '.' "$TMPFILE" 2>/dev/null || echo 0)
  TOTAL_EVENTS=$((TOTAL_EVENTS + CHUNK_EVENTS))
  echo "${CHUNK_EVENTS} lines"

  cat "$TMPFILE" >> "$OUTPUT"
  rm -f "$TMPFILE"

  CHUNK_START="$CHUNK_END"
done

echo ""
echo "Done. ${CHUNK_NUM} chunk(s), ${TOTAL_EVENTS} total lines written to ${OUTPUT}"
