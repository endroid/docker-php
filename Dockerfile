FROM ghcr.io/roadrunner-server/roadrunner:2024.3.1 AS roadrunner
FROM php:8.4.2-fpm-alpine3.21

COPY --from=roadrunner /usr/bin/rr /usr/local/bin/rr

# Install usermod and usermod www-data
RUN echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories
RUN apk add --no-cache shadow
RUN usermod -u 1000 www-data

# Install PostgreSQL
RUN apk add --no-cache postgresql-dev postgresql-client
RUN docker-php-ext-install pdo pdo_pgsql

# Install opcache
RUN docker-php-ext-install opcache

# Install composer (updated via entry point)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install sockets extension
RUN apk add --no-cache linux-headers
RUN docker-php-ext-install sockets

# Install intl extension
RUN docker-php-ext-install intl

# Install GD
RUN apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev zlib-dev libwebp-dev
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-install gd

# Install ZIP
RUN apk add --no-cache libzip-dev
RUN docker-php-ext-install zip

# Install some global packages
RUN apk add --no-cache bash git jq moreutils openssh rsync yq

# Add Xdebug
RUN apk add --no-cache linux-headers autoconf build-base
RUN pecl install xdebug
RUN docker-php-ext-enable xdebug

# Install Blackfire PHP Probe
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && architecture=$(uname -m) \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/alpine/$architecture/$version \
    && mkdir -p /tmp/blackfire \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8307\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
    && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz

# Add bash configuration
ADD .bashrc /home/www-data/.bashrc
RUN chmod 777 /home/www-data/.bashrc

WORKDIR /var/www/html

RUN chown -R 1000 /var/www

USER www-data
