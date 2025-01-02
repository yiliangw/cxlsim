local:
  hostname: compute1
  network:
    management:
      ip: {{ .network.management.nodes.compute1.ip }}
    service:
      ip: {{ .network.service.nodes.compute1.ip }}