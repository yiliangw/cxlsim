from .env import projenv

from simbricks.orchestration.nodeconfig import NodeConfig, AppConfig
from simbricks.orchestration.simulators import Gem5Host, QemuHost
from simbricks.orchestration.experiment.experiment_environment import ExpEnv

import typing as tp
import math


class CxlSimNodeConfig(NodeConfig):

    def __init__(self):
        super().__init__()
        self.cores = 1
        self.memory = 8192
        self.vmlinux_path = None
        """Absolute path to the kernel vmlinux."""
        self.raw_disk_image_path = None
        """Absolute path to the raw disk image."""
        self.disk_image_path = None
        """Absolute path to the disk image."""
        self.initrd_path = None
        """Absolute path to the initrd image."""
        self.kernel_command_line = \
            "earlyprintk=ttyS0 console=ttyS0 " \
            "no_timer_check memory_corruption_check=0 random.trust_cpu=on " \
            "net.ifnames=0 " \
            "raid=noautodetect " \
            "root=/dev/sda1 simbricks_guest_input=/dev/sdb rw"
        self.eth_driver = 'i40e'
        """Interface drivers"""
        self.force_mac_addrs = {}
        self.force_ip_addrs = {}
        self.dhcp_ifaces = []
        self.pre_cp_tc_devs = []
        self.pre_cp_tc_rate = '10mbit'
        self.pre_cp_tc_burst = '32kb'
        self.pre_cp_tc_latency = '200ms'

    def prepare_pre_cp(self):
        cmds = super().prepare_pre_cp()
        cmds += [
            'sleep 5'  # give the system enough to initialize
        ]
        cmds += [f'modprobe {self.eth_driver}']
        if len(self.force_mac_addrs) > 0:
            cmds += [
                f'ip link set dev {dev} address {mac}' for dev, mac in self.force_mac_addrs.items()
            ]
            cmds += [
                'systemctl restart systemd-networkd',
            ]
        if len(self.force_ip_addrs) > 0:
            cmds += [
                f'ip addr add dev {dev} {cidr} brd +' for dev, cidr in self.force_ip_addrs.items()
            ]
        if len(self.dhcp_ifaces) > 0:
            cmds += [
                f'ip link set dev {iface} up' for iface in self.dhcp_ifaces
            ]
            cmds += [
                'sleep 3'
            ]
            cmds += [
                'dhclient ' + iface for iface in self.dhcp_ifaces
            ]
            cmds += [
                'sleep 3'
            ]
        if len(self.pre_cp_tc_devs) > 0:
            cmds += [
                f'tc qdisc add dev {dev} root tbf rate {self.pre_cp_tc_rate} burst {self.pre_cp_tc_burst} latency {self.pre_cp_tc_latency}'
                for dev in self.pre_cp_tc_devs
            ]
        cmds += [
            'ip link show',
            'ip addr show'
        ]
        return cmds

    def cleanup_pre_cp(self):
        cmds = []
        cmds += [f'tc qdisc del dev {dev} root' for dev in self.pre_cp_tc_devs]
        cmds += [
            "nic_pci_addrs=$(lspci -nn -D | grep -i ethernet | awk '{print $1}')",
            f"for addr in $nic_pci_addrs; do echo $addr > /sys/bus/pci/drivers/{self.eth_driver}/unbind; done"
        ]
        return cmds

    def prepare_post_cp(self):
        cmds = [
            f"for addr in $nic_pci_addrs; do echo $addr > /sys/bus/pci/drivers/{self.eth_driver}/bind; done"
        ]
        return cmds

    def config_str(self) -> str:
        if self.sim == 'gem5':
            cp_es = [] if self.nockp else ['m5 checkpoint']
            exit_es = ['m5 exit']
        else:
            cp_es = ['echo ready to checkpoint']
            exit_es = ['poweroff -f']

        es = self.prepare_pre_cp() + self.app.prepare_pre_cp() + \
            self.cleanup_pre_cp() + cp_es + \
            self.prepare_post_cp() + self.app.prepare_post_cp() + \
            self.run_cmds() + self.cleanup_cmds() + exit_es
        return '\n'.join(es)


class CxlSimAppConfig(AppConfig):

    def __init__(self):
        self.input_tar_path = None
        self.install_script_path = None

    def config_files(self) -> tp.Dict[str, tp.IO]:
        files = {}
        if self.input_tar_path is not None:
            files['input.tar'] = open(self.input_tar_path, 'rb')
        if self.install_script_path is not None:
            files['install.sh'] = open(self.install_script_path, 'rb')
        return files

    def prepare_pre_cp(self) -> tp.List[str]:
        cmds = []
        if self.input_tar_path is not None:
            cmd = 'bash /tmp/guest/install.sh'
            if self.input_tar_path is not None:
                cmd = 'INPUT_TAR=/tmp/guest/input.tar ' + cmd
            cmds.append(cmd)
        return cmds


