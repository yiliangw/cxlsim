import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '../lib'))

from simbricks.orchestration.experiments import Experiment
from simbricks.orchestration.simulators import I40eNIC, E1000NIC, SwitchNet
from simbricks.orchestration.nodeconfig import AppConfig, NodeConfig

from baize.sim import OpenstackQemuHost, OpenstackGem5Host, OpenstackNodeConfig
from baize.env import projenv
from baize.utils import config_experiment_sync

import typing as tp

from easydict import EasyDict as edict

CONFIG = edict()

CONFIG.sync = True
CONFIG.pci_latency = 1000
CONFIG.eth_latency = 1000
CONFIG.cp = True
CONFIG.host_cores = 4
CONFIG.host_memory = 1024 * 8
CONFIG.host_sim = OpenstackQemuHost
CONFIG.host_sim = 'gem5'
CONFIG.net_direct = True
CONFIG.nic_sim = 'e1000'

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


class UbuntuOpenstackNodeConfig(OpenstackNodeConfig):

  def __init__(self):
    super().__init__()
    self.vmlinux_path = projenv.ubuntu_vmlinux_path
    self.initrd_path = projenv.ubuntu_initrd_path
    self.cores = CONFIG.host_cores
    self.memory = CONFIG.host_memory


class SshCient(AppConfig):
  """Check the state for a specific disk image for further setup."""

  def __init__(self):
    self.server_ip = '10.0.0.1'
    self.ip = '10.0.0.2'
    self.mac_addr = '52:54:00:11:11:01'
    self.prefix = 24
    self.device = 'eth0'

  def prepare_pre_cp(self) -> tp.List[str]:
    return [
        f'echo "--- OpenstackPingApp ---"',
        f'ip link',
        f'ip link set dev {self.device} address {self.mac_addr}',
        f'ip link set dev {self.device} up',
        f'ip addr add {self.ip}/{self.prefix} dev {self.device}',
        f'sleep 5',
        f'ping -c 10 {self.server_ip}',
        f'while ! ssh {self.server_ip} uptime; do sleep 1; done',
        f'ssh {self.server_ip} "touch ~/.prepare.done"',
        f'sleep 1',
    ]

  def run_cmds(self, node: NodeConfig) -> tp.List[str]:
    return [
        f'while ! ssh {self.server_ip} uptime; do echo "Trying ssh connection..."; done',
        f'echo "ssh success! Done."',
    ]


class SshServer(AppConfig):

  def __init__(self):
    self.ip = '10.0.0.1'
    self.mac_addr = '52:54:00:11:11:02'
    self.prefix = 24
    self.device = 'eth0'

  def prepare_pre_cp(self):
    return [
        f'echo "--- OpenstackPongApp ---"',
        f'ip link',
        f'ip link set dev {self.device} address {self.mac_addr}',
        f'ip link set dev {self.device} up',
        f'ip addr add {self.ip}/{self.prefix} dev {self.device}',
        f'while [ ! -f ~/.prepare.done ]; do sleep 5; done',
        f'echo "Found ~/.prepare.done!"',
    ]

  def run_cmds(self, node: NodeConfig) -> tp.List[str]:
    return [
        'sleep infinity'
    ]


e = Experiment(name='ubuntu_ssh')
e.checkpoint = CONFIG.cp  # use checkpoint and restore to speed up simulation

client_config = UbuntuOpenstackNodeConfig()
client_config.app = SshCient()
client_config.disk_image_path = projenv.get_ubuntu_disk('base')
client_config.raw_disk_image_path = projenv.get_ubuntu_raw_disk('base')

cient = HostSimCls(client_config)
cient.name = 'ssh_client'
cient.wait = True
e.add_host(cient)

if not CONFIG.net_direct:
  client_nic = NicSimCls()
  client_nic.debug = False
  e.add_nic(client_nic)
  cient.add_nic(client_nic)

server_config = UbuntuOpenstackNodeConfig()
server_config.app = SshServer()
server_config.disk_image_path = projenv.get_ubuntu_disk('base')
server_config.raw_disk_image_path = projenv.get_ubuntu_raw_disk('base')

server = HostSimCls(server_config)
server.name = 'ssh_server'
server.wait = False
e.add_host(server)

if not CONFIG.net_direct:
  server_nic = NicSimCls()
  server_nic.debug = False
  e.add_nic(server_nic)
  server.add_nic(server_nic)

network = SwitchNet()
network.name = 'net'
e.add_network(network)
if CONFIG.net_direct:
  cient.add_netdirect(network)
  server.add_netdirect(network)
else:
  client_nic.set_network(network)
  server_nic.set_network(network)

config_experiment_sync(
    e, sync=CONFIG.sync, pci_latency=CONFIG.pci_latency, eth_latency=CONFIG.eth_latency)

experiments = [e]
