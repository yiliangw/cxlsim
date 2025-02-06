from simbricks.orchestration.nodeconfig import NodeConfig, AppConfig
from simbricks.orchestration.simulators import Gem5Host
from simbricks.orchestration.experiment.experiment_environment import ExpEnv

import typing as tp


class OpenstackNodeConfig(NodeConfig):

  def __init__(self):
    super().__init__()
    self.nic_driver = 'i40e'
    self.vmlinux_path = None
    """Absolute path to the kernel vmlinux."""
    self.raw_disk_image_path = None
    # """Absolute path to the raw disk iamge."""
    # self.initrd_path = None
    """Absolute path to the initrd image."""
    self.kernel_command_line = \
        "earlyprintk=ttyS0 console=ttyS0 " \
        "net.ifnames=0 " \
        "root=/dev/sda1 simbricks_guest_input=/dev/sdb rw "

  def prepare_pre_cp(self) -> tp.List[str]:
    return super().prepare_pre_cp() + [
        f'modprobe {self.nic_driver}',
    ]

class OpenstackGem5Host(Gem5Host):

  def __init__(self, node_config: OpenstackNodeConfig):
    super().__init__(node_config)

  def run_cmd(self, env: ExpEnv) -> str:
    cpu_type = self.cpu_type
    if env.create_cp:
      cpu_type = self.cpu_type_cp

    cmd = f'{env.gem5_path(self.variant)} --outdir={env.gem5_outdir(self)} '
    cmd += ' '.join(self.extra_main_args)
    cmd += (
        f' {env.gem5_py_path} --caches --l2cache '
        '--l1d_size=32kB --l1i_size=32kB --l2_size=32MB '
        '--l1d_assoc=8 --l1i_assoc=8 --l2_assoc=16 '
        f'--cacheline_size=64 --cpu-clock={self.cpu_freq}'
        f' --sys-clock={self.sys_clock} '
        f'--checkpoint-dir={env.gem5_cpdir(self)} '
        f'--kernel={self.node_config.vmlinux_path} '
        f'--command-line "{self.node_config.kernel_command_line}" '
        f'--disk-image={self.node_config.raw_disk_image_path} '
        f'--disk-image={env.cfgtar_path(self)} '
        f'--cpu-type={cpu_type} --mem-size={self.node_config.memory}MB '
        f'--num-cpus={self.node_config.cores} '
        '--mem-type=DDR4_2400_16x4 '
    )

    if self.node_config.kcmd_append:
      cmd += f'--command-line-append="{self.node_config.kcmd_append}" '

    if env.create_cp:
      cmd += '--max-checkpoints=1 '

    if env.restore_cp:
      cmd += '-r 1 '

    for dev in self.pcidevs:
      cmd += (
          f'--simbricks-pci=connect:{env.dev_pci_path(dev)}'
          f':latency={self.pci_latency}ns'
          f':sync_interval={self.sync_period}ns'
      )
      if cpu_type == 'TimingSimpleCPU':
        cmd += ':sync'
      cmd += ' '

    for dev in self.memdevs:
      cmd += (
          f'--simbricks-mem={dev.size}@{dev.addr}@{dev.as_id}@'
          f'connect:{env.dev_mem_path(dev)}'
          f':latency={self.mem_latency}ns'
          f':sync_interval={self.sync_period}ns'
      )
      if cpu_type == 'TimingSimpleCPU':
        cmd += ':sync'
      cmd += ' '

    for net in self.net_directs:
      cmd += (
          '--simbricks-eth-e1000=listen'
          f':{env.net2host_eth_path(net, self)}'
          f':{env.net2host_shm_path(net, self)}'
          f':latency={net.eth_latency}ns'
          f':sync_interval={net.sync_period}ns'
      )
      if cpu_type == 'TimingSimpleCPU':
        cmd += ':sync'
      cmd += ' '

    cmd += ' '.join(self.extra_config_args)
    return cmd
