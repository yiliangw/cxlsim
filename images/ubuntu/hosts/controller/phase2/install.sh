set -xe

mkdir -p /tmp/input
cd /tmp/input
tar xf /dev/sdb

cp ssh/* ~/.ssh
chmod 600 ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

sudo tee /etc/hosts < hosts > /dev/null
sudo tee /etc/hostname < hostname > /dev/null
sudo rm -rf /etc/netplan/*
sudo cp netplan.yaml /etc/netplan/99-netplan-config.yaml
sudo chmod 600 /etc/netplan/99-netplan-config.yaml

sudo tee /etc/network/interfaces < interfaces > /dev/null

cp -r env/ ~
cp -r setup/ ~
