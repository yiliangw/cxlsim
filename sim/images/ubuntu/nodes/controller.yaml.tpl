local:
  hostname: controller
  network:
    management:
      ip: {{ .network.management.nodes.controller.ip }} 