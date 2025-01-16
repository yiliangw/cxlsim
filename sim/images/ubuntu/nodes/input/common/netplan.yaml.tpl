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
          - {{ .network.management.nameserver }}
      routes:
        - to: default
          via: {{ .network.management.ip }}