FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install prerequisites and add ondrej/php PPA for PHP 7.4
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:ondrej/php -y && \
    apt-get update

# Install PHP 7.4, Apache2, and utilities
RUN apt-get install -y \
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
    git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Composer 2.2.x (last version compatible with PHP 7.4)
RUN curl -sS https://getcomposer.org/installer | php -- --version=2.2.24 --install-dir=/usr/local/bin --filename=composer

# Create Laravel 8 project
RUN composer create-project laravel/laravel:^8.0 /var/www/html/travellist

# Add phpinfo route
COPY routes-web.php /tmp/routes-web.php
RUN cat /tmp/routes-web.php >> /var/www/html/travellist/routes/web.php

# Set permissions
RUN chown -R www-data:www-data /var/www/html/travellist && \
    chmod -R 775 /var/www/html/travellist/storage && \
    chmod -R 777 /var/www/html/travellist/storage/logs

# Configure Apache
COPY travellist-project.conf /etc/apache2/sites-available/travellist-project.conf
RUN a2enmod rewrite && \
    a2dissite 000-default.conf && \
    a2ensite travellist-project.conf

EXPOSE 80

CMD ["apache2ctl", "-D", "FOREGROUND"]
