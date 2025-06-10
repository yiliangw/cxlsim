#!/bin/bash
set -xe

pushd `dirname ${BASH_SOURCE[0]}`

if [ -f .done ]; then
    echo "Already set up"
    exit 1
fi

sudo tee /etc/chrony/chrony.conf < chrony.conf > /dev/null
sudo systemctl restart chrony

# Bring up ovs interfaces
sudo cp sbin/setup-ovs-iface.sh /usr/local/sbin
sudo chmod +x /usr/local/sbin/setup-ovs-iface.sh
sudo cp services/ovs-iface-up.service /etc/systemd/system
sudo systemctl enable --now ovs-iface-up

# Disable PAM for SSH to speed up
sudo sed -i 's/^#\?UsePAM.*/UsePAM no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

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

# For migration
sudo chsh -s /bin/bash nova
# When UsePAM is disabled for SSH, the server will refuse public key authentication
# for a disabled user (e.g., without a password set).
echo nova:nova | sudo chpasswd

# Wait for the controller to be ready
while ! ssh controller 'test -f ~/setup/.done'; do
    echo "Waiting for controller to be set up..."
    sleep 3
done

source ~/env/openstackrc

bash nova.sh
bash neutron.sh

# Set up provider veth interfaces
sudo cp sbin/setup-provider-veth.sh /usr/local/sbin
sudo chmod +x /usr/local/sbin/setup-provider-veth.sh
sudo cp services/provider-veth-up.service /etc/systemd/system
sudo systemctl enable --now provider-veth-up

sudo systemctl restart ovs-iface-up

touch .done

popd
