set -xe

INPUT_TAR=${INPUT_TAR:-/dev/sdb}

mkdir -p /tmp/input
pushd /tmp/input

tar xf $INPUT_TAR

sudo tee /etc/hosts < hosts > /dev/null
# sudo tee /etc/hostname < hostname > /dev/null
sudo hostnamectl set-hostname $(cat hostname)
sudo rm -rf /etc/netplan/*
sudo cp netplan.yaml /etc/netplan/99-netplan-config.yaml
sudo chmod 600 /etc/netplan/99-netplan-config.yaml
sudo netplan apply

sudo systemctl restart rabbitmq-server memcached etcd 

cp -r env/ ~
cp -r setup/ ~

popd
rm -rf /tmp/input
