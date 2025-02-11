#cloud-config
ssh_pwauth: True
users:
  - name: {{ .openstack.instances.user.name }}
    plain_text_passwd: {{ .openstack.instances.user.password }}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
# runcmd:
#   - systemctl mask systemd-networkd-wait-online # Do not wait for the network during boot
#   - systemctl set-default multi-user.target # Disable graphical interface
