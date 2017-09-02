FROM debian:latest
MAINTAINER Adam Talsma <se-adam.talsma@ccpgames.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -qqy \
&& apt-get install -qqy curl git expect gnupg bzip2 \
&& apt-get install -qqy php7.0 php7.0-dev php7.0-cli php7.0-mcrypt php7.0-intl php7.0-mysql php7.0-curl php7.0-gd mysql-client mariadb-server build-essential libtool autoconf uuid-dev pkg-config libsodium-dev

# Installing ZMQ
ARG ZMQ_VERSION=4.1.4
RUN curl -L https://archive.org/download/zeromq_$ZMQ_VERSION/zeromq-$ZMQ_VERSION.tar.gz > /tmp/zeromq-$ZMQ_VERSION.tar.gz \
  && cd /tmp \
  && ls -l \
  && tar xvzf zeromq-$ZMQ_VERSION.tar.gz \
  && cd zeromq-$ZMQ_VERSION \
  && ./configure \
  && make \
  && make install \
  && ldconfig \
  && cd /tmp \
  && rm -rf zeromq-$ZMQ_VERSION \
  && rm zeromq-$ZMQ_VERSION.tar.gz

  # Now php-zmq
#RUN curl -L https://github.com/mkoppanen/php-zmq/archive/1.1.2.tar.gz > /tmp/php-zeromq.tar.gz \
#  && cd /tmp \
#  && tar xvfz php-zeromq.tar.gz \
#  && cd php-zmq-1.1.2 \
#  && phpize \
#  && ./configure \
#  && make \
#  && make install \
#  && cd .. \
#  && rm -fr php-zmq \
#  && echo "extension=zmq.so" > /etc/php/7.0/mods-available/zmq.ini \
#  && phpenmod zmq

RUN pecl install zmq-1.1.3 \
 && echo "extension=zmq.so" > /etc/php/7.0/mods-available/zmq.ini \
 && phpenmod zmq

# Installing Composer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer

ARG MYSQL_DUMP_HOST=https://www.fuzzwork.co.uk/dump
ARG GIT_BRANCH=master
RUN curl -L $MYSQL_DUMP_HOST/mysql-latest.tar.bz2 > /tmp/mysql-latest.tar.bz2 \
&& rm -rf /var/www/html \
&& git clone -b $GIT_BRANCH --single-branch https://github.com/exodus4d/pathfinder.git /var/www/html \
&& chown -R www-data:www-data /var/www/html \
&& cd /var/www/html \
&& composer install

COPY start_mysql.sh /usr/local/bin/
COPY seed_ccp_data.sh /tmp/seed_ccp_data.sh

# This seems to be required on some versions of docker, otherwise, it raises a
# permission denied error
RUN chmod +x /tmp/seed_ccp_data.sh \
  && chmod +x /usr/local/bin/start_mysql.sh

RUN /tmp/seed_ccp_data.sh && rm -fr /tmp/*

# Making /var/lib/mysql persistant
VOLUME /var/lib/mysql

EXPOSE 80
WORKDIR /var/www/html

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
CMD /entrypoint.sh
