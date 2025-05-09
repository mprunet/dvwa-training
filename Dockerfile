FROM debian:12
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
    debconf-utils openssl systemctl && \
    openssl rand -hex 25 > /maria.pwd && \
    echo mariadb-server mysql-server/root_password password $(cat /maria.pwd) | debconf-set-selections && \
    echo mariadb-server mysql-server/root_password_again password $(cat /maria.pwd) | debconf-set-selections && \
    apt-get install -y \
    apache2 \
    mariadb-server \
    php \
    php-mysql \
    php-pgsql \
    php-pear \
    php-gd \
    git \
    wget \
    supervisor \
    && rm -Rf /var/www/html \ 
    && git clone --depth=1 \
               https://github.com/digininja/DVWA.git \
               /var/www/html \
    && apt-get clean 
COPY config.inc.php /var/www/html/config/
COPY supervisord.conf /etc/supervisord.conf
RUN rm -rf /var/lib/apt/lists/* && \
    chown www-data:www-data -R /var/www/html && \
    mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld && \
    /usr/bin/supervisord -c /etc/supervisord.conf & \ 
    pid=$! && \
    echo "Waiting for mysqld to start..." && \
    until mysqladmin ping --silent; do sleep 1; done && \
    mysql -e "CREATE USER app@localhost IDENTIFIED BY '`cat /maria.pwd`';CREATE DATABASE dvwa;GRANT ALL privileges ON dvwa.* TO 'app'@localhost;" && \
    sed -i -e 's/allow_url_include *= *Off/allow_url_include = On/' /etc/php/*/apache2/php.ini && \
    sed -i -e 's/display_errors *= *Off/display_errors = On/' /etc/php/*/apache2/php.ini && \
    sed -i -e 's/display_startup_errors *= *Off/display_startup_errors = On/' /etc/php/*/apache2/php.ini && \
    sed -i -e 's/error_reporting *= ./error_reporting = E_ALL/' /etc/php/*/apache2/php.ini && \
    sed -i -e 's/PASSWORDTOCHANGE/'`cat /maria.pwd`'/' /var/www/html/config/config.inc.php && \
    ln -sf /proc/self/fd/1 /var/log/apache2/access.log && \
    ln -sf /proc/self/fd/1 /var/log/apache2/error.log && \
    apache2ctl start && \
    wget -qO- --keep-session-cookies --save-cookies /tmp/cookies.txt --post-data '' http://127.0.0.1/login.php | sed -n -e 's/^.*user_token.*value=.\([a-zA-Z0-9_]*\).*$/\1/p' > /tmp/csrftoken.txt && \
    wget -qO- --load-cookies /tmp/cookies.txt --post-data 'create_db=Create+%2F+Reset+Database&user_token='`cat /tmp/csrftoken.txt` http://127.0.0.1/setup.php > /dev/null && \
    kill $pid && \
    wait $pid

    

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
