import os
import yaml
from easydict import EasyDict as edict


class ProjEnv(object):

  def __init__(self):

    self.repo_path = os.path.abspath(os.path.join(
        os.path.dirname(__file__), '../../..'))
    self.make_outdir = os.path.join(self.repo_path, 'out')
    self.images_dir = os.path.join(self.make_outdir, 'images')
    self.config_yaml_path = os.path.join(self.make_outdir, 'config/config.yaml')

    self.ubuntu_vmlinux_path = os.path.join(self.images_dir, 'ubuntu/vmlinux')
    self.ubuntu_initrd_path = os.path.join(self.images_dir, 'ubuntu/initrd.img')

    with open(self.config_yaml_path) as f:
      self.config = edict(yaml.safe_load(f))
      
  def get_ubuntu_raw_disk(self, disk_name):
    return os.path.join(self.images_dir, f'ubuntu/disks/{disk_name}/disk.raw')

  def get_ubuntu_disk(self, disk_name):
    return os.path.join(self.images_dir, f'ubuntu/disks/{disk_name}/disk.qcow2')

projenv = ProjEnv()
