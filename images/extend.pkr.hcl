variable "cpus" {
  type    = number
  default = 4
}

variable "memory" {
  type    = number
  default = 4096
}

variable "base_img" {
  type    = string
}

variable "disk_size" {
  type    = string
}

variable "disk_compression" {
  type    = bool
  default = false
}

variable "format" {
  type    = string
  default = "qcow2"
}

variable "out_dir" {
  type    = string
}

variable "out_name" {
  type    = string
}

variable "input_tar_src" {
  type    = string
}

variable "install_script" {
  type    = string
}

variable "use_backing_file" {
  type    = bool
  default = true
}

variable "user_name" {
  type    = string
}

variable "user_password" {
  type    = string
}

variable "qemu_binary" {
  type    = string
  default = "/usr/bin/qemu-system-aarch64"
}

source "qemu" "disk" {
  output_directory = "${var.out_dir}"
  communicator     = "ssh"
  cpus             = "${var.cpus}"
  memory           = "${var.memory}"
  format           = "${var.format}"
  disk_image       = true
  disk_compression = "${var.disk_compression}"
  # It seems that `skip_resize_disk` doesn't work. We get around by explicitly setting the original base image size
  disk_size        = "${var.disk_size}"
  headless         = true
  iso_url          = "${var.base_img}"
  iso_checksum     = "none"
  use_backing_file = "${var.use_backing_file}"
  net_device       = "virtio-net"
  qemu_binary      = "${var.qemu_binary}"
  qemuargs         = [
    ["-machine", "virt,accel=kvm:tcg"],
    ["-enable-kvm"],
    ["-cpu", "host"],
    ["-drive", "file=/usr/share/AAVMF/AAVMF_CODE.fd,format=raw,if=pflash,readonly=on"],
    ["-drive", "file=/usr/share/AAVMF/AAVMF_VARS.fd,format=raw,if=pflash,readonly=on"],
    ["-drive", "file=${var.out_dir}/${var.out_name},format=qcow2,if=none,id=hd0,cache=writeback,discard=ignore,media=disk"],
    ["-drive", "file=${var.input_tar_src},format=raw,if=none,id=hd1,media=disk"],
    ["-device", "virtio-scsi-device,id=scsi0"],
    ["-device", "scsi-hd,drive=hd0,bus=scsi0.0"],
    ["-device", "scsi-hd,drive=hd1,bus=scsi0.0"],
    ["-boot", "c"],
  ]
  shutdown_command = "sudo shutdown -P now"
  ssh_username     = "${var.user_name}"
  ssh_password     = "${var.user_password}"
  ssh_timeout      = "3m"
  vm_name          = "${var.out_name}"
}

build {
  sources = ["source.qemu.disk"]

  provisioner "shell" {
    execute_command = "{{ .Vars }} bash '{{ .Path }}'"
    scripts         = ["${var.install_script}"]
  }
}
