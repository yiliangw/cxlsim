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

source "qemu" "disk" {
  output_directory = "${var.out_dir}"
  communicator     = "ssh"
  cpus             = "${var.cpus}"
  memory           = "${var.memory}"
  format           = "qcow2"
  disk_image       = true
  disk_compression = false
  # It seems that `skip_resize_disk` doesn't work. We get around by explicitly setting the original base image size
  disk_size        = "${var.disk_size}"
  headless         = true
  iso_url          = "${var.base_img}"
  iso_checksum     = "none"
  net_device       = "virtio-net"
  qemuargs         = [
    ["-machine", "q35,accel=kvm:tcg"],
    ["-cpu", "host"],
    ["-drive", "file=${var.out_dir}/${var.out_name},if=ide,index=0,media=disk,format=qcow2"],
    ["-drive", "file=${var.input_tar_src},if=ide,index=1,media=disk,format=raw"],
    ["-boot", "c"],
  ]
  shutdown_command = "sudo shutdown -P now"
  ssh_password     = "baize"
  ssh_username     = "baize"
  ssh_timeout      = "3m"
  use_backing_file = "true"
  vm_name          = "${var.out_name}"
}

build {
  sources = ["source.qemu.disk"]

  provisioner "shell" {
    execute_command = "{{ .Vars }} bash '{{ .Path }}'"
    scripts         = ["${var.install_script}"]
  }
}
