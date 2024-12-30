#!/bin/bash
d=`dirname ${BASH_SOURCE[0]}`
. ${HOME}/env/passwdrc

# Create the glance database
cat <<EOF | sudo mysql -u root
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${GLANCE_DBPASS}';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${GLANCE_DBPASS}';
EOF
