#!/bin/bash

pushd $(dirname ${BASH_SOURCE[0]})

# Prevent automatically loading interface drivers
sudo install -m 644 blacklist-simbricks-if.conf /etc/modprobe.d/blacklist-simbricks-if.conf
sudo update-initramfs -u

popd
