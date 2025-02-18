set -xe

INPUT_TAR=${INPUT_TAR:-/dev/sdb}

mkdir -p /tmp/input
pushd /tmp/input

tar xf $INPUT_TAR

sudo tee /etc/hosts < hosts > /dev/null
sudo tee /etc/hostname < hostname > /dev/null
sudo rm -rf /etc/netplan/*
sudo cp netplan.yaml /etc/netplan/99-netplan-config.yaml
sudo chmod 600 /etc/netplan/99-netplan-config.yaml
sudo netplan apply

sudo mv ovs-iface-up.service /etc/systemd/system
sudo systemctl enable ovs-iface-up

cp -r env/ ~
cp -r prepare/ ~
cp -r run/ ~

popd
rm -rf /tmp/input
