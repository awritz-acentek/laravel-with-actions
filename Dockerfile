FROM composer:lts as build-composer
WORKDIR /var/www/html
COPY . .
RUN composer install --no-dev --optimize-autoloader --ignore-platform-reqs

FROM node:alpine as build-npm
WORKDIR /var/www/html
COPY --from=build-composer /var/www/html .
RUN npm install && npm run build
RUN rm -rf node_modules

FROM php:8.3-fpm-alpine

LABEL authors="Andrew Writz"

WORKDIR /var/www/html

ENV DEBIAN_FRONTEND noninteractive
#ENV TZ=UTC
#RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apk update  \
    && apk add icu-dev

RUN docker-php-ext-install bcmath pdo_mysql intl

#RUN setcap "cap_net_bind_service=+ep" /usr/bin/php8.3

COPY --from=build-npm /var/www/html .
RUN chown -R www-data:www-data /var/www/html

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
COPY opcache.ini "$PHP_INI_DIR/conf.d/opcache.ini"

RUN php artisan storage:link

USER www-data
EXPOSE 9000

CMD ["php-fpm"]
