Run QEMU VMs with virtual LAN
--------------------------------

1. Update `INTERNET_IF`, `BRIDGE_IF`, `BRIDGE_IF_IP` and `BRIDGE_IF_SUBNET_MASK_LEN` in `config/config.mk`.

2. Setup the bridge:
```bash
make setup-bridge
```

3. Grant permissions of the bridge to the QEMU bridge helper:
```bash
sudo mkdir -p /etc/qemu
sudo echo "allow ${BRIDGE_IF} >> /etc/qemu/bridge.conf"
```

4. Run QEMU VMs
```bash
make qemu-ubuntu-vm0
make qemu-ubuntu-vm1
```

5. Configure the network according to `BRIDGE_IF_IP` and `BRIDGE_IF_MASK_LEN` inside the VMs. For example:
```bash
# Assign a static IP
sudo ip addr add <BRIDGE_IF_IP>/<BRIDGE_IF_MASK_LEN> brd + dev <dev>
# Set the bridge as the gateway
sudo ip route add default via <BRIDGE_IF_IP> dev <dev>
```

Mount virtfs inside VMs
-----------------------

```bash
source admin-openrc
sudo mount -t 9p -o trans=virtio <tag> <mnt>
```