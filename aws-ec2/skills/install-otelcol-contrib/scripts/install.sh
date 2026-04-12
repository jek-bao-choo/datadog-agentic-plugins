#!/bin/bash
# Install OpenTelemetry Collector Contrib on CentOS Stream 9
# Usage: ./install.sh <DD_API_KEY>
set -euo pipefail

DD_API_KEY="${1:?Usage: ./install.sh <DD_API_KEY>}"
OTELCOL_VERSION="${2:-0.149.0}"

echo "=== Installing otelcol-contrib v${OTELCOL_VERSION} ==="

# Download and install RPM
RPM_URL="https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v${OTELCOL_VERSION}/otelcol-contrib_${OTELCOL_VERSION}_linux_amd64.rpm"
echo "Downloading: ${RPM_URL}"
curl -L -o /tmp/otelcol-contrib.rpm "${RPM_URL}"
sudo rpm -Uvh /tmp/otelcol-contrib.rpm
rm -f /tmp/otelcol-contrib.rpm

echo "=== Deploying config ==="

# Deploy config (expects config.yaml in same directory or parent references/)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_SRC="${SCRIPT_DIR}/../references/config.yaml"
if [ -f "${CONFIG_SRC}" ]; then
  sudo cp "${CONFIG_SRC}" /etc/otelcol-contrib/config.yaml
  echo "Config deployed from ${CONFIG_SRC}"
elif [ -f "/tmp/otelcol-contrib-config.yaml" ]; then
  sudo cp /tmp/otelcol-contrib-config.yaml /etc/otelcol-contrib/config.yaml
  echo "Config deployed from /tmp/otelcol-contrib-config.yaml"
else
  echo "ERROR: No config.yaml found. Place it at ${CONFIG_SRC} or /tmp/otelcol-contrib-config.yaml"
  exit 1
fi

echo "=== Configuring environment ==="

# Set DD_API_KEY and OTELCOL_OPTIONS in the environment file.
# The RPM systemd service reads OTELCOL_OPTIONS and passes it to the binary.
# Without --config, the collector fails with "at least one config flag must be provided".
sudo tee /etc/otelcol-contrib/otelcol-contrib.conf > /dev/null <<EOF
DD_API_KEY=${DD_API_KEY}
OTELCOL_OPTIONS="--config=/etc/otelcol-contrib/config.yaml"
EOF
sudo chmod 600 /etc/otelcol-contrib/otelcol-contrib.conf

echo "=== Configuring log access and storage ==="

# Grant otelcol-contrib user read access to system logs for filelog receiver
sudo setfacl -m u:otelcol-contrib:r /var/log/messages /var/log/secure 2>/dev/null || sudo chmod o+r /var/log/messages /var/log/secure

# Create storage directory for filelog checkpoint (tracks read position)
sudo mkdir -p /var/lib/otelcol-contrib/storage
sudo chown otelcol-contrib:otelcol-contrib /var/lib/otelcol-contrib/storage

echo "=== Starting otelcol-contrib ==="

sudo systemctl daemon-reload
sudo systemctl enable otelcol-contrib
sudo systemctl restart otelcol-contrib

# Wait a few seconds for startup
sleep 3

# Check status
if sudo systemctl is-active --quiet otelcol-contrib; then
  echo "=== otelcol-contrib is running ==="
  sudo systemctl status otelcol-contrib --no-pager -l
else
  echo "=== ERROR: otelcol-contrib failed to start ==="
  sudo journalctl -u otelcol-contrib --no-pager -n 30
  exit 1
fi

echo ""
echo "=== Installation complete ==="
echo "Health check: curl -s http://localhost:13133/"
echo "Logs:         sudo journalctl -u otelcol-contrib -f"
