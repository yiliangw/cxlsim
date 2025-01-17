#cloud-config
ssh_pwauth: True
users:
  - name: {{ .instances.user.name }}
    plain_text_passwd: {{ .instances.user.password }}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
