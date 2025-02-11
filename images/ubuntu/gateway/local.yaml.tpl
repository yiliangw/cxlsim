local:
  network:
    management:
      interface: eth0
      ip: {{ .openstack.network.management.gateway }}
    provider:
      interface: eth1
      ip: {{ .openstack.network.provider.gateway }}