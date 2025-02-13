# OpenStack

## Network Architecture

- [Overview](https://docs.openstack.org/install-guide/environment-networking.html)

- [Provider network](https://docs.openstack.org/install-guide/launch-instance-networks-provider.html)

- [Self-service network](https://docs.openstack.org/install-guide/launch-instance-networks-selfservice.html)

## Errors in the Installation Guide

- The `auth_url` in the `[keystone_authtoken]` section and the `[service_user]` section should be `http://controller:500/v3/` in `nova.conf` and `neutron.conf` according to the setup for keystone. 

- A non-admin use should assume the `member` role of a project to create networks for it.

## Nova virt_type

- Qemu(except for `-cpu host`) and Gem5 don't support kvm even with kvm enabled for the simulators. So, it is required to configure `virt_type=qemu` in section `[libvirt]` of `/etc/nova/nova-compute.conf`.

## Simbricks Usage

- It seems that a host simulator sometimes get stuck, it can be possibly prevented by letting the host output periodically(?)

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