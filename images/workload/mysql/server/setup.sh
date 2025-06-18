#!/bin/bash
set -xe

echo '+ +' > ~/.rhosts
chmod 600 ~/.rhosts

export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -f && apt-get install -y \
    net-tools rsh-redone-server rsh-redone-client \
    mysql-server

sed -i '/^bind-address/s/127.0.0.1/0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
systemctl restart mysql
