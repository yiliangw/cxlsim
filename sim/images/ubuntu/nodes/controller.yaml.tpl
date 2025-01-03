local:
  hostname: controller
  network:
    management:
      ip: {{ .network.management.nodes.controller.ip }}
    provider:
      ip: {{ .network.provider.nodes.controller.ip }}
  