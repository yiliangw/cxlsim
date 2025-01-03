#!/bin/bash
d=`dirname ${BASH_SOURCE[0]}`

set -xe

source ${HOME}/env/passwdrc

bash ${d}/nova.sh
bash ${d}/neutron.sh