class CxlSimGem5Host(Gem5Host):

    def __init__(self, node_config: CxlSimNodeConfig):
        super().__init__(node_config)
        self.node_config: CxlSimNodeConfig
        self.cpu_type_cp = 'X86KvmCPU'
        self.cpu_type = 'TimingSimpleCPU'
        self.sys_clock = '1GHz'
        self.variant = 'fast'
        self.gem5_py = 'simbricks_cxl.py'
        self.console_port = None

    def run_cmd(self, env: ExpEnv) -> str:
        cpu_type = self.cpu_type
        if env.create_cp:
            cpu_type = self.cpu_type_cp

        cmd = f'{env.gem5_path(self.variant)} --outdir={env.gem5_outdir(self)} '
        if self.console_port:
            cmd += '--listener-mode=on '
        cmd += ' '.join(self.extra_main_args)
        cmd += (
            f' {env.repodir}/sims/external/gem5/configs/simbricks/{self.gem5_py} '
            f'--cpu-clock={self.cpu_freq} '
            f'--sys-clock={self.sys_clock} '
            f'--checkpoint-dir={env.gem5_cpdir(self)} '
            f'--kernel={self.node_config.vmlinux_path} '
            f'--command-line "{self.node_config.kernel_command_line}" '
            f'--disk-image={self.node_config.raw_disk_image_path} '
            f'--disk-image={env.cfgtar_path(self)} '
            f'--cpu-type={cpu_type} --mem-size={self.node_config.memory}MB '
            f'--num-cpus={self.node_config.cores} '
            '--mem-type=DDR4_2400_16x4 '
        )

        if self.console_port:
            cmd += (
                f'--termport {self.console_port} '
            )

        # KvmCPU is incompatible with cache
        if cpu_type != 'X86KvmCPU':
            cmd += (
                '--caches --l2cache '
                '--l1d_size=32kB --l1i_size=32kB --l2_size=32MB '
                '--l1d_assoc=8 --l1i_assoc=8 --l2_assoc=16 '
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


class OpenstackQemuHost(QemuHost):

    def __init__(self, node_config: CxlSimNodeConfig):
        super().__init__(node_config)
        self.node_config: CxlSimNodeConfig
        self.ssh_port = None

    def prep_cmds(self, env: ExpEnv) -> tp.List[str]:
        return [
            f'{env.qemu_img_path} create -f qcow2 -F qcow2 -o '
            f'backing_file="{self.node_config.disk_image_path}" '
            f'{env.hdcopy_path(self)}'
        ]

    def run_cmd(self, env: ExpEnv) -> str:
        accel = ',accel=kvm:tcg' if not self.sync else ''
        if self.node_config.kcmd_append:
            kcmd_append = ' ' + self.node_config.kcmd_append
        else:
            kcmd_append = ''

        cmd = (
            f'{env.qemu_path} -machine q35{accel} -serial mon:stdio '
            '-cpu Skylake-Server -display none -nic none '
            f'-kernel {self.node_config.vmlinux_path} '
            f'-drive file={env.hdcopy_path(self)},if=ide,index=0,media=disk '
            f'-drive file={env.cfgtar_path(self)},if=ide,index=1,media=disk,'
            'driver=raw '
            f'-append "{self.node_config.kernel_command_line} {kcmd_append}" '
            f'-m {self.node_config.memory} -smp {self.node_config.cores} '
        )

        if self.node_config.initrd_path:
            cmd += f'-initrd {self.node_config.initrd_path} '

        if False and self.sync:
            unit = self.cpu_freq[-3:]
            if unit.lower() == 'ghz':
                base = 0
            elif unit.lower() == 'mhz':
                base = 3
            else:
                raise ValueError('cpu frequency specified in unsupported unit')
            num = float(self.cpu_freq[:-3])
            shift = base - int(math.ceil(math.log(num, 2)))

            cmd += f' -icount shift={shift},sleep=off '

        for dev in self.pcidevs:
            cmd += f'-device simbricks-pci,socket={env.dev_pci_path(dev)}'
            if self.sync:
                cmd += ',sync=on'
                cmd += f',pci-latency={self.pci_latency}'
                cmd += f',sync-period={self.sync_period}'
            else:
                cmd += ',sync=off'
            cmd += ' '

        if self.ssh_port:
            cmd += f'-netdev user,id=user-net,hostfwd=tcp::{self.ssh_port}-:22 '
            cmd += '-device e1000,netdev=user-net '

        # qemu does not currently support net direct ports
        assert len(self.net_directs) == 0
        # qemu does not currently support mem device ports
        assert len(self.memdevs) == 0
        return cmd


class IdleCheckpointApp(CxlSimAppConfig):

    CHECKPOINT_FILE = '/root/checkpoint.barrier'

    def __init__(self):
        super().__init__()
        self.ssh_control = False

    def prepare_pre_cp(self) -> tp.List[str]:
        """Commands to run to prepare this application before checkpointing."""
        cmds = super().prepare_pre_cp()
        if self.ssh_control:
            cmds += [
                'sleep infinity'
            ]
        else:
            cmds += [
                f'printf Waiting for {self.CHECKPOINT_FILE}...',
                f'while ! test -f {self.CHECKPOINT_FILE}; do sleep 30; done;',
                'sleep 3;',
            ]
        return cmds

    def run_cmds(self, node: NodeConfig) -> tp.List[str]:
        """Commands to run for this application."""
        return [
            'sleep infinity'
        ]
