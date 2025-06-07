#!/bin/bash
set -xe

SERVER_IP=${SERVER_IP:-10.10.11.111}

usermod -aG disk $USER

export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -f && apt-get install -y \
  net-tools \
  sysbench \
  mysql-client \
  stress-ng

# wait until the server's MySQL server is ready
while ! mysqladmin ping -h ${SERVER_IP} -u testuser --password=testpass --silent; do
    echo "Waiting for MySQL server at ${SERVER_IP} to be ready..."
    sleep 3
done

sysbench oltp_read_write \
  --table-size=100 \
  --mysql-host=${SERVER_IP} \
  --mysql-db=testdb \
  --mysql-user=testuser \
  --mysql-password=testpass \
  prepare
