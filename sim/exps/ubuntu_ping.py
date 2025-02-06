import os
import sys
sys.path.append(os.path.join(os.path.dirname(__file__), '../lib'))

from simbricks.orchestration.experiments import Experiment
from simbricks.orchestration.simulators import I40eNIC, SwitchNet
from simbricks.orchestration.nodeconfig import NodeConfig, AppConfig

from baize.sim import OpenstackGem5Host, OpenstackNodeConfig
from baize.env import projenv

import typing as tp


class PingApp(AppConfig):
  """Check the state for a specific disk image for further setup."""

  def __init__(self):
    self.server_ip = '10.0.0.1'
    self.ip = '10.0.0.2'
    self.prefix = 24
    self.device = 'eth0'

  def prepare_pre_cp(self) -> tp.List[str]:
    return [
        f'echo "--- OpenstackPingApp ---"',
        f'ip link',
        f'ip link set dev {self.device} up',
        f'ip addr add {self.ip}/{self.prefix} dev {self.device}',
        f'while ! ssh {self.server_ip} uptime; do sleep 1; done',
        f'ssh {self.server_ip} "touch ~/.prepare.done"',
        f'sleep 1',
    ]

  def run_cmds(self, node: NodeConfig) -> tp.List[str]:
    return [
        f'while ! ping -c 1 {self.server_ip}; do echo "Pinging..."; done',
        f'echo "Ping success! Finsh."',
        f'ssh {self.server_ip} "m5 exit"'
    ]


class PongApp(AppConfig):

  def __init__(self):
    self.ip = '10.0.0.1'
    self.client_ip = '10.0.0.2'
    self.prefix = 24
    self.device = 'eth0'

  def prepare_pre_cp(self):
    return [
        f'echo "--- OpenstackPongApp ---"',
        f'ip link',
        f'ip link set dev {self.device} up',
        f'ip addr add {self.ip}/{self.prefix} dev {self.device}',
        f'while [ ! -f ~/.prepare.done ]; do sleep 1; done',
        f'echo "Found ~/.prepare.done!"',
        f'sleep 1'
    ]

  def run_cmds(self, node: NodeConfig) -> tp.List[str]:
    return [
      'sleep infinity'
    ]


e = Experiment(name='ubuntu_ping')
e.checkpoint = True  # use checkpoint and restore to speed up simulation

ping_host_config = OpenstackNodeConfig()
ping_host_config.app = PingApp()
ping_host_config.vmlinux_path = projenv.ubuntu_kernel_path
ping_host_config.raw_disk_image_path = projenv.get_ubuntu_raw_disk('base')

ping_host = OpenstackGem5Host(ping_host_config)
ping_host.name = 'ping_host'
ping_host.wait = True
e.add_host(ping_host)

ping_nic = I40eNIC()
e.add_nic(ping_nic)
ping_host.add_nic(ping_nic)

pong_host_config = OpenstackNodeConfig()
pong_host_config.app = PongApp()
pong_host_config.vmlinux_path = projenv.ubuntu_kernel_path
pong_host_config.raw_disk_image_path = projenv.get_ubuntu_raw_disk('base')

pong_host = OpenstackGem5Host(pong_host_config)
pong_host.name = 'pong_host'
pong_host.wait = False
e.add_host(pong_host)

pong_nic = I40eNIC()
e.add_nic(pong_nic)
pong_host.add_nic(pong_nic)

network = SwitchNet()
e.add_network(network)
ping_nic.set_network(network)
pong_nic.set_network(network)

eth_latency = 500  # 500 us
network.eth_latency = eth_latency
ping_nic.eth_latency = eth_latency
pong_nic.eth_latency = eth_latency

experiments = [e]
