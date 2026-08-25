#!/usr/bin/env bash
# Deploy a WAR into the running WebSphere container and start it.
#
#   ./deploy-war.sh <file.war> [appname] [contextroot]
#
# appname and context root default to the WAR's base name, so sample.war becomes
# application "sample" at /sample - the same result as the console's Fast Path.
#
# Override with WAS_CONTAINER, WAS_CELL, WAS_NODE, WAS_SERVER, WAS_USER.
set -euo pipefail

WAR=${1:?usage: deploy-war.sh <file.war> [appname] [contextroot]}
[ -f "$WAR" ] || { echo "ERROR: no such file: $WAR" >&2; exit 1; }

BASE=$(basename "$WAR" .war)
APP=${2:-$BASE}
CTX=${3:-/$BASE}

CONTAINER=${WAS_CONTAINER:-was85530}
CELL=${WAS_CELL:-DefaultCell01}
NODE=${WAS_NODE:-DefaultNode01}
SERVER=${WAS_SERVER:-server1}
WSUSER=${WAS_USER:-wsadmin}
WAS=/opt/IBM/WebSphere/AppServer
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

docker ps --filter "name=$CONTAINER" --format '{{.Names}}' | grep -qx "$CONTAINER" \
  || { echo "ERROR: container $CONTAINER is not running" >&2; exit 1; }

# Read the generated password out of the container instead of taking it as an argument,
# so it stays out of shell history. It is still visible in the container's process list
# while wsadmin runs - acceptable for a local dev box, not for a shared host.
PW=$(docker exec "$CONTAINER" cat /tmp/PASSWORD)

docker cp "$WAR" "$CONTAINER:/tmp/$BASE.war"
docker cp "$HERE/deploy-war.py" "$CONTAINER:/tmp/deploy-war.py"

# `yes y` answers the one-time "Add signer to the trust store now? (y/n)" prompt that
# wsadmin's SOAP client raises against the profile's self-signed certificate. Without an
# answer on stdin - and without `docker exec -i` to carry it - the connection fails with
# "PKIX path building failed" and ConnectorNotAvailableException.
yes y | docker exec -i "$CONTAINER" "$WAS/bin/wsadmin.sh" \
  -lang jython -conntype SOAP -user "$WSUSER" -password "$PW" \
  -f /tmp/deploy-war.py "/tmp/$BASE.war" "$APP" "$CTX" "$CELL" "$NODE" "$SERVER"

echo
echo "HTTP   http://localhost:9080$CTX/"
echo "HTTPS  https://localhost:9443$CTX/"
