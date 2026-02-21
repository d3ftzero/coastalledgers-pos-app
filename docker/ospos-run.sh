#!/bin/sh
set -e

mkdir -p /app/writable/logs /app/writable/uploads /app/writable/cache /app/public/uploads/item_pics
chown -R www-data:www-data /app/writable /app/public/uploads

find /app/writable -type d -exec chmod 750 {} \;
find /app/writable -type f -exec chmod 640 {} \;
find /app/public/uploads -type d -exec chmod 750 {} \;
find /app/public/uploads -type f -exec chmod 640 {} \;

if [ -f /app/writable/uploads/importCustomers.csv ]; then
  chmod 660 /app/writable/uploads/importCustomers.csv
fi

exec apache2-foreground
