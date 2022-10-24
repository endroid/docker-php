FROM ghcr.io/roadrunner-server/roadrunner:2.11.4 AS roadrunner
FROM php:8.1.11-fpm-alpine3.16

COPY --from=roadrunner /usr/bin/rr /usr/local/bin/rr

# Install usermod and usermod www-data
RUN echo http://dl-2.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories
RUN apk add --no-cache shadow
RUN usermod -u 1000 www-data

# Install GD
RUN apk add --no-cache freetype-dev libjpeg-turbo-dev libpng-dev libzip-dev zlib-dev
RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg
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

# Install composer (updated via entry point)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install wkhtmltopdf
RUN apk add --no-cache wkhtmltopdf xvfb ttf-dejavu ttf-droid ttf-freefont ttf-liberation
RUN ln -s /usr/bin/wkhtmltopdf /usr/local/bin/wkhtmltopdf
RUN chmod +x /usr/local/bin/wkhtmltopdf

# Install sockets
RUN docker-php-ext-install sockets

# Install intl
RUN docker-php-ext-install intl

# Install XSL
RUN apk add --no-cache libxslt-dev && docker-php-ext-install xsl

# Custom PHP settings
ADD zzzz-config.ini /usr/local/etc/php/conf.d/zzzz-config.ini

# Install some global packages
RUN apk add --no-cache bash git jq moreutils openssh rsync yq

# Add bash configuration
ADD .bashrc /home/www-data/.bashrc

# Add localhost SSL certificates
ADD ssl /etc/ssl

# Add entrypoint
ADD entrypoint.sh /home/root/entrypoint.sh

WORKDIR /var/www/html

RUN chown -R 1000 /var/www

USER www-data

ENTRYPOINT /home/root/entrypoint.sh
