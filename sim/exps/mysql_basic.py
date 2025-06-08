import os

from simbricks.orchestration.experiments import Experiment
from simbricks.orchestration.simulators import I40eNIC, E1000NIC, SwitchNet

from lib.sim import OpenstackGem5Host, IdleCheckpointApp
from lib.ubuntu import UbuntuNodeConfig, UbuntuAppConfig
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

class ControllerApp(UbuntuAppConfig):

    def __init__(self):
        super().__init__()
        self.server_ip = '10.10.11.111'
        self.client_ip = '10.10.11.112'

    def prepare_pre_cp(self) -> tp.List[str]:
        """Commands to run to prepare this application before checkpointing."""
        cmds = super().prepare_pre_cp()
        if CONFIG.ssh_control:
            cmds += [
                'sleep infinity'
            ]
        else:
            ckp_file = IdleCheckpointApp.CHECKPOINT_FILE
            veth = 'veth-provider'
            veth_cidr = '10.10.11.11/24'
            cmds += [
                # Set up a veth pair to access the provider network
                f'ip link add {veth} type veth peer name {veth}br',
                f'ovs-vsctl add-port provider-br {veth}br',
                f'ip addr add {veth_cidr} dev {veth}',
                f'ip link set {veth} up',
                f'ip link set {veth}br up',
                'source /root/env/user_openrc',
                # Wait for compute nodes
                'while ! openstack compute service list | grep compute1 | grep -q enabled.*up; '
                'do sleep 5; done',
                'while ! openstack compute service list | grep compute2 | grep -q enabled.*up; '
                'do sleep 5; done',
                # Start the instances
                'openstack server start server client',
                'sleep 60', 
                f'while ! ssh {self.server_ip} true; do ' \
                'openstack server show server -c status; (openstack console log show server | tail); sleep 10; done',
                f'while ! ssh {self.client_ip} true; do '\
                'openstack server show client -c status; (openstack console log show client | tail); sleep 10; done',
                # Do a warmup run
                f'while ! ssh {self.client_ip} "bash /root/bench.sh"; do sleep 5; done', 
                # Notify checkpointing
                f'ssh compute1 "touch {ckp_file}"',
                f'ssh compute2 "touch {ckp_file}"',
            ]
        return cmds

    def run_cmds(self, node) -> tp.List[str]:
        """Commands to run for this application."""
        return [
            f'ssh {self.client_ip} "bash /root/bench.sh'
        ]


e = Experiment(name=exp_name)

# create the controller node
controller_config = UbuntuNodeConfig()
controller_config.raw_disk_image_path = projenv.get_ubuntu_raw_disk(
    f'{disk_prefix}/controller')
controller_config.cores = CONFIG.hosts.controller.cores
controller_config.memory = CONFIG.hosts.controller.memory
# controller_config.pre_cp_tc_ifaces = ['eth0', 'eth1']
controller_config.force_mac_addrs = {
    'eth0': CONFIG.hosts.controller.management_mac,
    'eth1': CONFIG.hosts.controller.provider_mac,
}
controller_config.app = ControllerApp()
controller = OpenstackGem5Host(controller_config)
controller.name = 'controller'
controller.wait = True
e.add_host(controller)

# create compute node 1
compute1_config = UbuntuNodeConfig()
compute1_config.raw_disk_image_path = projenv.get_ubuntu_raw_disk(
    f'{disk_prefix}/compute1')
compute1_config.cores = CONFIG.hosts.compute1.cores
compute1_config.memory = CONFIG.hosts.compute1.memory
# compute1_config.pre_cp_tc_ifaces = ['eth0', 'eth1']
compute1_config.force_mac_addrs = {
    'eth0': CONFIG.hosts.compute1.management_mac,
    'eth1': CONFIG.hosts.compute1.provider_mac,
}
compute1_config.app = IdleCheckpointApp()
compute1 = OpenstackGem5Host(compute1_config)
compute1.name = 'compute1'
compute1.wait = False
e.add_host(compute1)

# create compute node 2
compute2_config = UbuntuNodeConfig()
compute2_config.raw_disk_image_path = projenv.get_ubuntu_raw_disk(
    f'{disk_prefix}/compute2')
compute2_config.cores = CONFIG.hosts.compute1.cores
compute2_config.memory = CONFIG.hosts.compute1.memory
# compute2_config.pre_cp_tc_ifaces = ['eth0', 'eth1']
compute2_config.force_mac_addrs = {
    'eth0': CONFIG.hosts.compute2.management_mac,
    'eth1': CONFIG.hosts.compute2.provider_mac,
}
compute2_config.app = IdleCheckpointApp()
compute2 = OpenstackGem5Host(compute2_config)
compute2.name = 'compute2'
compute2.wait = False
e.add_host(compute2)

# set up management network
management_network = SwitchNet()
management_network.name = 'management_net'
e.add_network(management_network)
controller.add_netdirect(management_network)
compute1.add_netdirect(management_network)
compute2.add_netdirect(management_network)

# set up provider network
provider_network = SwitchNet()
provider_network.name = 'provider_net'
e.add_network(provider_network)
controller.add_netdirect(provider_network)
compute1.add_netdirect(provider_network)
compute2.add_netdirect(provider_network)

if CONFIG.ssh_control:
    assert False
    controller.ssh_port = CONFIG.hosts.controller.qemu_ssh_port
    compute1.ssh_port = CONFIG.hosts.compute1.qemu_ssh_port
    compute2.ssh_port = CONFIG.hosts.compute1.qemu_ssh_port
    controller_config.dhcp_ifaces.append('eth2')
    compute1_config.dhcp_ifaces.append('eth2')
    compute2_config.dhcp_ifaces.append('eth2')

config_experiment_sync(
    e, sync=CONFIG.sync, pci_latency=CONFIG.pci_latency, eth_latency=CONFIG.eth_latency)
config_experiment_checkpoint(e, CONFIG.cp)

experiments = [e]
