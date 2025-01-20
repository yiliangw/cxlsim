local:
  hostname: compute1
  network:
    management:
      ip: {{ .openstack.network.management.hosts.compute1.ip }}