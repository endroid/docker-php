FROM dunglas/frankenphp:php8.6-alpine

# Install bash
RUN apk add --no-cache bash

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install GD
RUN apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev zlib-dev
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-install gd

# Install extensions
RUN install-php-extensions mbstring pdo_pgsql zip

# Install Xdebug (loaded but off; enable with XDEBUG_MODE=coverage)
# No stable Xdebug supports PHP 8.6 yet; switch to the stable 3.6 release when available
RUN install-php-extensions xdebug/xdebug@3.6.0alpha1
RUN echo "xdebug.mode=off" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

# Install general tools
RUN apk add --no-cache git jq moreutils nodejs npm openssh rsync

# Add passwd entry for UID 1000 so SSH and git work with user: 1000
RUN echo "dev:x:1000:1000::/home/www-data:/bin/bash" >> /etc/passwd

# Add bash configuration
COPY .bashrc /home/www-data/.bashrc
RUN chmod 777 /home/www-data/.bashrc

USER 1000
