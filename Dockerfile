# ---- 1) Build vendor/ with PHP 8.2 + intl ----
FROM php:8.2-cli AS vendor
WORKDIR /app

ENV COMPOSER_ALLOW_SUPERUSER=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip libicu-dev \
    && docker-php-ext-install intl \
    && rm -rf /var/lib/apt/lists/*

# Composer binary (we only copy the binary, not the PHP runtime)
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copy composer manifests first for caching
COPY composer.json composer.lock ./

# Install prod deps
RUN composer install \
    --no-dev \
    --prefer-dist \
    --no-interaction \
    --no-progress \
    --optimize-autoloader \
    --classmap-authoritative


# ---- 2) Build frontend assets ----
FROM composer:2 AS assets
WORKDIR /app
RUN apk add --no-cache nodejs npm
COPY . /app

RUN npm ci && npm run build

# ---- 3) Runtime: Apache + PHP 8.2 ----
FROM php:8.2-apache AS ospos
LABEL maintainer="d3ftzero"
ARG COMMIT_SHA=dev

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl libicu-dev libgd-dev \
    && a2enmod rewrite \
    && sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf \
    && a2enmod headers \
    && docker-php-ext-install mysqli bcmath intl gd \
    && rm -rf /var/lib/apt/lists/*

# Set default timezone
# Override at runtime via app config if needed.
RUN echo "date.timezone = UTC" > /usr/local/etc/php/conf.d/timezone.ini

WORKDIR /app
COPY . /app
RUN sed -i "s/public string \$commit_sha1 = '.*';/public string \$commit_sha1 = '${COMMIT_SHA}';/" /app/app/Config/OSPOS.php

# Bring in built frontend assets
COPY --from=assets /app/app/Views/partial/header.php /app/app/Views/partial/header.php
COPY --from=assets /app/public/resources /app/public/resources
COPY --from=assets /app/public/images/menubar /app/public/images/menubar
COPY --from=assets /app/public/license /app/public/license

# Bring in vendor/ from builder
COPY --from=vendor /app/vendor /app/vendor

# Apache docroot to /app/public
RUN rm -rf /var/www/html \
    && ln -nsf /app/public /var/www/html

COPY docker/ospos-run.sh /usr/local/bin/ospos-run.sh
RUN chmod +x /usr/local/bin/ospos-run.sh

# Ensure writable dirs exist and permissions are correct
RUN mkdir -p /app/writable/uploads /app/writable/logs /app/writable/cache \
    && chown -R www-data:www-data /app \
    && find /app/writable -type d -exec chmod 0750 {} \; \
    && find /app/writable -type f -exec chmod 0640 {} \; \
    && [ -f /app/writable/uploads/importCustomers.csv ] \
    && chmod 0660 /app/writable/uploads/importCustomers.csv || true

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -fsS http://127.0.0.1/ >/dev/null || exit 1

CMD ["/usr/local/bin/ospos-run.sh"]
