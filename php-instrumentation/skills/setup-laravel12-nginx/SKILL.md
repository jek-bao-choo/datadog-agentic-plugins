---
name: setup-laravel12-nginx
description: >-
  Use this skill whenever the user needs to set up a Laravel 12 application with PHP 8.3
  and Nginx on Ubuntu 24.04. Triggers on mentions of Laravel 12 setup, PHP 8.3 install,
  Nginx + PHP-FPM configuration, or deploying a Laravel app on EC2. Also applies for
  local Docker-based Laravel development with PHP 8.3.
version: 0.1.0
version_matrix:
  php_version: [8.3]
  laravel_version: [12]
---

# Laravel 12 + PHP 8.3 + Nginx Setup

Set up a Laravel 12 application with PHP 8.3 and Nginx on Ubuntu 24.04. Provides the foundation for Datadog APM instrumentation (see `laravel12-dd-tracer` skill).

## Prerequisites

- Docker (for Phase 1 local setup)
- An EC2 instance running Ubuntu 24.04 with SSH access (for Phase 2)

## Instructions

The complete setup is documented in `references/README.md` across two phases:

### Phase 1 — Local Docker Setup

```bash
# Build and run locally (from the references/ directory)
docker build -t travellist-laravel12:latest .
docker run -d --name travellist -p 8080:80 travellist-laravel12:latest
```

### Phase 2 — EC2 Native Install

Install PHP 8.3, Nginx, PHP-FPM, Composer, and Laravel 12 directly on the EC2 instance. See `references/README.md` for the full SSH command sequence covering:

1. Install PHP 8.3, Nginx, PHP-FPM, and utilities
2. Install Composer
3. Create the Laravel 12 project
4. Create SQLite database
5. Append phpinfo route
6. Set permissions
7. Configure Nginx (use `references/travellist-nginx.conf`)
8. Verify the setup

## Reference Files

- `references/README.md` — Complete phase-by-phase guide
- `references/Dockerfile` — Docker image for local development
- `references/travellist-nginx.conf` — Nginx server block configuration
- `references/routes-web.php` — Laravel route snippet (phpinfo endpoint)

## Validation

```bash
# Check PHP version
php -v  # -> PHP 8.3.x

# Check Laravel version
php /var/www/html/travellist/artisan --version  # -> Laravel Framework 12.x.x

# Check homepage returns 200
curl -s -o /dev/null -w "%{http_code}" http://<HOST>  # -> 200

# Check phpinfo route
curl -s -o /dev/null -w "%{http_code}" http://<HOST>/phpinfo  # -> 200
```

## Troubleshooting

### Homepage returns 500
**Cause:** Laravel storage directory permissions are incorrect.
**Fix:** `sudo chown -R www-data:www-data /var/www/html/travellist && sudo chmod -R 775 /var/www/html/travellist/storage`

### Nginx returns 502 Bad Gateway
**Cause:** PHP-FPM is not running or misconfigured.
**Fix:** `sudo systemctl restart php8.3-fpm` and check the socket path in the Nginx config matches PHP-FPM's listen directive.
