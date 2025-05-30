local:
  hostname: compute2
  network:
    management:
      ip: {{ .openstack.network.management.hosts.compute2.ip }}