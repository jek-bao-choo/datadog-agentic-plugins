#!/usr/bin/env bash
# Start a dedicated containerised Datadog Agent that monitors the WebSphere container.
#
#   DD_API_KEY=<key> ./run-dd-agent.sh
#   DD_API_KEY=<key> DD_SITE=datadoghq.eu ./run-dd-agent.sh
#
# A container Agent rather than a host install, for two reasons:
#   1. A corporate/MDM-managed host Agent must not be repurposed - see SKILL.md.
#   2. Only an Agent on the Docker host can read the WAS log volume. On macOS the volume
#      lives inside the Colima VM, invisible to the host filesystem.
#
# Override with WAS_CONTAINER, WAS_LOG_VOLUME, DD_HOSTNAME, AGENT_CONTAINER, DD_NETWORK.
set -euo pipefail

: "${DD_API_KEY:?set DD_API_KEY (do not hardcode it in this file)}"
DD_SITE=${DD_SITE:-datadoghq.com}

CONTAINER=${WAS_CONTAINER:-was85530}
LOG_VOLUME=${WAS_LOG_VOLUME:-was85530-logs}
AGENT=${AGENT_CONTAINER:-dd-agent}
NETWORK=${DD_NETWORK:-dd-was}
DD_HOSTNAME=${DD_HOSTNAME:-${CONTAINER}-lab}
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Never pipe into `grep -q` here: it exits on first match, the writer takes SIGPIPE, and
# `set -o pipefail` then reports a successful match as a failed pipeline.
running() { [ -n "$(docker ps --filter "name=$1" --format '{{.Names}}' | grep -x "$1" || true)" ]; }

running "$CONTAINER" || { echo "ERROR: container $CONTAINER is not running" >&2; exit 1; }

# A user-defined network gives DNS by container name. The default bridge does not, and its
# IPs move between restarts. `network connect` attaches the *running* WebSphere container -
# no recreate, so no configuration is lost from its container layer.
docker network inspect "$NETWORK" >/dev/null 2>&1 || docker network create "$NETWORK" >/dev/null
ATTACHED=$(docker inspect "$CONTAINER" --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}' \
     | tr ' ' '\n' | grep -x "$NETWORK" || true)
if [ -z "$ATTACHED" ]; then
  docker network connect "$NETWORK" "$CONTAINER"
  echo "==> Attached $CONTAINER to network $NETWORK"
fi

# The check config expects to reach WebSphere by container name on that network.
#
# Rendered under $HOME on purpose. Do NOT use `mktemp -d`: on macOS that returns
# /var/folders/..., which Colima does not share into its VM (default `mounts: []` shares
# only $HOME). The bind mount then silently resolves to an EMPTY directory, the Agent comes
# up healthy with a valid API key, and the check never loads. $HOME is shared, so it works.
CONF_DIR=${DD_CONF_DIR:-$HOME/.websphere-dd-lab/ibm_was.d}
mkdir -p "$CONF_DIR"
sed -e "s|@WAS_CONTAINER@|$CONTAINER|g" "$HERE/ibm_was.d/conf.yaml" > "$CONF_DIR/conf.yaml"
echo "==> Rendered check config to $CONF_DIR/conf.yaml"

docker rm -f "$AGENT" >/dev/null 2>&1 || true

docker run -d --name "$AGENT" \
  --network "$NETWORK" \
  -e DD_API_KEY="$DD_API_KEY" \
  -e DD_SITE="$DD_SITE" \
  -e DD_HOSTNAME="$DD_HOSTNAME" \
  -e DD_LOGS_ENABLED=true \
  -e DD_TAGS="env:local project:websphere-lab" \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v "$LOG_VOLUME:/was-logs:ro" \
  -v "$CONF_DIR:/etc/datadog-agent/conf.d/ibm_was.d:ro" \
  gcr.io/datadoghq/agent:7 >/dev/null

echo "==> Waiting for the Agent to report healthy"
for _ in $(seq 1 24); do
  [ "$(docker inspect "$AGENT" --format '{{.State.Health.Status}}' 2>/dev/null)" = healthy ] \
    && { echo "    healthy"; break; }
  running "$AGENT" \
    || { echo "ERROR: Agent exited" >&2; docker logs "$AGENT" 2>&1 | tail -30; exit 1; }
  sleep 5
done

echo "==> Confirming the config actually reached the container"
MOUNTED=$(docker exec "$AGENT" ls /etc/datadog-agent/conf.d/ibm_was.d/ 2>/dev/null | grep -c 'conf.yaml' || true)
[ "${MOUNTED:-0}" -gt 0 ] \
  || { echo "ERROR: conf.d/ibm_was.d is empty inside the Agent - the bind mount did not" >&2
       echo "       resolve. On macOS/Colima the source must be under \$HOME." >&2; exit 1; }

echo "==> Waiting for the check to be scheduled"
# A healthy Agent with a valid API key proves nothing about the check being loaded. Assert
# it explicitly, or a silent mount failure looks like success.
LOADED=no
for _ in $(seq 1 12); do
  HITS=$(docker exec "$AGENT" agent status 2>/dev/null | grep -c -E '^ *ibm_was \(' || true)
  if [ "${HITS:-0}" -gt 0 ]; then LOADED=yes; break; fi
  sleep 5
done
[ "$LOADED" = yes ] \
  || { echo "ERROR: the ibm_was check never appeared in 'agent status'" >&2
       docker exec "$AGENT" agent status 2>/dev/null | tail -30 >&2; exit 1; }

echo "==> API key and check status"
# BSD grep (macOS) has no \s in its pattern language, so use explicit spaces.
docker exec "$AGENT" agent status 2>/dev/null | grep -E 'API key ending with .*: API Key' || true
docker exec "$AGENT" agent status 2>/dev/null | grep -A6 -E '^ *ibm_was \(' || true

echo
echo "Metrics:  Metrics Explorer -> ibm_was.*   (host:$DD_HOSTNAME)"
echo "Logs:     source:ibm_was service:websphere"
echo "Recheck:  docker exec $AGENT agent check ibm_was"
