FROM richbrains/symfony:ag-base

RUN apk add --no-cache --virtual .ext-deps \
        nginx \

COPY default.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /entrypoint.sh
COPY php-fpm.conf /etc/php7/php-fpm.conf

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer --1 && \
    mkdir -p /run/nginx && mkdir -p /init/ && chmod 777 /entrypoint.sh

ENTRYPOINT /entrypoint.sh
EXPOSE 80