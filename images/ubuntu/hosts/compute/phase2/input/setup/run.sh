#!/bin/bash
d=`dirname ${BASH_SOURCE[0]}`

fdone=${d}/.done

if [ -f $fdone ]; then
    echo "Already set up"
    exit 0
fi

set -xe

sudo tee /etc/chrony/chrony.conf < ${d}/chrony.conf > /dev/null
sudo systemctl restart chrony

source ~/env/openstackrc

bash ${d}/nova.sh
bash ${d}/neutron.sh

touch $fdone
