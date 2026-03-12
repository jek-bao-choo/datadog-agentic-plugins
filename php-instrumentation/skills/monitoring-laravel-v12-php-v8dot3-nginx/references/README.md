# Laravel 12 + PHP 8.3 + Nginx on Ubuntu 24.04

Reference environment for a Laravel 12 application running on PHP 8.3 with Nginx + PHP-FPM, built on Ubuntu 24.04.

## Tech Stack

| Component | Version |
|-----------|---------|
| Ubuntu    | 24.04   |
| PHP       | 8.3     |
| Laravel   | 12.x    |
| Nginx     | latest  |
| PHP-FPM   | 8.3     |
| Composer  | latest  |

## Project Structure

```
references/
├── .claude/
│   └── settings.local.json       # Claude Code permission allowlist for Phase 1
├── Dockerfile                    # Ubuntu 24.04 + PHP 8.3 + Nginx + Laravel 12
├── travellist-nginx.conf         # Nginx server block configuration
├── routes-web.php                # phpinfo route snippet appended to Laravel routes
└── README.md                     # This file
```

## Phase 1 — Local Docker Setup

Build and run the Laravel 12 application locally in Docker.

### 1. Build the Docker image

```bash
# From the references/ directory
docker build -t travellist-laravel12:latest .
```

### 2. Run the container

```bash
docker run -d --name travellist -p 8080:80 travellist-laravel12:latest
```

### 3. Verify the setup

Run each command and confirm the expected output:

```bash
# Check PHP version → PHP 8.3.x
docker exec travellist php -v

# Check Laravel version → Laravel Framework 12.x.x
docker exec travellist php /var/www/html/travellist/artisan --version

# Check homepage returns 200
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080
# → 200

# Check phpinfo route returns 200
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/phpinfo
# → 200

# Confirm PHP version from phpinfo output
curl -s http://localhost:8080/phpinfo | grep -o 'PHP Version [0-9.]*' | head -1
# → PHP Version 8.3.x
```

### 4. Cleanup

```bash
docker rm -f travellist
```

---

## Phase 2 — EC2 Native Install

Install PHP 8.3, Nginx, PHP-FPM, and Laravel 12 directly on an EC2 instance running Ubuntu 24.04.

All commands are executed via SSH. Replace `<KEY_PATH>` and `<EC2_HOST>` with your values.

### Prerequisites

- EC2 instance running Ubuntu 24.04
- SSH access: `ssh -i <KEY_PATH> ubuntu@<EC2_HOST>`
- Security group allows inbound TCP port 80

### 1. Install PHP 8.3, Nginx, PHP-FPM, and utilities

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo apt-get update && \
    sudo apt-get install -y software-properties-common && \
    sudo add-apt-repository ppa:ondrej/php -y && \
    sudo apt-get update && \
    sudo apt-get install -y \
        php8.3-fpm \
        php8.3-cli \
        php8.3-common \
        php8.3-curl \
        php8.3-mbstring \
        php8.3-xml \
        php8.3-zip \
        php8.3-mysql \
        php8.3-sqlite3 \
        nginx \
        curl \
        unzip \
        git'
```

### 2. Install Composer

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer'
```

### 3. Create the Laravel 12 project

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo composer create-project laravel/laravel:^12.0 /var/www/html/travellist'
```

### 4. Create the SQLite database

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo touch /var/www/html/travellist/database/database.sqlite'
```

### 5. Append the phpinfo route

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> "sudo tee -a /var/www/html/travellist/routes/web.php > /dev/null <<'ROUTE'

Route::get('phpinfo', function () {
    phpinfo();
})->name('phpinfo');
ROUTE"
```

### 6. Set permissions

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo chown -R www-data:www-data /var/www/html/travellist && \
    sudo chmod -R 775 /var/www/html/travellist/storage && \
    sudo chmod -R 777 /var/www/html/travellist/storage/logs'
```

### 7. Configure Nginx

Copy the config file to the EC2 instance and enable it.

#### 7a. Copy the Nginx config to the EC2 instance

```bash
scp -i <KEY_PATH> travellist-nginx.conf ubuntu@<EC2_HOST>:/tmp/travellist-nginx.conf
```

#### 7b. Install the config and enable the site

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo cp /tmp/travellist-nginx.conf /etc/nginx/sites-available/travellist-nginx.conf && \
    sudo ln -sf /etc/nginx/sites-available/travellist-nginx.conf /etc/nginx/sites-enabled/travellist-nginx.conf && \
    sudo rm -f /etc/nginx/sites-enabled/default && \
    sudo systemctl restart php8.3-fpm && \
    sudo systemctl restart nginx'
