FROM dunglas/frankenphp:php8.6-alpine

# Install bash
RUN apk add --no-cache bash

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install GD
RUN apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev zlib-dev
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-install gd

# Install pcov (disabled by default)
# pcov 1.0.12 does not build on PHP 8.6; use the upstream fix until the next release
RUN apk add --no-cache --virtual .pcov-build-deps $PHPIZE_DEPS \
    && mkdir /tmp/pcov \
    && curl -sSL https://github.com/krakjoe/pcov/archive/c96a5742073e1c42e1d519f5b64bcfce28b1c644.tar.gz | tar -xz -C /tmp/pcov --strip-components=1 \
    && cd /tmp/pcov && phpize && ./configure && make -j"$(nproc)" && make install \
    && docker-php-ext-enable pcov \
    && cd / && rm -rf /tmp/pcov && apk del .pcov-build-deps
RUN echo "pcov.enabled=0" >> /usr/local/etc/php/conf.d/docker-php-ext-pcov.ini

# Install general tools
RUN apk add --no-cache git openssh rsync

# Add passwd entry for UID 1000 so SSH and git work with user: 1000
RUN echo "dev:x:1000:1000::/home/www-data:/bin/bash" >> /etc/passwd

# Add bash configuration
COPY .bashrc /home/www-data/.bashrc
RUN chmod 777 /home/www-data/.bashrc

USER 1000
