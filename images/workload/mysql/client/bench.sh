#!/bin/bash
set -xe

SERVER_IP=${SERVER_IP:-10.10.11.111}

sysbench oltp_read_write \
  --threads=1 \
  --time=2 \
  --mysql-host=${SERVER_IP} \
  --mysql-db=testdb \
  --mysql-user=testuser \
  --mysql-password=testpass \
  run
