FROM php:7-fpm-alpine

RUN apk add --no-cache --virtual .ext-deps \
        libjpeg-turbo-dev \
        libwebp-dev \
        libpng-dev \
        freetype-dev \
        libmcrypt-dev \
        nodejs-npm \
        nginx \
        git \
        inkscape \
        libmemcached-dev

RUN apk add --update --no-cache \
    libc6-compat fontconfig \
    libgcc libstdc++ libx11 glib libxrender libxext libintl \
    libcrypto1.0 libssl1.0 \
    ttf-dejavu ttf-droid ttf-freefont ttf-liberation ttf-ubuntu-font-family \
    jpegoptim optipng pngquant gifsicle

RUN apk add --no-cache --update libmemcached-libs zlib
RUN set -xe && \
    cd /tmp/ && \
    apk add --no-cache --update --virtual .phpize-deps $PHPIZE_DEPS && \
    apk add --no-cache --update --virtual .memcached-deps zlib-dev libmemcached-dev cyrus-sasl-dev && \
# Install igbinary (memcached's deps)
    pecl install igbinary && \
# Install memcached
    ( \
        pecl install --nobuild memcached && \
        cd "$(pecl config-get temp_dir)/memcached" && \
        phpize && \
        ./configure --enable-memcached-igbinary && \
        make -j$(nproc) && \
        make install && \
        cd /tmp/ \
    ) && \
# Enable PHP extensions
    docker-php-ext-enable igbinary memcached && \
    apk del .memcached-deps .phpize-deps


# imagick
RUN apk add --update --no-cache autoconf g++ imagemagick-dev libtool make pcre-dev \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && apk del autoconf g++ libtool make pcre-dev

RUN docker-php-ext-configure pdo_mysql && \
    docker-php-ext-configure opcache && \
    docker-php-ext-configure exif && \
    docker-php-ext-configure gd \
    --with-jpeg-dir=/usr/include --with-png-dir=/usr/include --with-webp-dir=/usr/include --with-freetype-dir=/usr/include

RUN docker-php-ext-install pdo_mysql opcache exif gd zip && \
    docker-php-source delete

COPY default.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh
COPY php-fpm.conf /etc/php7/php-fpm.conf

RUN ln -s /usr/bin/php7 /usr/bin/php && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
    mkdir -p /run/nginx && mkdir -p /init/ && chmod 777 /entrypoint.sh

ENTRYPOINT /entrypoint.sh
EXPOSE 80
