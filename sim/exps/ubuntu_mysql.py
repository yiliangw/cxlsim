import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '../lib'))

from simbricks.orchestration.experiments import Experiment
from simbricks.orchestration.simulators import I40eNIC, E1000NIC, SwitchNet
from simbricks.orchestration.nodeconfig import NodeConfig, AppConfig

from baize.sim import OpenstackQemuHost, OpenstackGem5Host, OpenstackNodeConfig
from baize.env import projenv
from baize.utils import config_experiment_sync

import typing as tp
from easydict import EasyDict as edict
import yaml

exp_name = os.path.basename(__file__).replace('.py', '')
config_file = os.path.abspath(__file__).replace('.py', '.yaml')

with open(config_file, 'r') as f:
  CONFIG = edict(yaml.full_load(f))

if CONFIG.host_sim == 'qemu':
  HostSimCls = OpenstackQemuHost
elif CONFIG.host_sim == 'gem5':
  HostSimCls = OpenstackGem5Host
else:
  raise ValueError(f'Unknown host simulator: {CONFIG.host_sim}')

if CONFIG.nic_sim == 'i40e':
  NicSimCls = I40eNIC
elif CONFIG.nic_sim == 'e1000':
  NicSimCls = E1000NIC
else:
  raise ValueError(f'Unknown NIC simulator: {CONFIG.nic_sim}')

gateway_management_ip = projenv.config.openstack.network.management.gateway
controller_management_ip = projenv.config.openstack.network.management.hosts.controller.ip


class UbuntuHostConfig(OpenstackNodeConfig):

  def __init__(self):
    super().__init__()
    self.vmlinux_path = projenv.ubuntu_vmlinux_path
    self.initrd_path = projenv.ubuntu_initrd_path


class GatewayApp(AppConfig):

  def prepare_pre_cp(self) -> tp.List[str]:
    """Commands to run to prepare this application before checkpointing."""
    return [
        f'while [ ! -f /root/.prepare.done ]; do sleep 10; done',
        'sleep 3',
    ]

  def run_cmds(self, node: NodeConfig) -> tp.List[str]:
    return [
        'sleep infinity'
    ]


class ControllerApp(AppConfig):

  def prepare_pre_cp(self) -> tp.List[str]:
    """Commands to run to prepare this application before checkpointing."""
    return [
        # ensure connection from both side can be setup
        "while ! ssh compute1 'while ! ssh controller uptime; do sleep 3; done'; do sleep 3; done",
        f'while ! ssh {gateway_management_ip} "while ! ssh {controller_management_ip}; do sleep 3; done"; do sleep 3; done',
        "bash /root/prepare/run.sh",
        "ssh compute1 'touch /root/.prepare.done'",
        "ssh gateway 'touch /root/.prepare.done'",
        "sleep 3",
    ]

  def run_cmds(self, node: NodeConfig) -> tp.List[str]:
    """Commands to run for this application."""
    return [
        f'bash /root/run/run.sh'
    ]


class ComputeApp(AppConfig):

  def prepare_pre_cp(self) -> tp.List[str]:
    """Commands to run to prepare this application before checkpointing."""
    return [
        f'while [ ! -f /root/.prepare.done ]; do sleep 10; done',
        'sleep 3',
    ]

  def run_cmds(self, node: NodeConfig) -> tp.List[str]:
    """Commands to run for this application."""
    return [
        'sleep inifinity'
    ]


e = Experiment(name=exp_name)
e.checkpoint = CONFIG.cp  # use checkpoint and restore to speed up simulation

# create the gateway
gateway_config = UbuntuHostConfig()
gateway_config.disk_image_path = projenv.get_ubuntu_disk('gateway')
gateway_config.raw_disk_image_path = projenv.get_ubuntu_raw_disk('gateway')
gateway_config.cores = CONFIG.hosts.gateway.cores
gateway_config.memory = CONFIG.hosts.gateway.memory
gateway_config.force_mac_addrs = {
    'eth0': CONFIG.hosts.gateway.management_mac,
    'eth1': CONFIG.hosts.gateway.provider_mac,
}
gateway_config.app = GatewayApp()
gateway = HostSimCls(gateway_config)
gateway.name = 'gateway'
gateway.wait = False
e.add_host(gateway)

