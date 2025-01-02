network:
  version: 2
  renderer: networkd
  ethernets:
    enp0s2:
      dhcp4: false
      addresses:
        - {{ .local.network.management.ip }}/{{ .network.management.mask_len }}
      nameservers:
        addresses:
          - 8.8.8.8
      routes:
        - to: default
          via: {{ .network.management.ip }}
    enp0s3:
      dhcp4: false
      addresses:
        - {{ .local.network.service.ip }}/{{ .network.service.mask_len }}
