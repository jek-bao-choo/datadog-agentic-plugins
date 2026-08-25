#!/usr/bin/env bash
# Prepare the WebSphere container for the Datadog `ibm_was` check, then restart it.
#
#   ./enable-perfservlet.sh [--no-restart]
#
# Deploys PerfServlet, sets PMI statisticSet=all, restarts the server (the PMI level only
# takes effect on restart), and verifies PerfServlet answers.
#
# Override with WAS_CONTAINER, WAS_CELL, WAS_NODE, WAS_SERVER, WAS_USER, WAS_HTTP_PORT.
set -euo pipefail

RESTART=yes
[ "${1:-}" = "--no-restart" ] && RESTART=no

CONTAINER=${WAS_CONTAINER:-was85530}
CELL=${WAS_CELL:-DefaultCell01}
NODE=${WAS_NODE:-DefaultNode01}
SERVER=${WAS_SERVER:-server1}
WSUSER=${WAS_USER:-wsadmin}
PORT=${WAS_HTTP_PORT:-9080}
WAS=/opt/IBM/WebSphere/AppServer
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Piping into `grep -q` is avoided throughout this script. `grep -q` exits on its first
# match, the writer upstream then takes SIGPIPE, and under `set -o pipefail` that makes a
# *successful* match look like a failed pipeline. Capture first, test after.
running() { [ -n "$(docker ps --filter "name=$1" --format '{{.Names}}' | grep -x "$1" || true)" ]; }

running "$CONTAINER" || { echo "ERROR: container $CONTAINER is not running" >&2; exit 1; }

echo "==> Backing up the profile configuration first"
docker exec "$CONTAINER" "$WAS/bin/backupConfig.sh" \
  /tmp/AppSrv01-pre-datadog.zip -profileName AppSrv01 -nostop >/dev/null
docker cp "$CONTAINER:/tmp/AppSrv01-pre-datadog.zip" ./AppSrv01-pre-datadog.zip
echo "    saved ./AppSrv01-pre-datadog.zip"

# Read the generated password from the container so it stays out of shell history.
PW=$(docker exec "$CONTAINER" cat /tmp/PASSWORD)
docker cp "$HERE/enable-perfservlet.py" "$CONTAINER:/tmp/enable-perfservlet.py" >/dev/null

echo "==> Deploying PerfServlet and raising PMI to 'all'"
# The `y` answers wsadmin's one-time "Add signer to the trust store now? (y/n)" prompt for
# the profile's self-signed cert. Without an answer on stdin -- and without `docker exec -i`
# to carry it -- the SOAP connection dies with "PKIX path building failed".
#
# Deliberately `printf`, not `yes`: an infinite `yes` is killed by SIGPIPE when wsadmin
# closes the pipe, and under `set -o pipefail` that exit status 141 aborts the script right
# after a *successful* deployment. A finite writer cannot race that way.
printf 'y\ny\ny\n' | docker exec -i "$CONTAINER" "$WAS/bin/wsadmin.sh" \
  -lang jython -conntype SOAP -user "$WSUSER" -password "$PW" \
  -f /tmp/enable-perfservlet.py "$CELL" "$NODE" "$SERVER" \
  | grep -E 'INFO:|OK:|ERROR|ADMA5013I|ADMA5106I' || true

if [ "$RESTART" = no ]; then
  echo "==> Skipping restart (--no-restart). PMI stays at its old level until you restart."
  exit 0
fi

echo "==> Restarting $CONTAINER gracefully"
docker stop -t 60 "$CONTAINER" >/dev/null
docker start "$CONTAINER" >/dev/null

echo "==> Waiting for the server to reopen for e-business"
READY=no
for _ in $(seq 1 60); do
  # `grep -c` consumes all of its input, so no SIGPIPE and no pipefail false negative.
  HITS=$(docker logs --since 5m "$CONTAINER" 2>&1 | grep -c 'open for e-business' || true)
  if [ "${HITS:-0}" -gt 0 ]; then READY=yes; echo "    ready"; break; fi
  running "$CONTAINER" \
    || { echo "ERROR: container exited during restart" >&2; docker logs "$CONTAINER" 2>&1 | tail -30; exit 1; }
  sleep 10
done
[ "$READY" = yes ] || { echo "ERROR: server did not reopen within 10 minutes" >&2; docker logs "$CONTAINER" 2>&1 | tail -30; exit 1; }

echo "==> Verifying PerfServlet"
URL="http://localhost:$PORT/wasPerfTool/servlet/perfservlet"

# "Server open for e-business" precedes application initialisation by several seconds, so
# the first request after a restart can return an empty reply (curl exit 52 / code 000).
# Retry rather than treating that as a hard failure.
CODE=000
for _ in $(seq 1 18); do
  CODE=$(curl -sS -o /tmp/perfservlet-check.xml -w '%{http_code}' -u "$WSUSER:$PW" "$URL" 2>/dev/null || echo 000)
  [ "$CODE" = "200" ] && break
  sleep 5
done

if [ "$CODE" != "200" ]; then
  echo "ERROR: PerfServlet returned HTTP $CODE" >&2
  echo "  000     -> no reply; the app may still be starting, or the port is wrong" >&2
  echo "  401/403 -> application security may be required for this WAS build:" >&2
  echo "     AdminConfig.modify(AdminConfig.getid('/Security:/'), [['appEnabled','true']])" >&2
  echo "  404     -> PerfServletApp did not start; check SystemOut.log" >&2
  exit 1
fi
grep -c 'PerformanceMonitor' /tmp/perfservlet-check.xml >/dev/null \
  || { echo "ERROR: HTTP 200 but the body is not PMI XML" >&2; exit 1; }

echo "OK: PerfServlet serving PMI XML at $URL"
echo "    $(wc -c < /tmp/perfservlet-check.xml) bytes"
