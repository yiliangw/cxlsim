#!/bin/bash

set -xe

cat <<EOF | mysql -u testuser -p testpass -h {{ .openstack.instances.mysql.server.ip }} 
SHOW DATABASES;
USE testdb;
CREATE TABLE example (id INT PRIMARY KEY, name VARCHAR(50));
INSERT INTO example VALUES (1, 'Sample');
SELECT * FROM example;
EOF
