#!/usr/bin/env bash
# colima-preflight.sh - read-only diagnostic for a Colima-based Docker setup on macOS.
#
# Reports PASS / WARN / FAIL for each check. Makes no changes to the system.
#
# Exit codes:
#   0  healthy      - Colima is running and Docker works
#   1  needs repair - Colima is installed but stopped or misconfigured
#   2  not installed- Colima (or the Docker CLI) is missing

set -u

SOCK="$HOME/.colima/default/docker.sock"
DOCKER_CONFIG_FILE="$HOME/.docker/config.json"
NEEDS_REPAIR=0

pass() { printf 'PASS  %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; NEEDS_REPAIR=1; }

echo "=== Colima preflight ==="

# --- 1. Binaries on PATH -----------------------------------------------------
if ! command -v colima >/dev/null 2>&1; then
  fail "colima is not on PATH - Colima is not installed"
  echo
  echo "Result: NOT INSTALLED. Follow references/migrating-from-docker-desktop.md"
  exit 2
fi
pass "colima found at $(command -v colima)"

if ! command -v docker >/dev/null 2>&1; then
  fail "docker CLI is not on PATH"
  echo
  echo "Result: NOT INSTALLED. Run: brew install docker docker-compose docker-buildx && brew link docker"
  exit 2
fi
pass "docker found at $(command -v docker)"

if docker compose version >/dev/null 2>&1; then
  pass "docker compose plugin available ($(docker compose version --short 2>/dev/null))"
else
  fail "docker compose plugin not found - check cliPluginsExtraDirs in $DOCKER_CONFIG_FILE"
fi

# --- 2. Colima VM state ------------------------------------------------------
# colima status writes to stderr; capture both streams.
COLIMA_STATUS="$(colima status 2>&1)"
if printf '%s' "$COLIMA_STATUS" | grep -qi 'colima is running'; then
  pass "Colima VM is running"
  printf '%s' "$COLIMA_STATUS" | grep -oE 'arch: [^"]*|runtime: [^"]*|mountType: [^"]*' | sed 's/^/      /'
else
  fail "Colima VM is not running - run: colima start"
fi

# --- 3. Docker daemon reachable ---------------------------------------------
if docker info >/dev/null 2>&1; then
  pass "docker daemon is reachable"
else
  fail "docker daemon is not reachable - run: colima start"
fi

# --- 4. Socket / DOCKER_HOST -------------------------------------------------
if [ -S "$SOCK" ]; then
  pass "Colima docker socket exists at \$HOME/.colima/default/docker.sock"
else
  fail "Colima docker socket missing at \$HOME/.colima/default/docker.sock"
fi

if [ -n "${DOCKER_HOST:-}" ]; then
  if [ "${DOCKER_HOST}" = "unix://$SOCK" ]; then
    pass "DOCKER_HOST points at the Colima socket"
  else
    warn "DOCKER_HOST is set to '${DOCKER_HOST}' (expected unix://\$HOME/.colima/default/docker.sock)"
  fi
else
  warn "DOCKER_HOST is unset - fine for the docker CLI, but Testcontainers and other Docker SDK tools need it"
fi

if [ -n "${TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE:-}" ]; then
  pass "TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE is set"
else
  warn "TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE is unset - set it to /var/run/docker.sock for Testcontainers"
fi

# --- 5. Docker context -------------------------------------------------------
CURRENT_CTX="$(docker context ls --format '{{.Name}}{{if .Current}} *{{end}}' 2>/dev/null | grep '\*' | awk '{print $1}')"
case "${CURRENT_CTX:-}" in
  colima)  pass "docker context is 'colima'" ;;
  default) if [ -n "${DOCKER_HOST:-}" ]; then
             pass "docker context is 'default', overridden by DOCKER_HOST (this is expected and harmless)"
           else
             warn "docker context is 'default' and DOCKER_HOST is unset - run: docker context use colima"
           fi ;;
  "")      warn "could not determine the current docker context" ;;
  *)       warn "docker context is '${CURRENT_CTX}' - run: docker context use colima" ;;
esac

if docker context ls --format '{{.Name}}' 2>/dev/null | grep -qx 'desktop-linux'; then
  warn "leftover 'desktop-linux' context from Docker Desktop - run: docker context rm desktop-linux"
fi

# --- 6. Storage driver -------------------------------------------------------
STORAGE="$(docker info --format '{{.Driver}}' 2>/dev/null)"
case "${STORAGE:-}" in
  overlayfs) pass "storage driver is overlayfs (containerd snapshotter)" ;;
  overlay2)  warn "storage driver is overlay2 - enable the containerd snapshotter for multi-platform builds" ;;
  "")        warn "could not read the storage driver (daemon unreachable?)" ;;
  *)         warn "storage driver is '${STORAGE}'" ;;
esac

# --- 7. ~/.docker/config.json ------------------------------------------------
if [ -f "$DOCKER_CONFIG_FILE" ]; then
  if grep -q '"credsStore"[[:space:]]*:[[:space:]]*"desktop"' "$DOCKER_CONFIG_FILE"; then
    fail "credsStore is still set to 'desktop' - docker-credential-desktop will not be found"
  else
    pass "no leftover Docker Desktop credsStore entry"
  fi
  if grep -q 'cliPluginsExtraDirs' "$DOCKER_CONFIG_FILE"; then
    # Docker does NOT expand shell variables in this field - the path must be literal.
    if grep -A3 'cliPluginsExtraDirs' "$DOCKER_CONFIG_FILE" | grep -q '\$'; then
      fail "cliPluginsExtraDirs contains an unexpanded shell variable - Docker treats it literally. Use the resolved path, e.g. /opt/homebrew/lib/docker/cli-plugins"
    else
      pass "cliPluginsExtraDirs is configured with a literal path"
    fi
  else
    warn "cliPluginsExtraDirs is not configured - Homebrew CLI plugins (compose, buildx) may not be found"
  fi
else
  warn "$DOCKER_CONFIG_FILE does not exist yet"
fi

# --- Result ------------------------------------------------------------------
echo
if [ "$NEEDS_REPAIR" -eq 0 ]; then
  echo "Result: HEALTHY. Colima is running and Docker is usable."
  exit 0
fi
echo "Result: NEEDS REPAIR. See the FAIL lines above."
exit 1
