#!/bin/bash
cat << _EOF_ > Dockerfile
FROM debian:latest
MAINTAINER Evgeny Savitsky <evgeny.savitsky@devprom.ru>

#
RUN apt-get -y update && apt-get -y install apache2 xvfb phantomjs unzip wget \
  php libapache2-mod-php php-gd php-common php-curl php-xml php-mbstring php-imagick ca-certificates curl bzip2

RUN mkdir  -p /var/www/devprom && \
  wget -O /var/www/devprom/master.zip https://github.com/devprom-dev/math-server/archive/master.zip && \
  unzip /var/www/devprom/master.zip -d /var/www/devprom/ && \
  mv /var/www/devprom/math-server-master /var/www/devprom/htdocs

RUN cd /var/www/devprom/htdocs && \
  apt-get -y install curl && \
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer && \
  composer update && \
  chmod -R 775 * && \
  chown -R www-data:www-data *

RUN mkdir /var/log/devprom && \
  chmod -R 775 /var/log/devprom && \
  chown -R www-data:www-data /var/log/devprom

#
RUN rm /etc/apache2/sites-available/* && rm /etc/apache2/sites-enabled/*
COPY apache2/math.conf /etc/apache2/sites-available/
RUN a2ensite math.conf
RUN a2enmod rewrite

CMD ( set -e && \
  export APACHE_RUN_USER=www-data && export APACHE_RUN_GROUP=www-data && export APACHE_PID_FILE=/var/run/apache2/.pid && \
  export APACHE_RUN_DIR=/var/run/apache2 && export APACHE_LOCK_DIR=/var/lock/apache2 && export APACHE_LOG_DIR=/var/log/apache2 && \
  exec apache2 -DFOREGROUND )
_EOF_

docker pull debian:latest
docker build -t devprom/math:latest .
docker push devprom/math:latest
