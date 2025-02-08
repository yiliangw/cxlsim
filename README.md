Baize
-----

Quick Start
===========

Most of the project's dependencies are managed with Docker.
After building the images, you can access the environment either by working with Visual Studio Code's dev container or by starting the container with an interactive shell.

Prerequisites:

- `git`, `make` and `docker` (with docker compose plugin) have been installed on the system.

- sudo is enabled for the current user.

Steps:

1. Initialize submodules:
    ```bash
    git submodules update --init --recursive --depth 1
    ```

2. Add the current user to `docker` and `kvm` groups:
    ```bash
    sudo usermod -aG docker $USER
    sudo usermod -aG kvm $USER
    ```

3. Configure the image's user information in `.devcontainer/rules.mk`. By default, the created user will have the same user ID and group ID as the current user on the host. This avoids any conflicts in the file system. 

4. Build the image for the dev container:
    ```bash
    make devcontainer
    ```

5. Access the environment with either of the two options:
    - Reopen the project in the dev container with Visual Studio Code.
    - Run the container and start an interacting shell by running `make run-devcontainer`. 

6. Build Simbricks in the container:
    ```bash
    make simbricks-build
    ```

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

Disable and delete a component's service (compute)
--------------------------------------------------

List the compute services
```bash
openstack compute service list
```

Disable the service
```bash
openstack compute service set --disable <host> <binary>(nova-compute)
```

Delete the serivce
```bash
openstack compute service delete <service-id>/<binary>(nova-compute)
```
