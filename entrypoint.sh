#!/usr/bin/env sh
cd /var/www/html;
php -d memory_limit=512M bin/console cache:clear --env=prod
chmod 777 /var/www/html/var -R
php-fpm -F &
nginx -g 'daemon off;' &
tail -f /dev/null
