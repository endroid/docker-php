FROM dunglas/frankenphp:php8.5-alpine

# Install bash
RUN apk add --no-cache bash

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install GD
RUN apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev zlib-dev
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-install gd

# Install Git and delta
RUN apk add --no-cache git openssh

# NodeJS and NPM
RUN apk add --no-cache nodejs npm

# Add passwd entry for UID 1000 so SSH and git work with user: 1000
RUN echo "dev:x:1000:1000::/home/www-data:/bin/bash" >> /etc/passwd

# Add bash configuration
COPY .bashrc /home/www-data/.bashrc
RUN chmod 777 /home/www-data/.bashrc

USER 1000
