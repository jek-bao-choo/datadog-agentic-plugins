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

Copy the config file to the EC2 instance and enable it:

```bash
# Copy the Nginx config
scp -i <KEY_PATH> travellist-nginx.conf ubuntu@<EC2_HOST>:/tmp/travellist-nginx.conf

# Install config and enable the site
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

## Teardown

### Phase 1

```bash
docker rm -f travellist
```

### Phase 2

```bash
# Remove the Laravel project
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo rm -rf /var/www/html/travellist'

# Restore default Nginx config
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo rm -f /etc/nginx/sites-enabled/travellist-nginx.conf && \
    sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default && \
    sudo systemctl restart nginx && \
    sudo rm -f /etc/nginx/sites-available/travellist-nginx.conf'
```
