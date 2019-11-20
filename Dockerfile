FROM debian:9.11
RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    debconf-utils openssl && \
    openssl rand -hex 25 > /maria.pwd && \
    echo mariadb-server mysql-server/root_password password $(cat /maria.pwd) | debconf-set-selections && \
    echo mariadb-server mysql-server/root_password_again password $(cat /maria.pwd) | debconf-set-selections && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    apache2 \
    mariadb-server \
    php \
    php-mysql \
    php-pgsql \
    php-pear \
    php-gd \
    git \
    wget \
    && rm -Rf /var/www/html \ 
    && git clone --depth=1 \
               https://github.com/ethicalhack3r/DVWA.git \
               /var/www/html \
    && apt-get clean 
COPY config.inc.php /var/www/html/config/
RUN rm -rf /var/lib/apt/lists/* && \
    chown www-data:www-data -R /var/www/html && \
    service mysql start && \
    service apache2 start && \
    sleep 3 && \
    mysql -e "CREATE USER app@localhost IDENTIFIED BY '`cat /maria.pwd`';CREATE DATABASE dvwa;GRANT ALL privileges ON dvwa.* TO 'app'@localhost;" && \
    sed -i -e 's/allow_url_include *= *Off/allow_url_include = On/' /etc/php/7.0/apache2/php.ini && \
    sed -i -e 's/PASSWORDTOCHANGE/'`cat /maria.pwd`'/' /var/www/html/config/config.inc.php && \
    ln -sf /proc/self/fd/1 /var/log/apache2/access.log && \
    ln -sf /proc/self/fd/1 /var/log/apache2/error.log && \
    wget -qO- --keep-session-cookies --save-cookies /tmp/cookies.txt --post-data '' http://127.0.0.1/login.php | sed -n -e 's/^.*user_token.*value=.\([a-zA-Z0-9_]*\).*$/\1/p' > /tmp/csrftoken.txt && \
    wget -qO- --load-cookies /tmp/cookies.txt --post-data 'create_db=Create+%2F+Reset+Database&user_token='`cat /tmp/csrftoken.txt` http://127.0.0.1/setup.php > /dev/null

EXPOSE 80

COPY main.sh /
ENTRYPOINT ["/main.sh"]
