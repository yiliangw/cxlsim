#!/bin/bash

set -eux

# These groups will only take effect from the next login
sudo usermod -aG sudo $USER
sudo usermod -aG disk $USER
sudo usermod -aG kvm $USER

# # OpenStack 2024.1 (Caracal)
# sudo add-apt-repository -y cloud-archive:caracal

sudo apt-get update

export DEBIAN_FRONTEND=noninteractive

# Packages required for building the kernel
sudo -E apt-get install -y \
  build-essential \
  libncurses-dev \
  bison \
  flex \
  libssl-dev \
  libelf-dev \
  bc \
  dwarves \
  qemu-guest-agent \
  rsh-redone-server rsh-redone-client

mkdir /tmp/input
pushd /tmp/input

sudo tar xf /dev/sdb
sudo chown -R $(id -u):$(id -g) .

# Allow rsh connection to root
sudo install -m 600 /dev/null /root/.rhosts
cat <<EOF | sudo tee /root/.rhosts
+ +
EOF

sudo cp simbricks-guestinit.sh /usr/local/sbin/simbricks-guestinit.sh
sudo chmod +x /usr/local/sbin/simbricks-guestinit.sh
sudo cp simbricks-guestinit.service /etc/systemd/system/
sudo systemctl enable simbricks-guestinit

sudo cp m5 /sbin/m5
sudo chmod +x /sbin/m5

mkdir -p ~/.ssh/controlmasters/
cp ssh/* ~/.ssh
chmod 600 ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

cp -r linux/ ~/linux
cd ~/linux
cp /boot/config-$(uname -r) .config
./scripts/config --set-str SYSTEM_TRUSTED_KEYS ""
./scripts/config --disable MODULE_SIG_CERT
./scripts/config --disable SYSTEM_REVOCATION_KEYS

./scripts/config \
  --disable CONFIG_WIRELESS   \
  --disable CONFIG_WLAN       \
  --disable CONFIG_CFG80211   \
  --disable CONFIG_MAC80211   \
  --disable CONFIG_IWLWIFI    \
  --disable CONFIG_BT         \
  --disable CONFIG_IEEE802154

./scripts/config \
  --disable CONFIG_NET_VENDOR_MELLANOX \
  --disable CONFIG_MELLANOX_PLATFORM


# find all WLAN_VENDOR_* and disable them
for i in $(grep '^CONFIG_.*WLAN_VENDOR.*=y' .config | awk -F= '{print $1}'); do
    ./scripts/config --disable $i
done

./scripts/config --disable CONFIG_INFINIBAND

./scripts/config \
  --disable CONFIG_COMEDI \
  --disable CONFIG_IIO \
  --disable CONFIG_I2C \
  --disable CONFIG_SPI \
  --disable CONFIG_GPIO \
  --disable CONFIG_HID \
  --disable CONFIG_MEDIA_SUPPORT \
  --disable CONFIG_SOUND \
  --disable CONFIG_INPUT_MOUSE \
  --disable CONFIG_INPUT_JOYSTICK \
  --disable CONFIG_INPUT_TABLET \
  --disable CONFIG_INPUT_TOUCHSCREEN \
  --disable CONFIG_INPUT_MISC \
  --disable CONFIG_HID_SUPPORT \
  --disable CONFIG_HID

./scripts/config \
  --disable CONFIG_DRM \
  --disable CONFIG_DRM_AMDGPU \
  --disable CONFIG_DRM_VIRTIO_GPU \
  --disable CONFIG_FB

./scripts/config --refresh
# yes "" | make oldconfig

make -j$(nproc)
sudo make modules_install
sudo make install

GRUB_CFG_FILE=/etc/default/grub.d/50-cloudimg-settings.cfg
echo 'GRUB_DISABLE_OS_PROBER=true' >> $GRUB_CFG_FILE
echo 'GRUB_HIDDEN_TIMEOUT=0' >> $GRUB_CFG_FILE
echo 'GRUB_TIMEOUT=0' >> $GRUB_CFG_FILE
update-grub

sudo mkdir /root/output
sudo cp .config /root/output/config
sudo cp vmlinux /root/output/vmlinux
sudo cp arch/x86/boot/bzImage /root/output/bzImage
sudo cp /boot/initrd.img /root/output/initrd.img

popd
rm -rf /tmp/input
