import os

from simbricks.orchestration.experiments import Experiment
from simbricks.orchestration.simulators import I40eNIC, E1000NIC, SwitchNet
from simbricks.orchestration.nodeconfig import AppConfig

from lib.sim import CxlSimGem5Host, CxlSimNodeConfig, CxlSimAppConfig, IdleCheckpointApp
from lib.env import projenv
from lib.utils import config_experiment_sync, config_experiment_checkpoint

import typing as tp
from easydict import EasyDict as edict
import yaml

exp_name = os.path.basename(__file__).replace('.py', '')
config_file = os.path.join(os.path.dirname(__file__), f'{exp_name}.yaml')
disk_prefix = 'mysql/basic'

with open(config_file, 'r') as f:
    CONFIG = edict(yaml.full_load(f))

instances_ips = {
    'server': '10.10.11.111',
    'client': '10.10.11.112'
}


class ControllerApp(CxlSimAppConfig):

    def __init__(self):
        super().__init__()
        self.compute_nodes = ['compute1', 'compute2']

    def prepare_pre_cp(self) -> tp.List[str]:
        """Commands to run to prepare this application before checkpointing."""
        ckp_file = self.CHECKPOINT_BARRIER_FILE
        cmds: list = super().prepare_pre_cp()
        cmds += ['source /root/env/user_openrc']
        cmds += [
            f'while ! openstack compute service list | grep {n} | grep -q enabled.*up; do sleep 5; ping {n} -c 1; done'
            for n in self.compute_nodes
        ]
        cmds += [
            f'openstack server start {' '.join(instances_ips.keys())}',
            'sleep 60',
        ]
        cmds += [
            f'while ! ssh {ip} true; do '
            f'openstack server show {n} -c status; '
            f'(openstack console log show {n} | tail); '
            'sleep 10; done'
            for n, ip in instances_ips.items()
        ]
        # A trail
        cmds += [
            f'while ! ssh {instances_ips['client']} "bash /root/verify.sh"; '
            'do sleep 5; done'
        ]
        # Notify checkpointing
        cmds += [
            f'ssh {n} "touch {ckp_file}"'
            for n in self.compute_nodes
        ]

        return cmds

    def run_cmds(self, node) -> tp.List[str]:
        """Commands to run for this application."""
        return ['m5 exit']


class Compute1App(IdleCheckpointApp):
    pass


class Compute2App(IdleCheckpointApp):

    def run_cmds(self, node) -> tp.List[str]:
        """Commands to run for this application."""
        cmds = []
        cmds += ['sleep 1']
        cmds += [
            f'while ! (echo trying... && ssh -vvv {instances_ips['client']} "bash /root/bench.sh"); do sleep 1; done',
        ]
        cmds += [
            'ssh compute1 "m5 exit"',
        ]

        return cmds


e = Experiment(name=exp_name)

# Create the management network
management_net = SwitchNet()
management_net.name = 'management'
e.add_network(management_net)

# Create the provider network
provider_net = SwitchNet()
provider_net.name = 'provider'
e.add_network(provider_net)

if CONFIG.nic == 'i40e':
    NIC_SIM = I40eNIC
elif CONFIG.nic == 'e1000':
    NIC_SIM = E1000NIC
else:
    raise ValueError(f"Unknown NIC: {CONFIG.nic}")


def create_openstack_node(node: str, app: CxlSimAppConfig):

    config = CxlSimNodeConfig()
    config.disable_guestinit = CONFIG.interactive
    config.vmlinux_path = projenv.ubuntu_vmlinux_path
    config.initrd_path = projenv.ubuntu_initrd_path
    config.raw_disk_image_path = projenv.get_ubuntu_raw_disk(
        f'{disk_prefix}/{node}')
    config.cores = getattr(CONFIG.hosts, node).cores
    config.memory = getattr(CONFIG.hosts, node).memory
    config.eth_driver = CONFIG.nic
    config.app = app

    host = CxlSimGem5Host(config)
    host.name = f'{node}'
    host.cpu_type = CONFIG.cpu_type
    host.cpu_freq = CONFIG.cpu_freq
    host.wait = True
    if CONFIG.console:
        host.console_port = getattr(CONFIG.hosts, node).console_port
    e.add_host(host)

    management_nic = NIC_SIM()
    management_nic.name = 'management'
    management_nic.mac = getattr(CONFIG.hosts, node).management_mac
    e.add_nic(management_nic)
    host.add_nic(management_nic)
    management_nic.set_network(management_net)

    provider_nic = NIC_SIM()
    provider_nic.name = 'provider'
    provider_nic.mac = getattr(CONFIG.hosts, node).provider_mac
    e.add_nic(provider_nic)
    host.add_nic(provider_nic)
    provider_nic.set_network(provider_net)

    return host, management_nic, provider_nic


create_openstack_node('controller', ControllerApp())
create_openstack_node('compute1', Compute1App())
create_openstack_node('compute2', Compute2App())

config_experiment_sync(
    e, sync=CONFIG.sync,
    pci_latency=CONFIG.pci_latency,
    eth_latency=CONFIG.eth_latency
)
config_experiment_checkpoint(e, CONFIG.cp)

experiments = [e]
