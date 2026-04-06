---
name: install-dd-agent
description: >-
  Use this skill whenever the user wants to install the Datadog Agent on an EC2 instance
  running Ubuntu. Triggers on mentions of Datadog Agent install, DD agent on Ubuntu, host
  monitoring setup, syslog collection with Datadog, or Agent installation on EC2. Also
  applies when the user asks about collecting system logs or infrastructure metrics from
  a Linux VM with Datadog.
version: 0.1.0
version_matrix:
  ami: [ubuntu-22.04]
routing:
  - match: { ami: ubuntu-22.04 }
    variant: references/ubuntu.md
---

# Install Datadog Agent

Install the Datadog Agent on an EC2 instance, enable log collection, configure syslog forwarding, and verify telemetry in Datadog.

## Prerequisites

- SSH access to an Ubuntu EC2 instance (see `setup-ec2` skill)
- Datadog API key
- Datadog data center site location (e.g., `datadoghq.com`)

## Instructions

Based on the prospect's AMI, read the appropriate reference file from `references/` and follow its instructions.

| AMI | Reference File |
|-----|---------------|
| Ubuntu 22.04 | `references/ubuntu.md` |

## Validation

```bash
# Check agent status
sudo datadog-agent status

# Check Logs Agent section
sudo datadog-agent status | grep -A 25 "Logs Agent"

# Check for errors
sudo journalctl -u datadog-agent -p err -n 50
sudo grep -i "error" /var/log/datadog/agent.log
```

Confirm syslog events and infrastructure metrics appear in the Datadog UI.

## Troubleshooting

### Agent status shows "API key is invalid"
**Cause:** The `DD_API_KEY` used during installation is incorrect or expired.
**Fix:** Update the API key in `/etc/datadog-agent/datadog.yaml` and restart: `sudo systemctl restart datadog-agent`

### Syslog events not appearing in Datadog
**Cause:** The syslog conf.yaml file is missing or has incorrect YAML formatting.
**Fix:** Verify `/etc/datadog-agent/conf.d/syslog.d/conf.yaml` exists with correct content and restart the agent.

### Agent cannot reach Datadog endpoints
**Cause:** EC2 security group or network ACL blocks outbound HTTPS (port 443).
**Fix:** Ensure the security group allows outbound traffic to `*.datadoghq.com` on port 443.

## Reference Files

- `references/ubuntu.md` — Ubuntu 22.04 specific install instructions
- `references/datadog.yaml.example` — Full Datadog agent config reference
- `references/DATADOGYAML.md` — Config tree overview
- `references/MYSQLCONFYAML.md` — MySQL integration config tree
- `references/mysql.conf.yaml.example` — MySQL integration config
