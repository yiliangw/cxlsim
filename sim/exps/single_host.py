import os

from simbricks.orchestration.experiments import Experiment
from simbricks.orchestration.simulators import I40eNIC, E1000NIC, SwitchNet

from lib.sim import OpenstackGem5Host, IdleCheckpointApp
from lib.ubuntu import UbuntuNodeConfig, UbuntuAppConfig
from lib.env import projenv
from lib.utils import config_experiment_sync

import typing as tp

CHECKPOINT = True
DISK = 'mysql/basic/controller'
NETWORK = True
SYNC = True
GEM5_VARIANT = 'fast'
NO_SIMBRICKS= False
GEM5_PY='simbricks_cxl.py'


class ControllerApp(UbuntuAppConfig):

    def __init__(self):
        super().__init__()

    def prepare_pre_cp(self) -> tp.List[str]:
        """Commands to run to prepare this application before checkpointing."""
        cmds = super().prepare_pre_cp()
        cmds += [
            'echo "Before checkpointing"'
        ]
        return cmds

    def run_cmds(self, node) -> tp.List[str]:
        """Commands to run for this application."""
        return [
            "echo 'Hello CXL!'"
        ]


e = Experiment('single_host')
e.checkpoint = CHECKPOINT

# create the controller node
host_config = UbuntuNodeConfig()
host_config.raw_disk_image_path = projenv.get_ubuntu_raw_disk(DISK)
host_config.cores = 4
host_config.memory = 8192
host_config.app = ControllerApp()
host = OpenstackGem5Host(host_config)
host.name = 'host'
host.variant = GEM5_VARIANT
host.gem5_py = GEM5_PY
host.wait = True
e.add_host(host)

if NETWORK:
    management_network = SwitchNet()
    management_network.name = 'management_net'
    e.add_network(management_network)
    host.add_netdirect(management_network)
    provider_network = SwitchNet()
    provider_network.name = 'provider_net'
    e.add_network(provider_network)
    host.add_netdirect(provider_network)

config_experiment_sync(
    e, sync=SYNC, pci_latency=1000, eth_latency=1000)
e.no_simbricks = NO_SIMBRICKS

experiments = [e]
