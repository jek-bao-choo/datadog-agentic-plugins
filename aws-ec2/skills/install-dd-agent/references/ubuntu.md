# Ubuntu 22.04 — Datadog Agent Installation

> **Applies to:** AMI ubuntu-22.04

## Step 1: Install Datadog Agent

```bash
DD_API_KEY=<YOUR_API_KEY> \
DD_SITE="datadoghq.com" \
bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"
```

Replace `<YOUR_API_KEY>` with your Datadog API key and `datadoghq.com` with your Datadog site if different.

## Step 2: Enable Log Collection

Edit `/etc/datadog-agent/datadog.yaml` and set `logs_enabled: true`.

See `datadog.yaml.example` in this references directory for the full config reference.
See `DATADOGYAML.md` for the config tree overview.

## Step 3: Configure Syslog Collection

Create `/etc/datadog-agent/conf.d/syslog.d/conf.yaml` with the following content:

```yaml
logs:
  - type: file
    path: /var/log/syslog
    service: syslog
    source: ubuntu
```

## Step 4: Restart Datadog Agent

```bash
sudo systemctl restart datadog-agent
```

## Step 5: Verify

```bash
# Check agent status
sudo datadog-agent status

# Check Logs Agent section specifically
sudo datadog-agent status | grep -A 25 "Logs Agent"

# Check for errors in agent journal
sudo journalctl -u datadog-agent -p err -n 50

# Grep the log file for errors
sudo grep -i "error" /var/log/datadog/agent.log
```

Confirm syslog events appear in the Datadog UI under **Logs**.
