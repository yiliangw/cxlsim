#cloud-config
ssh_pwauth: True
users:
  - name: {{ .platform.ubuntu.user.name }}
    plain_text_passwd: {{ .platform.ubuntu.user.password }}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
