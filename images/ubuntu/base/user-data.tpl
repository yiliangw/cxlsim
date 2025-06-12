#cloud-config
ssh_pwauth: true
disable_root: false 
users:
  - name: root
    lock_passwd: false
    plain_text_passwd: {{ .platform.ubuntu.root.password }}
  - name: {{ .platform.ubuntu.user.name }}
    plain_text_passwd: {{ .platform.ubuntu.user.password }}
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    lock_passwd: false
bootcmd:
  # - systemctl mask systemd-networkd-wait-online || true # Do not wait for the network during boot
  # - systemctl mask NetworkManager-wait-online.service || true
  - systemctl set-default multi-user.target # Disable graphical interface
runcmd:
  - sed -i 's/^#\?UsePAM.*/UsePAM no/' /etc/ssh/sshd_config # Disable PAM for SSH to speed up
  - sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config  # Allow root login with key or password
  - sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config  # Enable password auth
  - systemctl restart ssh  # Restart SSH to apply the changes
  # Disable cloud-init
  - touch /etc/cloud/cloud-init.disabled
