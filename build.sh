#!/bin/bash
cat << _EOF_ > Dockerfile
FROM debian:latest
MAINTAINER Evgeny Savitsky <evgeny.savitsky@devprom.ru>

#
RUN apt-get -y update && apt-get -y install apache2 xvfb phantomjs unzip wget \
  php7.0 libapache2-mod-php7.0 php7.0-gd php7.0-common php7.0-curl php7.0-xml php7.0-mbstring php7.0-imagick
  
RUN mkdir -p /var/www/devprom && \
  wget -O /var/www/devprom/master.zip https://github.com/devprom-dev/math-server/archive/master.zip && \
  unzip /var/www/devprom/master.zip -d /var/www/devprom/ && \
  mv /var/www/devprom/math-server-master /var/www/devprom/htdocs

RUN cd /var/www/devprom/htdocs && \
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
  composer update && \
  chmod -R 775 * && \
  chown -R www-data:www-data *
  
#
RUN rm /etc/apache2/sites-available/* && rm /etc/apache2/sites-enabled/*
COPY apache2/devprom.conf /etc/apache2/sites-available/
RUN a2ensite devprom.conf

CMD ( set -e && \
  export APACHE_RUN_USER=www-data && export APACHE_RUN_GROUP=www-data && export APACHE_PID_FILE=/var/run/apache2/.pid && \
  export APACHE_RUN_DIR=/var/run/apache2 && export APACHE_LOCK_DIR=/var/lock/apache2 && export APACHE_LOG_DIR=/var/log/apache2 && \
  exec apache2 -DFOREGROUND )
_EOF_

docker pull debian:latest
docker build -t devprom/math:latest .
docker push devprom/math:latest
