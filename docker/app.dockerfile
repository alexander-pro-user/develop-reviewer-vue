#PHP and Apache Options
FROM php:8.3-apache
WORKDIR /var/www/project

# Arguments defined in docker-compose.yml
ARG user
ARG uid

# Install system dependencies
RUN apt-get update \
    && apt-get install -y \
        git \
        curl \
        libpng-dev \
        libonig-dev \
        libxml2-dev \
        zip \
        unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# Install and activate the Xdebug extension
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Remove temporary files and packages
RUN apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /tmp/*

# Get latest Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create system user to run Composer and Artisan Commands
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

COPY /docker/php/config/xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Copy the virtual host configuration file
COPY /docker/apache/config/httpd-vhosts.conf /etc/apache2/sites-available/my-vhost.conf

# Include the virtual host configuration file in the main Apache configuration file
RUN ln -s /etc/apache2/sites-available/my-vhost.conf /etc/apache2/sites-enabled/my-vhost.conf

# Setting up logging
RUN chmod -R 755 /var/log/apache2 \
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log


# Install and activate the mod_rewrite module
RUN a2enmod rewrite
RUN service apache2 restart

RUN chown -R www-data:www-data /var/www/project && chmod -R 755 /var/www/project