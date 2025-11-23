FROM ghcr.io/roadrunner-server/roadrunner:2025.1.5 AS roadrunner
FROM php:8.5.0-fpm-alpine3.22

COPY --from=roadrunner /usr/bin/rr /usr/local/bin/rr

# Install usermod and usermod www-data
RUN echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories
RUN apk add --no-cache shadow
RUN usermod -u 1000 www-data

# Install PostgreSQL
RUN apk add --no-cache postgresql-dev postgresql-client
RUN docker-php-ext-install pdo pdo_pgsql

# Install composer (updated via entry point)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install sockets extension
RUN apk add --no-cache linux-headers
RUN docker-php-ext-install sockets

# Install intl extension
RUN docker-php-ext-install intl

# Install GD
RUN apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev zlib-dev
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg --with-webp
RUN docker-php-ext-install gd

# Install ZIP
RUN apk add --no-cache libzip-dev
RUN docker-php-ext-install zip

# Install some global packages
RUN apk add --no-cache bash git jq moreutils openssh rsync yq

# Add Xdebug 3.5.0alpha2 (compatible with PHP 8.5)
RUN apk add --no-cache autoconf build-base linux-headers
RUN cd /tmp \
    && git clone --branch 3.5.0alpha2 --depth 1 https://github.com/xdebug/xdebug.git \
    && cd xdebug \
    && phpize \
    && ./configure \
    && make \
    && make install \
    && docker-php-ext-enable xdebug \
    && cd / \
    && rm -rf /tmp/xdebug

# Install Blackfire PHP Probe
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && architecture=$(uname -m) \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/alpine/$architecture/$version \
    && mkdir -p /tmp/blackfire \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8307\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
    && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz

# Install and enable OpenTelemetry
RUN apk add --no-cache autoconf build-base linux-headers
RUN pecl install opentelemetry
RUN docker-php-ext-enable opentelemetry

# Add bash configuration
COPY .bashrc /home/www-data/.bashrc
RUN chmod 777 /home/www-data/.bashrc

WORKDIR /var/www/html

RUN chown -R 1000 /var/www

USER www-data
