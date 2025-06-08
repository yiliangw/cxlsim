from simbricks.orchestration.experiments import Experiment
from simbricks.orchestration.simulators import QemuHost, Gem5Host, SwitchNet


def config_experiment_sync(e: Experiment, sync: bool, pci_latency: int = 500, eth_latency: int = 500):
  # Synchronization
  sync_period = min(pci_latency, eth_latency)
  for h in e.hosts:
    h.sync_mode = 1 if sync else 0
    h.sync_period = sync_period
    h.pci_latency = pci_latency
    if isinstance(h, QemuHost):
      h.sync = sync
    elif isinstance(h, Gem5Host):
      if not sync:
        h.cpu_type = 'X86KvmCPU'

  for n in e.nics:
    n.sync_mode = 1 if sync else 0
    n.sync_period = sync_period
    n.pci_latency = pci_latency
    n.eth_latency = eth_latency

  for n in e.networks:
    n.sync_mode = 1 if sync else 0
    n.sync_period = sync_period
    n.eth_latency = eth_latency
    if isinstance(n, SwitchNet):
      n.sync = sync

def config_experiment_checkpoint(e: Experiment, cp: bool):
  e.checkpoint = cp
  for h in e.hosts:
    if isinstance(h, Gem5Host):
      h.nockp = not cp
