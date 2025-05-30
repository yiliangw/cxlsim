#!/bin/bash
set -xe

pushd `dirname ${BASH_SOURCE[0]}`

if [ -f .done ]; then
    echo "Already set up"
    exit 1
fi

sudo tee /etc/chrony/chrony.conf < chrony.conf > /dev/null
sudo systemctl restart chrony

source ~/env/openstackrc

bash nova.sh
bash neutron.sh

sudo systemctl restart ovs-iface-up

touch .done

popd
