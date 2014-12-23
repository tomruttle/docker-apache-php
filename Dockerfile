FROM debian:wheezy
MAINTAINER Tom Ruttle <thruttle@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

# Install base packages
RUN apt-get update && \
    apt-get -yq install \
        curl \
        apache2 \
        libapache2-mod-php5 \
        php5-mysql \
        php5-gd \
        php5-curl \
#        php-pear \
        php-apc \
        wget

RUN echo "deb http://repo.suhosin.org/ ubuntu-trusty main" >> /etc/apt/sources.list &&\
    wget -q https://sektioneins.de/files/repository.asc -O - | apt-key add -

RUN apt-get update &&\
    apt-get -yq install php5-suhosin-extension &&\
    apt-get remove --purge wget &&\
    rm -rf /var/lib/apt/lists/*

# Configure PHP for Drupal
RUN sed -i -e"s/^memory_limit\s*=\s*128M/memory_limit = 256M/" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/session.gc_probability\s*=\s*0/session.gc_probability = 1/" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/session.gc_divisor\s*=\s*1000/session.gc_divisor = 100/" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/session.gc_maxlifetime\s*=\s*1440/session.gc_maxlifetime = 200000/" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/session.cookie_lifetime\s*=\s*0/session.cookie_lifetime = 200000/" /etc/php5/apache2/php.ini ;\
    sed -i "s/variables_order.*/variables_order = \"EGPCS\"/g" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/log_errors\s*=\s*Off/log_errors = On/" /etc/php5/apache2/php.ini

# Configure PHP for Security
RUN sed -i -e"s/;assert.active\s*=\s*On/assert.active = Off/" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/session.use_strict_mode\s*=\s*0/session.use_strict_mode = 1/" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/\;default_charset\s*=\s*\"UTF-8\"/default_charset = \"UTF-8\"/" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/allow_url_fopen\s*=\s*On/allow_url_fopen = Off/" /etc/php5/apache2/php.ini

# Configure Apache
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2

RUN sed -i 's/AllowOverride None/AllowOverride All/' /etc/apache2/sites-available/default
RUN a2enmod headers rewrite vhost_alias

# Send Apache's error logs to STDERR for Docker to pick up
RUN ln -sf /dev/stderr /var/log/apache2/error.log

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

EXPOSE 80

ENTRYPOINT ["/usr/sbin/apache2"]
CMD ["-D", "FOREGROUND", "-k", "start"]

