#!/bin/bash

set -xe

sysbench oltp_read_write \
  --table-size=100 \
  --mysql-host={{ .openstack.instances.mysql.server.ip }} \
  --mysql-db=testdb \
  --mysql-user=testuser \
  --mysql-password=testpass \
  prepare
