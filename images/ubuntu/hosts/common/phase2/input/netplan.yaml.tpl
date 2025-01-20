network:
  version: 2
  renderer: networkd
  ethernets:
    {{ .local.network.management.interface }}:
      dhcp4: false
      addresses:
        - {{ .local.network.management.ip }}/{{ .openstack.network.management.mask_len }}
      nameservers:
        addresses:
          - {{ .openstack.network.management.nameserver }}
      routes:
        - to: default
          via: {{ .openstack.network.management.gateway }}