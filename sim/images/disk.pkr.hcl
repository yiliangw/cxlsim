variable "cpus" {
  type    = number
  default = 4
}

variable "memory" {
  type    = number
  default = 4096
}

variable "iso_url" {
  type    = string
}

variable "iso_cksum_url" {
  type    = string    
}

variable "disk_sz" {
  type    = number
}

variable "out_dir" {
  type    = string
}

variable "out_name" {
  type    = string
}

variable "seedimg" {
  type    = string
}

variable "input_tar" {
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
  disk_size        = "${var.disk_sz}"
  disk_image       = true
  disk_compression = false
  headless         = true
  iso_url          = "${var.iso_url}"
  iso_checksum     = "file:${var.iso_cksum_url}"
  net_device       = "virtio-net"
  qemuargs         = [
    ["-machine", "q35,accel=kvm:tcg,usb=off,vmport=off,dump-guest-core=off"],
    ["-drive", "file=${var.out_dir}/${var.out_name},if=ide,index=0,cache=writeback,discard=ignore,media=disk,format=qcow2"],
    ["-drive", "file=${var.seedimg},if=ide,index=1,media=disk,driver=raw"],
    ["-drive", "file=${var.input_tar},if=ide,index=2,media=disk,driver=raw"],
    ["-boot", "c"]
  ]
  shutdown_command = "sudo shutdown -P now"
  ssh_password     = "baize"
  ssh_username     = "baize"
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