```

### 8. Verify the setup

Replace `<EC2_PUBLIC_IP>` with the instance's public IP address.

```bash
# Check PHP version → PHP 8.3.x
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'php -v'

# Check Laravel version → Laravel Framework 12.x.x
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'php /var/www/html/travellist/artisan --version'

# Check homepage returns 200
curl -s -o /dev/null -w "%{http_code}" http://<EC2_PUBLIC_IP>
# → 200

# Check phpinfo route returns 200
curl -s -o /dev/null -w "%{http_code}" http://<EC2_PUBLIC_IP>/phpinfo
# → 200

# Confirm PHP version from phpinfo output
curl -s http://<EC2_PUBLIC_IP>/phpinfo | grep -o 'PHP Version [0-9.]*' | head -1
# → PHP Version 8.3.x
```

### 9. Browser verification

Open in a browser:

- Homepage: `http://<EC2_PUBLIC_IP>/`
- PHP info: `http://<EC2_PUBLIC_IP>/phpinfo`

---

## Phase 3 — Datadog APM Instrumentation

Instrument the Laravel application with Datadog APM tracing. Choose one of the two options below. Both assume SSH access to the EC2 instance from Phase 2.

### Option A — Single Step Instrumentation

The Datadog Agent install script can install both the Agent **and** the PHP tracer in one step when APM Instrumentation is enabled.

Docs: https://docs.datadoghq.com/tracing/trace_collection/single-step-apm/linux/

#### 1. Install the Datadog Agent with APM Instrumentation

> **Note:** You can also obtain a pre-filled version of this command from the Datadog UI at **Integrations → Agent → Linux** with **APM Instrumentation** enabled.

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'DD_API_KEY=<DD_API_KEY> \
    DD_SITE="<DD_SITE>" \
    DD_APM_INSTRUMENTATION_ENABLED=host \
    DD_APM_INSTRUMENTATION_LIBRARIES="php:1" \
    bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"'
```

> Replace `<DD_API_KEY>` and `<DD_SITE>` (e.g. `datadoghq.com`) with your values.

#### 2. Restart PHP-FPM

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo systemctl restart php8.3-fpm'
```

#### 3. Set unified service tags

Single Step instrumentation does not inject `DD_SERVICE`, `DD_ENV`, or `DD_VERSION`. Without this step, the service appears in Datadog as `service:laravel,env:none`. Set them via the PHP-FPM pool config:

> **Note:** This command appends to the file. If re-running, check entries don't already exist first:
> `ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'grep DD_SERVICE /etc/php/8.3/fpm/pool.d/www.conf'`

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> "sudo tee -a /etc/php/8.3/fpm/pool.d/www.conf > /dev/null <<'EOF'

env[DD_SERVICE] = travellist
env[DD_ENV] = sandbox
env[DD_VERSION] = 1.0.0
EOF"
```

#### 4. Restart PHP-FPM and verify

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo systemctl restart php8.3-fpm'
```

```bash
# Confirm ddtrace extension is loaded
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'php -m | grep ddtrace'
# → ddtrace

# Check ddtrace appears in phpinfo output
curl -s http://<EC2_PUBLIC_IP>/phpinfo | grep -o 'ddtrace'
# → ddtrace

# Generate traffic for APM traces (send multiple requests to ensure flush)
for i in {1..10}; do curl -s -o /dev/null -w "%{http_code}\n" http://<EC2_PUBLIC_IP>/; done

# Confirm agent is receiving traces and is connected to Datadog
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo datadog-agent status'
```

Look for the following in the `datadog-agent status` output:

```
APM Agent
=========
  Status: Running
  ...
  Receiver (previous minute)
    From php 8.3.x (fpm-fcgi), client 1.x.x
      Traces received: N (... bytes)   ← PHP tracer is sending spans
      Spans received: N

  Writer (previous minute)
    Traces: N payloads ...             ← may be 0 due to timing (see note below)
    Stats: N payloads, N stats buckets ← this confirms data is reaching Datadog
```

> **Note on `Writer: Traces: 0 payloads`** — The writer stats cover only the previous 60-second window and may show 0 if the flush already completed in an earlier window. This does not indicate a problem. The reliable signals are:
> - `Receiver: Traces received: N` — the PHP tracer is submitting spans locally
> - `Writer: Stats: N payloads` — aggregated APM stats are being flushed to Datadog
> - `diagnostics: APM traces … success` — the agent can reach `trace.agent.datadoghq.com`

