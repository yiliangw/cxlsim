# OpenStack

## Network Architecture

- [Overview](https://docs.openstack.org/install-guide/environment-networking.html)

- [Provider network](https://docs.openstack.org/install-guide/launch-instance-networks-provider.html)

- [Self-service network](https://docs.openstack.org/install-guide/launch-instance-networks-selfservice.html)

## Errors in the Installation Guide

- The `auth_url` in the `[keystone_authtoken]` section and the `[service_user]` section should be `http://controller:500/v3/` in `nova.conf` and `neutron.conf` according to the setup for keystone. 

- A non-admin use should assume the `member` role of a project to create networks for it.