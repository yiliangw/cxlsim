#cloud-config
ssh_pwauth: True
users:
  - name: {{ .id.system.user }}
    plain_text_passwd: {{ .id.system.pass }}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
