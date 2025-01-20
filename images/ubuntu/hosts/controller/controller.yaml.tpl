local:
  hostname: controller
  network:
    management:
      ip: {{ .openstack.network.management.hosts.controller.ip }}