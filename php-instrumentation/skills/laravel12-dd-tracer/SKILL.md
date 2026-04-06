---
name: laravel12-dd-tracer
description: >-
  Use this skill whenever the user wants to instrument a Laravel 12 application with
  Datadog APM. Triggers on mentions of Laravel APM, PHP tracing with Datadog, dd-trace-php,
  PHP-FPM monitoring, Laravel instrumentation, or PHP 8.3 application monitoring. Also
  applies when the user asks about Single Step APM instrumentation for PHP.
version: 0.1.0
version_matrix:
  php_version: [8.3]
  laravel_version: [12]
---

# Laravel 12 + PHP 8.3 — Datadog APM Instrumentation

Instrument a Laravel 12 application (PHP 8.3, Nginx/PHP-FPM) with Datadog APM tracing.

## Prerequisites

- Laravel 12 + PHP 8.3 + Nginx running on EC2 (see `setup-laravel12-nginx` skill)
- SSH access to the EC2 instance
- Datadog API key and site location

## Instructions

Two options are available. Both install the Datadog Agent and the `dd-trace-php` extension.

### Option A — Single Step Instrumentation (recommended)

Installs the Agent and PHP tracer in one step:

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'DD_API_KEY=<DD_API_KEY> \
    DD_SITE="<DD_SITE>" \
    DD_APM_INSTRUMENTATION_ENABLED=host \
    DD_APM_INSTRUMENTATION_LIBRARIES="php:1" \
    bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"'
```

### Option B — Manual PHP Tracer Install

Install agent and tracer separately:

```bash
# Install Datadog Agent
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'DD_API_KEY=<DD_API_KEY> DD_SITE="<DD_SITE>" \
    bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"'

# Install PHP tracer
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'curl -LO https://github.com/DataDog/dd-trace-php/releases/latest/download/datadog-setup.php && \
    sudo php datadog-setup.php --php-bin=all'
```

### Set unified service tags (both options)

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> "sudo tee -a /etc/php/8.3/fpm/pool.d/www.conf > /dev/null <<'EOF'

env[DD_SERVICE] = travellist
env[DD_ENV] = sandbox
env[DD_VERSION] = 1.0.0
EOF"
```

### Restart PHP-FPM

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo systemctl restart php8.3-fpm'
```

## Validation

```bash
# Verify ddtrace extension is loaded
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'php -m | grep ddtrace'
# -> ddtrace

# Check ddtrace in phpinfo output
curl -s http://<EC2_PUBLIC_IP>/phpinfo | grep -o 'ddtrace'
# -> ddtrace

# Generate traffic for APM traces
for i in {1..10}; do curl -s -o /dev/null -w "%{http_code}\n" http://<EC2_PUBLIC_IP>/; done

# Check agent is receiving traces
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo datadog-agent status'
```

In the Datadog UI: **APM > Services** — look for `travellist` with `env:sandbox`.

## Troubleshooting

### `ddtrace` not in `php -m` output
**Cause:** PHP tracer not installed or PHP-FPM not restarted.
**Fix:** Re-run tracer installation and restart: `sudo systemctl restart php8.3-fpm`

### Service appears as `env:none` in Datadog
**Cause:** Unified service tags not set in PHP-FPM pool config.
**Fix:** Add `env[DD_SERVICE]`, `env[DD_ENV]`, `env[DD_VERSION]` to `/etc/php/8.3/fpm/pool.d/www.conf` and restart PHP-FPM.

### Agent `Writer: Traces: 0 payloads`
**Cause:** The writer stats cover a 60-second window and may show 0 between flushes. This is normal.
**Fix:** Check `Receiver: Traces received: N` and `Writer: Stats: N payloads` instead.
