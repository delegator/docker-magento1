FROM alpine:3.8
MAINTAINER Tom Richards <tom.r@delegator.com>

# Removals:
# - nullmailer
# - mcrypt (php)
RUN apk add --update --no-cache \
  php7 php7-bcmath php7-curl php7-fpm php7-gd php7-iconv php7-intl php7-opcache php7-pdo_mysql php7-soap php7-xsl php7-xml php7-zip \
  composer php7-xdebug \
  nginx nginx-mod-http-headers-more nginx-mod-http-geoip \
  bash supervisor \
  curl htop git vim wget \
  mysql-client \
  redis \
  nodejs yarn \
  ruby ruby-dev ruby-rake \
  sassc

# Add non-privileged web server user
RUN deluser xfs \
 && delgroup www-data \
 && addgroup -S -g 33 www-data \
 && adduser -S -D -u 33 -G www-data -s /bin/bash www-data

# Nginx config
RUN rm -f /etc/nginx/conf.d/default.conf; \
    ln -sf /dev/stdout /var/log/nginx/access.log; \
    ln -sf /dev/stderr /var/log/nginx/error.log;

# n98-magerun for Magento 1
RUN curl -sL https://files.magerun.net/n98-magerun-1.101.1.phar -o /usr/local/bin/n98-magerun \
 && chmod +x /usr/local/bin/n98-magerun

# Port helper
COPY src/wait-for-port /usr/local/bin/wait-for-port

# Install config files and tester site
COPY ./config/nginx /etc/nginx
COPY ./config/php /etc/php
COPY ./config/php-fpm /etc/php-fpm.d
COPY ./config/supervisor.d /etc/supervisor.d/
COPY ./tester /usr/share/nginx/tester

# Test configuration
RUN /usr/sbin/nginx -T

# Set working directory
RUN chown -R www-data:www-data /var/www
WORKDIR /var/www

# Default command
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]

# Expose ports
EXPOSE 80
