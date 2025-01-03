local:
  hostname: compute1
  network:
    management:
      ip: {{ .network.management.nodes.compute1.ip }}
    provider:
      ip: {{ .network.provider.nodes.compute1.ip }}