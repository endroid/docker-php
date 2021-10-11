FROM php:8.0.11-fpm-alpine3.14

# Install usermod and usermod www-data
RUN echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories
RUN apk add --no-cache shadow
RUN usermod -u 1000 www-data

# Install GD
RUN apk add --no-cache libpng-dev libzip-dev zlib-dev
RUN docker-php-ext-install gd

# Install ZIP
RUN apk add --no-cache zip
RUN docker-php-ext-install zip

# Install PostgreSQL
RUN apk add --no-cache postgresql-dev
RUN docker-php-ext-install pdo pdo_pgsql

# Install PCOV
RUN apk add --no-cache autoconf build-base
RUN pecl install pcov && docker-php-ext-enable pcov

# Install opcache
RUN docker-php-ext-install opcache

# Install Blackfire Probe
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && architecture=$(uname -m) \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/alpine/$architecture/$version \
    && mkdir -p /tmp/blackfire \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8307\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
    && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz

# Custom PHP settings
ADD zzzz-config.ini /usr/local/etc/php/conf.d/zzzz-config.ini

# Install some global packages
RUN apk add --no-cache bash git

WORKDIR /var/www/html

RUN chown -R 1000 /var/www

USER www-data
