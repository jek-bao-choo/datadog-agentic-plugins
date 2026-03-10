FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites and add ondrej/php PPA for PHP 8.3
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:ondrej/php -y && \
    apt-get update

# Install PHP 8.3, PHP-FPM, Nginx, and utilities
RUN apt-get install -y \
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
    git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer (latest stable)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Create Laravel 12 project
RUN composer create-project laravel/laravel:^12.0 /var/www/html/travellist

# Create SQLite database (Laravel 12 default)
RUN touch /var/www/html/travellist/database/database.sqlite

# Add phpinfo route
COPY routes-web.php /tmp/routes-web.php
RUN cat /tmp/routes-web.php >> /var/www/html/travellist/routes/web.php

# Set permissions
RUN chown -R www-data:www-data /var/www/html/travellist && \
    chmod -R 775 /var/www/html/travellist/storage && \
    chmod -R 777 /var/www/html/travellist/storage/logs

# Configure Nginx
COPY travellist-nginx.conf /etc/nginx/sites-available/travellist-nginx.conf
RUN ln -sf /etc/nginx/sites-available/travellist-nginx.conf /etc/nginx/sites-enabled/travellist-nginx.conf && \
    rm -f /etc/nginx/sites-enabled/default

# Create PHP-FPM run directory
RUN mkdir -p /run/php

EXPOSE 80

CMD service php8.3-fpm start && nginx -g 'daemon off;'
