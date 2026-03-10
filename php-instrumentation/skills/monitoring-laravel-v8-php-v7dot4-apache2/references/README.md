# Laravel 8 + PHP 7.4 + Apache2 on Ubuntu 24.04

Reference environment for a Laravel 8 application running on PHP 7.4 with Apache2, built on Ubuntu 24.04.

## Tech Stack

| Component | Version |
|-----------|---------|
| Ubuntu    | 24.04   |
| PHP       | 7.4     |
| Laravel   | 8.x     |
| Apache    | 2.x     |
| Composer  | 2.2.24  |

## Project Structure

```
references/
├── .claude/
│   └── settings.local.json       # Claude Code permission allowlist for Phase 1
├── Dockerfile                    # Ubuntu 24.04 + PHP 7.4 + Apache2 + Laravel 8
├── travellist-project.conf       # Apache VirtualHost configuration
├── routes-web.php                # phpinfo route snippet appended to Laravel routes
└── README.md                     # This file
```

## Phase 1 — Local Docker Setup

Build and run the Laravel 8 application locally in Docker.

### 1. Build the Docker image

```bash
# From the references/ directory
docker build -t travellist-laravel8:latest .
```

### 2. Run the container

```bash
docker run -d --name travellist -p 8080:80 travellist-laravel8:latest
```

### 3. Verify the setup

Run each command and confirm the expected output:

```bash
# Check PHP version → PHP 7.4.x
docker exec travellist php -v

# Check Laravel version → Laravel Framework 8.x.x
docker exec travellist php /var/www/html/travellist/artisan --version

# Check homepage returns 200
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080
# → 200

# Check phpinfo route returns 200
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/phpinfo
# → 200

# Confirm PHP version from phpinfo output
curl -s http://localhost:8080/phpinfo | grep -o 'PHP Version [0-9.]*' | head -1
# → PHP Version 7.4.x
```

### 4. Cleanup

```bash
docker rm -f travellist
```

---

## Phase 2 — EC2 Native Install

Install PHP 7.4, Apache2, and Laravel 8 directly on an EC2 instance running Ubuntu 24.04.

All commands are executed via SSH. Replace `<KEY_PATH>` and `<EC2_HOST>` with your values.

### Prerequisites

- EC2 instance running Ubuntu 24.04
- SSH access: `ssh -i <KEY_PATH> ubuntu@<EC2_HOST>`
- Security group allows inbound TCP port 80

### 1. Install PHP 7.4, Apache2, and utilities

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo apt-get update && \
    sudo apt-get install -y software-properties-common && \
    sudo add-apt-repository ppa:ondrej/php -y && \
    sudo apt-get update && \
    sudo apt-get install -y \
        php7.4 \
        php7.4-cli \
        php7.4-common \
        php7.4-curl \
        php7.4-mbstring \
        php7.4-xml \
        php7.4-zip \
        php7.4-mysql \
        libapache2-mod-php7.4 \
        apache2 \
        curl \
        unzip \
        git'
```

### 2. Install Composer 2.2.24

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'curl -sS https://getcomposer.org/installer | sudo php -- --version=2.2.24 --install-dir=/usr/local/bin --filename=composer'
```

### 3. Create the Laravel 8 project

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo composer create-project laravel/laravel:^8.0 /var/www/html/travellist'
```

### 4. Append the phpinfo route

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> "sudo tee -a /var/www/html/travellist/routes/web.php > /dev/null <<'ROUTE'

Route::get('phpinfo', function () {
    phpinfo();
})->name('phpinfo');
ROUTE"
```

### 5. Set permissions

```bash
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo chown -R www-data:www-data /var/www/html/travellist && \
    sudo chmod -R 775 /var/www/html/travellist/storage && \
    sudo chmod -R 777 /var/www/html/travellist/storage/logs'
```

### 6. Configure the Apache VirtualHost

Copy the config file to the EC2 instance and enable it:

```bash
# Copy the VirtualHost config
scp -i <KEY_PATH> travellist-project.conf ubuntu@<EC2_HOST>:/tmp/travellist-project.conf

# Install config and enable the site
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo cp /tmp/travellist-project.conf /etc/apache2/sites-available/travellist-project.conf && \
    sudo a2enmod rewrite && \
    sudo a2dissite 000-default.conf && \
    sudo a2ensite travellist-project.conf && \
    sudo systemctl restart apache2'
```

### 7. Verify the setup

Replace `<EC2_PUBLIC_IP>` with the instance's public IP address.

```bash
# Check PHP version → PHP 7.4.x
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'php -v'

# Check Laravel version → Laravel Framework 8.x.x
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'php /var/www/html/travellist/artisan --version'

# Check homepage returns 200
curl -s -o /dev/null -w "%{http_code}" http://<EC2_PUBLIC_IP>
# → 200

# Check phpinfo route returns 200
curl -s -o /dev/null -w "%{http_code}" http://<EC2_PUBLIC_IP>/phpinfo
# → 200

# Confirm PHP version from phpinfo output
curl -s http://<EC2_PUBLIC_IP>/phpinfo | grep -o 'PHP Version [0-9.]*' | head -1
# → PHP Version 7.4.x
```

### 8. Browser verification

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

# Restore default Apache config
ssh -i <KEY_PATH> ubuntu@<EC2_HOST> 'sudo a2dissite travellist-project.conf && \
    sudo a2ensite 000-default.conf && \
    sudo systemctl restart apache2 && \
    sudo rm /etc/apache2/sites-available/travellist-project.conf'
```
