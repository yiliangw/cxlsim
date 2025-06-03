#!/bin/bash
set -xe

pushd `dirname ${BASH_SOURCE[0]}`

if [ -f .done ]; then
    echo "Already set up"
    exit 1
fi

sudo tee /etc/chrony/chrony.conf < chrony.conf > /dev/null
sudo systemctl restart chrony

# Configure libvirtd for live migration
sudo sed -i 's/^#listen_tls.*/listen_tls = 0/' /etc/libvirt/libvirtd.conf
sudo sed -i 's/^#listen_tcp.*/listen_tcp = 1/' /etc/libvirt/libvirtd.conf
sudo sed -i 's/^#auth_tcp.*/auth_tcp = "none"/' /etc/libvirt/libvirtd.conf
# Configure socket activation for libvirt
sudo systemctl disable libvirtd
sudo systemctl stop libvirtd
sudo systemctl mask libvirtd-tls.socket
sudo systemctl enable libvirtd-tcp.socket
sudo systemctl start libvirtd-tcp.socket

# Configure nova user for cold migration
sudo mkdir -p /var/lib/nova/.ssh
pushd /var/lib/nova/.ssh
sudo cp ~/.ssh/id_rsa.pub authorized_keys
sudo cp ~/.ssh/id_rsa id_rsa
sudo tee config > /dev/null <<EOF
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
EOF
sudo chmod 600 authorized_keys id_rsa config
sudo chown -R nova:nova /var/lib/nova/.ssh
popd

sudo chsh -s /bin/bash nova

# Wait for the controller to be ready
while ! ssh controller 'test -f ~/setup/.done'; do
    echo "Waiting for controller to be set up..."
    sleep 3
done

source ~/env/openstackrc

bash nova.sh
bash neutron.sh

sudo systemctl restart ovs-iface-up

touch .done

popd
