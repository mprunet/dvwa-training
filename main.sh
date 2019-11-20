#!/bin/bash

chown -R mysql:mysql /var/lib/mysql /var/run/mysqld

echo '[+] Starting mysql...'
service mysql start

echo '[+] Starting apache'
. /etc/apache2/envvars 
/usr/sbin/apache2 -DFOREGROUND
