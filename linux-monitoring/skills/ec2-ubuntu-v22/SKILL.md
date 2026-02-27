---
name: EC2 Linux Monitoring (Ubuntu 22.04)
description: "This skill should be used when the user wants to set up Datadog infrastructure monitoring on an Amazon EC2 instance running Ubuntu."
version: 0.1.0
---

# EC2 Linux Monitoring — Ubuntu 22.04

## Prerequisites

- SSH access to an Ubuntu EC2 instance
- Datadog API key
- Datadog data center site location
- (Optional) Terraform for infrastructure provisioning — see `scripts/`

## Steps

### 1. Install Datadog Agent

```bash
DD_API_KEY=<YOUR_API_KEY> \
DD_SITE="datadoghq.com" \
bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"
```

### 2. Enable Log Collection

Edit `/etc/datadog-agent/datadog.yaml` and set `logs_enabled: true`.

See `references/datadog.yaml.example` for full config reference.
See `references/DATADOGYAML.md` for config tree overview.

### 3. Configure Syslog Collection

Create `/etc/datadog-agent/conf.d/syslog.d/conf.yaml` with the following content:

```yaml
logs:
  - type: file
    path: /var/log/syslog
    service: syslog
    source: ubuntu
```

### 4. Restart Datadog Agent

```bash
sudo systemctl restart datadog-agent
```

## Verification

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

Confirm syslog events appear in the Datadog UI.

## References

- Original README: `references/README.md`
- Datadog agent config reference: `references/datadog.yaml.example`
- Datadog config tree: `references/DATADOGYAML.md`
- MySQL integration config: `references/mysql.conf.yaml.example`
- MySQL config tree: `references/MYSQLCONFYAML.md`
- Terraform infrastructure: `scripts/main.tf`, `scripts/variables.tf`, `scripts/outputs.tf`
