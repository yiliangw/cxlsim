#!/bin/bash
set -xe

SERVER_IP=${SERVER_IP:-10.10.11.111}

sudo usermod -aG disk $USER

sudo apt-get update
sudo apt-get install -y \
  net-tools \
  sysbench \
  mysql-client

sysbench oltp_read_write \
  --table-size=100 \
  --mysql-host=${MYSQL_SERVER_IP} \
  --mysql-db=testdb \
  --mysql-user=testuser \
  --mysql-password=testpass \
  prepare