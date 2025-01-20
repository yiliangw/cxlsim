#cloud-config
ssh_pwauth: True
users:
  - name: {{ .openstack.system.user }}
    plain_text_passwd: {{ .openstack.system.password }}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
