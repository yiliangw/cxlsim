#!/bin/bash
set -xe

echo '+ +' > ~/.rhosts
chmod 600 ~/.rhosts

usermod -aG disk $USER

export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get install -f && apt-get install -y \
  net-tools rsh-redone-server rsh-redone-client \
  sysbench \
  mysql-client \
  stress-ng
