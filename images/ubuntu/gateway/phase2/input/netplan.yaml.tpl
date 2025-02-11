network:
  version: 2
  renderer: networkd
  ethernets:
    {{ .local.network.management.interface }}:
      addresses:
        - {{ .local.network.management.ip }}/{{ .openstack.network.management.mask_len }}
    {{ .local.network.provider.interface }}:
      addresses:
        - {{ .local.network.provider.ip }}/{{ .openstack.network.provider.mask_len }}