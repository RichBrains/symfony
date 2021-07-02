FROM php:7.4-fpm-alpine

RUN apk add --no-cache --virtual .ext-deps \
        libjpeg-turbo-dev \
        libwebp-dev \
        libpng-dev \
        freetype-dev \
        libmcrypt-dev \
        nodejs-npm \
        git \
        inkscape \
        libzip-dev unzip

RUN apk add --update --no-cache \
    libc6-compat fontconfig \
    libgcc libstdc++ libx11 glib libxrender libxext libintl \
    ttf-dejavu ttf-droid ttf-freefont ttf-liberation ttf-ubuntu-font-family \
    jpegoptim optipng pngquant gifsicle


# Add openssl dependencies for wkhtmltopdf
RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.8/main' >> /etc/apk/repositories && \
    apk add --no-cache libcrypto1.0 libssl1.0

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
# imagick
RUN set -ex \
&& apk add --no-cache --virtual .phpize-deps $PHPIZE_DEPS imagemagick-dev libtool \
&& export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
&& pecl install imagick \
&& docker-php-ext-enable imagick \
&& apk add --no-cache --virtual .imagick-runtime-deps imagemagick \
&& apk del .phpize-deps

RUN docker-php-ext-configure pdo_mysql && \
    docker-php-ext-configure opcache && \
    docker-php-ext-configure exif && \
    docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype

RUN docker-php-ext-install pdo_mysql opcache exif gd zip && \
    docker-php-source delete

COPY php.ini /usr/local/etc/php/conf.d/php.ini

RUN ln -s /usr/bin/php7 /usr/bin/php