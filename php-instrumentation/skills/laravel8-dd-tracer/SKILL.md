---
name: laravel8-dd-tracer
description: >-
  Use this skill whenever the user wants to instrument a Laravel 8 application with
  Datadog APM. Triggers on mentions of Laravel 8 tracing, PHP 7.4 APM, dd-trace-php
  for Apache2, or Datadog instrumentation for legacy PHP applications.
version: 0.1.0
version_matrix:
  php_version: [7.4]
  laravel_version: [8]
---

# Laravel 8 + PHP 7.4 — Datadog APM Instrumentation

Instrument a Laravel 8 application (PHP 7.4, Apache2) with Datadog APM tracing.

## Prerequisites

- Laravel 8 + PHP 7.4 + Apache2 running on EC2 (see `setup-laravel8-apache2` skill)
- SSH access to the EC2 instance
- Datadog API key and site location

## Instructions

### 1. Install the Datadog Agent

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'DD_API_KEY=<DD_API_KEY> \
    DD_SITE="<DD_SITE>" \
    bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"'
```

### 2. Install the PHP tracer

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'curl -LO https://github.com/DataDog/dd-trace-php/releases/latest/download/datadog-setup.php && \
    sudo php datadog-setup.php --php-bin=all'
```

### 3. Configure unified service tagging

For Apache2 with mod_php, add environment variables to the Apache VirtualHost or to a PHP INI file:

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'echo -e "\ndatadog.service = travellist\ndatadog.env = sandbox\ndatadog.version = 1.0.0" | sudo tee -a /etc/php/7.4/apache2/conf.d/98-ddtrace.ini'
```

### 4. Restart Apache

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo systemctl restart apache2'
```

## Validation

```bash
# Verify ddtrace extension is loaded
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'php -m | grep ddtrace'
# -> ddtrace

# Check ddtrace in phpinfo output
curl -s http://<EC2_PUBLIC_IP>/phpinfo | grep -o 'ddtrace'
# -> ddtrace

# Generate traffic
for i in {1..10}; do curl -s -o /dev/null -w "%{http_code}\n" http://<EC2_PUBLIC_IP>/; done

# Check agent status
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo datadog-agent status'
```

In the Datadog UI: **APM > Services** — look for `travellist` with `env:sandbox`.

## Troubleshooting

### `ddtrace` not in `php -m` output
**Cause:** PHP tracer not installed or Apache not restarted.
**Fix:** Re-run tracer installation and restart: `sudo systemctl restart apache2`

### Service appears as `env:none`
**Cause:** Unified service tags not configured.
**Fix:** Add `datadog.service`, `datadog.env`, `datadog.version` to the PHP INI file and restart Apache.