# attach the gateway's NICs
if not CONFIG.net_direct:
  gateway_management_nic = NicSimCls()
  gateway_management_nic.name = 'management'
  e.add_nic(gateway_management_nic)
  gateway.add_nic(gateway_management_nic)

  gateway_provider_nic = NicSimCls()
  gateway_provider_nic.name = 'provider'
  e.add_nic(gateway_provider_nic)
  gateway.add_nic(gateway_provider_nic)

# create the controller node
controller_config = UbuntuHostConfig()
controller_config.disk_image_path = projenv.get_ubuntu_disk(
    'controller')
controller_config.raw_disk_image_path = projenv.get_ubuntu_raw_disk(
    'controller')
controller_config.cores = CONFIG.hosts.controller.cores
controller_config.memory = CONFIG.hosts.controller.memory
controller_config.force_mac_addrs = {
    'eth0': CONFIG.hosts.controller.management_mac,
    'eth1': CONFIG.hosts.controller.provider_mac,
}
controller_config.app = ControllerApp()
controller = HostSimCls(controller_config)
controller.name = 'controller'
controller.wait = True
e.add_host(controller)

# attach controller's NIC
if not CONFIG.net_direct:
  controller_management_nic = NicSimCls()
  controller_management_nic.name = 'management'
  e.add_nic(controller_management_nic)
  controller.add_nic(controller_management_nic)

  controller_provider_nic = NicSimCls()
  controller_provider_nic.name = 'provider'
  e.add_nic(controller_provider_nic)
  controller.add_nic(controller_provider_nic)

# # create compute node
compute1_config = UbuntuHostConfig()
compute1_config.disk_image_path = projenv.get_ubuntu_disk('compute1')
compute1_config.raw_disk_image_path = projenv.get_ubuntu_raw_disk('compute1')
compute1_config.cores = CONFIG.hosts.compute1.cores
compute1_config.memory = CONFIG.hosts.compute1.memory
compute1_config.force_mac_addrs = {
    'eth0': CONFIG.hosts.compute1.management_mac,
    'eth1': CONFIG.hosts.compute1.provider_mac,
}
compute1_config.app = ComputeApp()
compute1 = HostSimCls(compute1_config)
compute1.name = 'compute1'
compute1.wait = False
e.add_host(compute1)

# attach compute1's NIC
if not CONFIG.net_direct:
  compute1_management_nic = NicSimCls()
  compute1_management_nic.name = 'management'
  e.add_nic(compute1_management_nic)
  compute1.add_nic(compute1_management_nic)

  compute1_provider_nic = NicSimCls()
  compute1_provider_nic.name = 'provider'
  e.add_nic(compute1_provider_nic)
  compute1.add_nic(compute1_provider_nic)

# set up management network
management_network = SwitchNet()
management_network.name = 'management_net'
e.add_network(management_network)
if not CONFIG.net_direct:
  gateway_management_nic.set_network(management_network)
  controller_management_nic.set_network(management_network)
  compute1_management_nic.set_network(management_network)
else:
  gateway.add_netdirect(management_network)
  controller.add_netdirect(management_network)
  compute1.add_netdirect(management_network)

# set up provider network
provider_network = SwitchNet()
provider_network.name = 'provider_net'
e.add_network(provider_network)
if not CONFIG.net_direct:
  gateway_provider_nic.set_network(provider_network)
  controller_provider_nic.set_network(provider_network)
  compute1_provider_nic.set_network(provider_network)
else:
  gateway.add_netdirect(provider_network)
  controller.add_netdirect(provider_network)
  compute1.add_netdirect(provider_network)

config_experiment_sync(
    e, sync=CONFIG.sync, pci_latency=CONFIG.pci_latency, eth_latency=CONFIG.eth_latency)

experiments = [e]
