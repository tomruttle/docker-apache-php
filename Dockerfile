FROM debian:wheezy
MAINTAINER Tom Ruttle <thruttle@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

# Install base packages
RUN apt-get update && \
    apt-get -yq install \
        curl \
        apache2 \
        libapache2-mod-php5 \
        php5-gd \
        php5-curl \
        php-apc \
        wget

# Install Composer
RUN wget -q http://getcomposer.org/composer.phar &&\
    mv composer.phar /usr/local/bin/composer &&\
    chmod 0755 /usr/local/bin/composer

# Install Suhosin
RUN echo "deb http://repo.suhosin.org/ debian-wheezy main" >> /etc/apt/sources.list &&\
    wget -q https://sektioneins.de/files/repository.asc -O - | apt-key add -

RUN apt-get update &&\
    apt-get -yq install php5-suhosin-extension &&\

# We only needed wget for that one task, so now uninstall
    apt-get remove --purge -yq wget &&\
    rm -rf /var/lib/apt/lists/*

# Configure PHP
RUN sed -i -e"s/session.gc_probability.*/session.gc_probability = 1/" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/session.gc_divisor.*/session.gc_divisor = 100/" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/session.cookie_lifetime.*/session.cookie_lifetime = 200000/" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/session.gc_maxlifetime.*/session.gc_maxlifetime = 200000/" /etc/php5/apache2/php.ini ;\
    sed -i "s/variables_order.*/variables_order = \"EGPCS\"/g" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/;assert.active.*/assert.active = Off/" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/session.use_strict_mode.*/session.use_strict_mode = 1/" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/\;default_charset.*/default_charset = \"UTF-8\"/" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/allow_url_fopen.*/allow_url_fopen = Off/" /etc/php5/apache2/php.ini ;\
    sed -i -e"s/log_errors.*/log_errors = On/" /etc/php5/apache2/php.ini

# Configure Apache
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2

# Send Apache2's error logs to STDERR for Docker to pick up
RUN ln -sf /dev/stderr /var/log/apache2/error.log

EXPOSE 80

ENTRYPOINT ["/usr/sbin/apache2"]
CMD ["-D", "FOREGROUND", "-k", "start"]
