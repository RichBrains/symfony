#!/usr/bin/env sh
cd /var/www;
php bin/console cache:warmup
chmod 777 /var/www/var -R
php-fpm -F &
nginx -g 'daemon off;' &
tail -f /dev/null
