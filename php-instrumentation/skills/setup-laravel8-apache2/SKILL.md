---
name: setup-laravel8-apache2
description: >-
  Use this skill whenever the user needs to set up a Laravel 8 application with PHP 7.4
  and Apache2 on Ubuntu 24.04. Triggers on mentions of Laravel 8 setup, PHP 7.4 install,
  Apache2 with Laravel, or legacy PHP application deployment on EC2. Also applies for
  local Docker-based Laravel 8 development.
version: 0.1.0
version_matrix:
  php_version: [7.4]
  laravel_version: [8]
---

# Laravel 8 + PHP 7.4 + Apache2 Setup

Set up a Laravel 8 application with PHP 7.4 and Apache2 on Ubuntu 24.04. Provides the foundation for Datadog APM instrumentation (see `laravel8-dd-tracer` skill).

## Prerequisites

- Docker (for Phase 1 local setup)
- An EC2 instance running Ubuntu 24.04 with SSH access (for Phase 2)

## Instructions

The complete setup is documented in `references/README.md` across two phases:

### Phase 1 — Local Docker Setup

```bash
# Build and run locally (from the references/ directory)
docker build -t travellist-laravel8:latest .
docker run -d --name travellist -p 8080:80 travellist-laravel8:latest
```

### Phase 2 — EC2 Native Install

Install PHP 7.4, Apache2, Composer 2.2.24, and Laravel 8 on the EC2 instance. See `references/README.md` for the full SSH command sequence covering:

1. Install PHP 7.4, Apache2, and utilities
2. Install Composer 2.2.24 (required for PHP 7.4 compatibility)
3. Create the Laravel 8 project
4. Append phpinfo route
5. Set permissions
6. Configure Apache VirtualHost (use `references/travellist-project.conf`)
7. Verify the setup

## Reference Files

- `references/README.md` — Complete phase-by-phase guide
- `references/Dockerfile` — Docker image for local development
- `references/travellist-project.conf` — Apache VirtualHost configuration
- `references/routes-web.php` — Laravel route snippet (phpinfo endpoint)

## Validation

```bash
# Check PHP version
php -v  # -> PHP 7.4.x

# Check Laravel version
php /var/www/html/travellist/artisan --version  # -> Laravel Framework 8.x.x

# Check homepage returns 200
curl -s -o /dev/null -w "%{http_code}" http://<EC2_PUBLIC_IP>  # -> 200

# Check phpinfo route
curl -s -o /dev/null -w "%{http_code}" http://<EC2_PUBLIC_IP>/phpinfo  # -> 200
```

## Troubleshooting

### Homepage returns 500
**Cause:** Laravel storage directory permissions are incorrect.
**Fix:** `sudo chown -R www-data:www-data /var/www/html/travellist && sudo chmod -R 775 /var/www/html/travellist/storage`

### Apache returns default page instead of Laravel
**Cause:** VirtualHost not enabled or default site still active.
**Fix:** `sudo a2dissite 000-default.conf && sudo a2ensite travellist-project.conf && sudo systemctl restart apache2`

### Composer install fails
**Cause:** Composer version too new for PHP 7.4.
**Fix:** Use Composer 2.2.24: `curl -sS https://getcomposer.org/installer | sudo php -- --version=2.2.24 --install-dir=/usr/local/bin --filename=composer`