#### 5. Datadog UI verification

Open **APM → Services** in the Datadog UI:
https://app.datadoghq.com/apm/services

Look for service **`travellist`** with env **`sandbox`**.

> Allow 1–2 minutes after generating traffic for the service to appear.
> Individual traces are visible under **APM → Traces** — filter by `service:travellist`.

---

### Option B — Manual PHP Tracer Install

Install the Datadog Agent and `dd-trace-php` separately for more control over versions, configuration, and features.

Docs:
- https://docs.datadoghq.com/tracing/trace_collection/dd_libraries/php/
- https://docs.datadoghq.com/tracing/trace_collection/library_config/php/

#### 1. Install the Datadog Agent

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'DD_API_KEY=<DD_API_KEY> \
    DD_SITE="<DD_SITE>" \
    bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"'
```

#### 2. Install the PHP tracer

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'curl -LO https://github.com/DataDog/dd-trace-php/releases/latest/download/datadog-setup.php && \
    sudo php datadog-setup.php --php-bin=all'
```

#### 3. Configure unified service tagging

Set service tags via the PHP-FPM pool config:

> **Note:** This command appends to the file. If re-running, first check that the entries don't already exist:
> `ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'grep DD_SERVICE /etc/php/8.3/fpm/pool.d/www.conf'`

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> "sudo tee -a /etc/php/8.3/fpm/pool.d/www.conf > /dev/null <<'EOF'

env[DD_SERVICE] = travellist
env[DD_ENV] = sandbox
env[DD_VERSION] = 1.0.0
EOF"
```

Alternatively, add the values to an INI file:

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'echo -e "\ndatadog.service = travellist\ndatadog.env = sandbox\ndatadog.version = 1.0.0" | sudo tee -a /etc/php/8.3/fpm/conf.d/98-ddtrace.ini'
```

#### 4. Restart PHP-FPM

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo systemctl restart php8.3-fpm'
```

#### 5. Verify

```bash
# Confirm ddtrace extension is loaded
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'php -m | grep ddtrace'
# → ddtrace

# Check ddtrace appears in phpinfo output
curl -s http://<EC2_PUBLIC_IP>/phpinfo | grep -o 'ddtrace'
# → ddtrace

# Generate traffic for APM traces (send multiple requests to ensure flush)
for i in {1..10}; do curl -s -o /dev/null -w "%{http_code}\n" http://<EC2_PUBLIC_IP>/; done

# Confirm agent is receiving traces and is connected to Datadog
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo datadog-agent status'
```

Look for the following in the `datadog-agent status` output:

```
APM Agent
=========
  Status: Running
  ...
  Receiver (previous minute)
    From php 8.3.x (fpm-fcgi), client 1.x.x
      Traces received: N (... bytes)   ← PHP tracer is sending spans
      Spans received: N

  Writer (previous minute)
    Traces: N payloads ...             ← may be 0 due to timing (see note below)
    Stats: N payloads, N stats buckets ← this confirms data is reaching Datadog
```

> **Note on `Writer: Traces: 0 payloads`** — The writer stats cover only the previous 60-second window and may show 0 if the flush already completed in an earlier window. This does not indicate a problem. The reliable signals are:
> - `Receiver: Traces received: N` — the PHP tracer is submitting spans locally
> - `Writer: Stats: N payloads` — aggregated APM stats are being flushed to Datadog
> - `diagnostics: APM traces … success` — the agent can reach `trace.agent.datadoghq.com`

#### 6. Datadog UI verification

Open **APM → Services** in the Datadog UI:
https://app.datadoghq.com/apm/services

Look for service **`travellist`** with env **`sandbox`**.

> Allow 1–2 minutes after generating traffic for the service to appear.
> Individual traces are visible under **APM → Traces** — filter by `service:travellist`.

---

## Teardown

### Phase 1

```bash
docker rm -f travellist
```

### Phase 2 & 3

```bash
# Stop and remove the Datadog Agent (if installed)
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo systemctl stop datadog-agent && \
    sudo apt-get remove -y datadog-agent && \
    sudo rm -rf /etc/datadog-agent /opt/datadog-agent'

# Remove the Laravel project
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo rm -rf /var/www/html/travellist'

# Restore default Nginx config
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo rm -f /etc/nginx/sites-enabled/travellist-nginx.conf && \
    sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default && \
    sudo systemctl restart nginx && \
    sudo rm -f /etc/nginx/sites-available/travellist-nginx.conf'
```