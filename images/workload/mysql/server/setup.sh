#!/bin/bash

set -xe

sudo apt-get update
sudo apt-get install -y net-tools mysql-server

sudo sed -i '/^bind-address/s/127.0.0.1/0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

cat<<EOF |sudo mysql -u root
CREATE DATABASE testdb;
CREATE USER 'testuser'@'%' IDENTIFIED BY 'testpass';
GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'%';
FLUSH PRIVILEGES;
EOF
