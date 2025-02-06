import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '../lib'))

from simbricks.orchestration.experiments import Experiment
from simbricks.orchestration.simulators import I40eNIC, SwitchNet
from simbricks.orchestration.nodeconfig import NodeConfig, AppConfig

from baize.sim import OpenstackGem5Host, OpenstackNodeConfig
from baize.env import projenv

import typing as tp
from easydict import EasyDict as edict

config = edict()

config.sync = False
config.sync_period = 1000
config.cp = False
config.user_name = projenv.config.platform.ubuntu.user.name


class OpenstackUbuntuNode(OpenstackNodeConfig):

  def __init__(self):
    super().__init__()
    self.vmlinux_path = projenv.ubuntu_kernel_path


class ControllerApp(AppConfig):

  def run_cmds(self, node: NodeConfig) -> tp.List[str]:
    """Commands to run for this application."""
    return [f'bash /root/run/run.sh']

  def prepare_pre_cp(self) -> tp.List[str]:
    """Commands to run to prepare this application before checkpointing."""
    return [f'bash /root/prepare/run.sh']

  def prepare_post_cp(self) -> tp.List[str]:
    """Commands to run to prepare this application after the checkpoint is
    restored."""
    return []


class ComputeApp(AppConfig):

  def run_cmds(self, node: NodeConfig) -> tp.List[str]:
    """Commands to run for this application."""
    return [f'sleep inifinity']

  def prepare_pre_cp(self) -> tp.List[str]:
    """Commands to run to prepare this application before checkpointing."""
    return [f'while [ ! -f /root/prepare/.done ]; do echo "waiting to be prepared by controller..."; sleep 3; done']

  def prepare_post_cp(self) -> tp.List[str]:
    """Commands to run to prepare this application after the checkpoint is
    restored."""
    return []


e = Experiment(name='ubuntu_mysql')
e.checkpoint = True  # use checkpoint and restore to speed up simulation

# create controller node
controller_config = OpenstackUbuntuNode()
controller_config.raw_disk_image_path = projenv.get_ubuntu_raw_disk(
    'controller')
controller_config.app = ControllerApp()
controller = OpenstackGem5Host(controller_config)
controller.name = 'controller'
controller.wait = True
e.add_host(controller)

# attach controller's NIC
controller_management_nic = I40eNIC()
controller_management_nic.name = 'management'
e.add_nic(controller_management_nic)
controller.add_nic(controller_management_nic)

controller_provider_nic = I40eNIC()
controller_provider_nic.name = 'provider'
e.add_nic(controller_provider_nic)
controller.add_nic(controller_provider_nic)

# # create compute node
compute1_config = OpenstackUbuntuNode()
compute1_config.raw_disk_image_path = projenv.get_ubuntu_raw_disk('compute1')
compute1_config.app = ComputeApp()
compute1 = OpenstackGem5Host(compute1_config)
compute1.name = 'compute1'
compute1.wait = False
e.add_host(compute1)

# attach compute1's NIC
compute1_management_nic = I40eNIC()
compute1_management_nic.name = 'management'
e.add_nic(compute1_management_nic)
compute1.add_nic(compute1_management_nic)
compute1_provider_nic = I40eNIC()
compute1_provider_nic.name = 'provider'
e.add_nic(compute1_provider_nic)
compute1.add_nic(compute1_provider_nic)

# set up management network
management_network = SwitchNet()
management_network.name = 'management_net'
e.add_network(management_network)
controller_management_nic.set_network(management_network)
compute1_management_nic.set_network(management_network)

# set up provider network
provider_network = SwitchNet()
provider_network.name = 'provider_net'
e.add_network(provider_network)
controller_provider_nic.set_network(provider_network)
compute1_provider_nic.set_network(provider_network)

# eth_latency = 500 * 10**3  # 500 us
# management_network.eth_latency = eth_latency
# provider_network.eth_latency = eth_latency
# controller_management_nic.eth_latency = eth_latency
# controller_provider_nic.eth_latency = eth_latency
# compute1_management_nic.eth_latency = eth_latency
# compute1_provider_nic.eth_latency = eth_latency

# # initialize synchronization parameters
# for h in e.hosts:
#   h.sync_mode = 1 if config.sync else 0
#   h.sync_period = config.sync_period
#   h.pci_latency = config.sync_period

# for n in e.nics:
#   n.sync_mode = 1 if config.sync else 0
#   n.sync_period = config.sync_period
#   n.pci_latency = config.sync_period
#   n.eth_latency = config.sync_period

# for n in e.networks:
#   n.sync_mode = 0 if config.sync else 0
#   n.sync_period = config.sync_period
#   n.eth_latency = config.sync_period

experiments = [e]
