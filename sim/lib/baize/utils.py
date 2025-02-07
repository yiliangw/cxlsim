from simbricks.orchestration.experiments import Experiment
from simbricks.orchestration.simulators import QemuHost


def config_experiment_sync(e: Experiment, sync: bool, sync_period: int = 500):
  # Synchronization
  for h in e.hosts:
    h.sync_mode = 1 if sync else 0
    h.sync_period = sync_period
    h.pci_latency = sync_period
    if isinstance(h, QemuHost):
      h.sync = sync

  for n in e.nics:
    n.sync_mode = 1 if sync else 0
    n.sync_period = sync_period
    n.pci_latency = sync_period
    n.eth_latency = sync_period

  for n in e.networks:
    n.sync_mode = 1 if sync else 0
    n.sync_period = sync_period
    n.eth_latency = sync_period
