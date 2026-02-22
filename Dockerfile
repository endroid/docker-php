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
RUN apk add --no-cache git delta

# Add bash configuration
COPY .bashrc /home/www-data/.bashrc
RUN chmod 777 /home/www-data/.bashrc
