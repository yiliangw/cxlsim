Baize
-----

Quick Start
===========

Most of the project's dependencies are managed with Docker.
After building the images, you can access the environment either by working with Visual Studio Code's dev container or by starting the container with an interactive shell.

Prerequisites:

- x86 linux machine with at least 32 CPU cores, 32G memory and 350G free disk space.

- KVM is available.

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

4. Build the docker image for the dev container:
    ```bash
    make devcontainer
    ```

5. Access the environment with either of the two options:
    - Reopen the project in the dev container with Visual Studio Code.
    - Run the container and start an interacting shell by running `make run-devcontainer`. 

The following steps should be executed inside the container.

6. Build SimBricks:
    ```bash
    make build-simbricks
    ```

7. Set up bridges and NAT:
    ```bash
    make setup-bridges
    make setup-nat
    ```

8. Build OpenStack base images:
    ```bash
    make ubuntu-setup
    ```

9. Set up OpenStack base images:

    For `<node>` in `controller`, `compute1`, and `compute2`, do the following things:

    - Launch the node by running `make qemu-ubuntu-setup/<node>`.

    - Login into the node with user `root` and password `root`.

    - Setup the node by running `bash /dev/sdc && bash ~/setup/run.sh`. Other node can be set up only after 'controller` has been set up.

    - Shutdown the nodes after all nodes have been set up.

10. Set up MySQL workload base images:

    - For `<node>` in `controller`, `compute1`, and `compute2`, launch the node by running `make qemu-ubuntu-mysql/base/<node>`.

    - Login into `controller` and setup up the workload by running:
    ```bash
    mount -t 9p workload /mnt
    bash /mnt/mysql/setup.sh
    ```

    - Shutdown the nodes after the setup is done.

11. Run the MySQL workload experiment:
    
    ```bash
    make run-exp-ubuntu_basic
    ```
    

    This experiment builds up an OpenStack system with a controller node and two compute nodes.



13. Migrate a VM to another compute node:
    ```sh
    openstack server migrate --os-compute-api-version 2.30 --live-migration --host compute2 --wait server
    openstack server confirm-migration <INSTANCE_ID>
    ```

    According to the [thread](https://bugs.launchpad.net/nova/+bug/2051907), neutron policy for create_port_binding requires the role `service`.
    A quick workaround is to do `openstack role add --user neutron --project service service`.

    It seems that if one compute node uses kvm while another uses qemu, then an instance can only be live migrated from kvm to qemu.
    However, a cold migration would work for both directions.
    Also, a cold migration should be confirmed with `openstack server migration confirm <server_name>`.
    

## Configuring Identities

```sh
# Create a domain
openstack domain create mydomain

# Create a project
openstack project create --domain mydomain myproject

# Create a user
openstack user create --domain default --password pass myuser

# Creat a role
openstack role create myrole

# Add a role to a project and user
openstack role add --project myproject --user myuser myrole

# Add a user as admin of a project
openstack role add --project myproject --user myuser admin

# List the role of a user in a project
openstack role assignment list --user myuser --project myproject --names
```

## Configuraing Swap Space

```sh
# Create and enable the swap file
sudo fallocate -l 16G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Disable the swap file
sudo swapoff /swapfile
sudo rm /swapfile

# Verify
swapon --show
free -h

# Enable kernel memory overcommit
echo 1 | sudo tee /proc/sys/vm/overcommit_memory
echo 150 | sudo tee /proc/sys/vm/overcommit_ratio

# Make the configuration persistent
sudo bash -c 'cat <<EOF >> /etc/fstab
/swapfile   none    swap    sw  0   0
EOF'
# Verify
sudo findmnt --verify
sudo swapon -a || sudo mount -a


sudo bash -c 'cat <<EOF >> /etc/sysctl.conf
vm.overcommit_memory = 1
vm.overcommit_ratio = 150
EOF'
sudo sysctl -p
```
