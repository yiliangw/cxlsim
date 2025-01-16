#!/bin/bash
d=`dirname ${BASH_SOURCE[0]}`

fdone=${d}/.done

if [ -f $fdone ]; then
    echo "Already set up"
    exit 0
fi

set -xe

source ${HOME}/env/openstackrc

bash ${d}/nova.sh
bash ${d}/neutron.sh

touch $fdone
