#!/bin/bash

set -xe

export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -f && apt-get install -y \
    net-tools rsh-server rsh-redone-client \
    mysql-server

echo '+ +' > ~/.rhosts
chmod 600 ~/.rhosts

sed -i '/^bind-address/s/127.0.0.1/0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql

cat<<EOF | mysql -u root
CREATE DATABASE testdb;
CREATE USER 'testuser'@'%' IDENTIFIED BY 'testpass';
GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'%';
FLUSH PRIVILEGES;
EOF
