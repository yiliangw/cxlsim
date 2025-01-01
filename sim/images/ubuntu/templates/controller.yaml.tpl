local:
  hostname: controller
  network:
    management:
      ip: {{ .network.management.nodes.controller.ip }}
    service:
      ip: {{ .network.service.nodes.controller.ip }}
  