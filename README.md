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
    make simbricks-build
    ```

7. Run the example experiment:
    ```bash
    make run-ubuntu-mysql
    ```
    This experiment builds up an OpenStack system with a controller, a compute node and a gateway.
    After setting up, a MySQL server and a client will be launched as instances on the provider network and run some simple workload. 


## Launching Instances

1. Mount the 9p shared folder in controller node:
    ```sh
    mkdir -p /mnt/instances
    mount -t 9p -o trans=virtio instances /mnt/instances
    ```

2. Initialize the credentials
    ```sh
    . env/admin_openrc
    ```

3. Create the provider network:
    ```sh
    openstack network create --share --external \
        --provider-physical-network provider \
        --provider-network-type flat provier
    openstack subnet create --network provider \
    --allocation-pool start=10.10.11.100,end=10.10.11.250 \
    --dns-nameserver 8.8.8.8 --gateway 10.10.11.1 \
    --subnet-range 10.10.11.0/24 provider
    ```

4. Assign fixed IP address
    ```sh
    openstack port create --project myproject --network provider \
        --fixed-ip ip-address=10.10.11.112 myport
    ```
    

5. List avaialbe resources:
    ```sh
    openstack flavor list
    openstack image list
    openstack network list
    openstack security group list
    ```

6. Create a flavor:
    ```sh
    # ram: MB   disk: GB
    openstack flavor create --vcpus 1 --ram 64 --disk 1 m1.nano
   
    openstack flavor create --vcpus 2 --ram 4096 --disk 4 server
    openstack flavor create --vcpus 1 --ram 4096 --disk 4 client
    ```

7. Add an image:
    ```sh
    glance image-create --name "cirros" \
    --file /mnt/instances/disks/cirros/disk.qcow2 \
    --disk-format qcow2 --container-format bare \
    --visibility=public
    glance image-list
    ```
    
8. Add a public key:
    ```sh
    openstack keypair create --public-key ~/.ssh/id_rsa.pub mykey 
    # Verify
    openstack keypair list
    ```

9. Add a security group:
    ```sh
    openstack security group create mygroup
    openstack security group rule create mygroup --proto any --ingress
    # openstack security group rule create --proto tcp --dst-port default
    # openstack security group rule create --proto icmp default
    ```

10. Launch a cirros instance (on a provider network `provider`):
    ```sh
    openstack server create --flavor m1.nano --image cirros \
    --port myport --security-group mygroup \
    --key-name mykey \
    --user-data /mnt/instances/user-data \
    --hint force_hosts=compute1 \
    cirros
    ```

11. Shut down an instance gracefully and relaunch
    ```sh
    openstack server stop cirros
    openstack server stop --wait cirros # Force stop
    openstack server start cirros
    
    openstack server reboot --soft cirros
    ```

12. Check the console output of an instance:
    ```sh
    openstack console log show cirros
    ```

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