#!/bin/bash

set -xe

SERVER_IP=${SERVER_IP:-10.10.11.111}

mysql -h $SERVER_IP -u testuser --password=testpass -e "SELECT 1;"
