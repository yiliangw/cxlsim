network:
  version: 2
  renderer: networkd
  ethernets:
    {{ .local.network.management.interface }}:
      dhcp4: false
      addresses:
        - {{ .local.network.management.ip }}/{{ .network.management.mask_len }}
      nameservers:
        addresses:
          - 8.8.8.8
      routes:
        - to: default
          via: {{ .network.management.ip }}
    {{ .local.network.provider.interface }}:
      dhcp4: false
      addresses:
        - {{ .local.network.provider.ip }}/{{ .network.provider.mask_len }}
