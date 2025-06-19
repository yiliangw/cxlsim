import os
from abc import ABC, abstractmethod


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


class Workload(ABC):

    def __init__(self):
        self.server_ip: str = None
        self.client_ip: str = None

    def prepare_server(self) -> str:
        return """
set -ex

busybox telnetd -l /bin/sh

until mysql -u root <<EOF_PREPARE_SERVER
CREATE DATABASE IF NOT EXISTS testdb;
CREATE USER IF NOT EXISTS 'testuser'@'%' IDENTIFIED BY 'testpass';
GRANT ALL PRIVILEGES ON testdb.* TO 'testuser'@'%';
FLUSH PRIVILEGES;
EOF_PREPARE_SERVER
do
echo Failed to set up the database, retrying...
sleep 3
done
"""

    @abstractmethod
    def prepare_client(self) -> str:
        pass

    @abstractmethod
    def bench_client(self) -> str:
        pass


class MysqlslapWorkload(Workload):

    def __init__(self):
        super().__init__()
        self.server_ip = instances_ips['server']
        self.client_ip = instances_ips['client']

    def prepare_client(self):
        return f"""
set -ex    

busybox telnetd -l /bin/sh

until mysqladmin ping -h {self.server_ip} -u testuser --password=testpass --silent; do
    echo "Waiting for MySQL server at {self.server_ip} to be ready..."
    sleep 3
done

mysql -h {self.server_ip} -u testuser --password=testpass <<EOF_PREPARE_CLIENT
USE testdb;
CREATE TABLE IF NOT EXISTS testtable (
  id INT PRIMARY KEY AUTO_INCREMENT,
  value VARCHAR(100)
);

INSERT INTO testtable (value) VALUES ('testdata') ON DUPLICATE KEY UPDATE value='testdata';
EOF_PREPARE_CLIENT
"""

    def bench_client(self):
        return f"""
set -ex
until mysqladmin ping -h {self.server_ip} -u testuser --password=testpass --silent; do
    echo "Waiting for MySQL server at {self.server_ip} to be ready..."
    sleep 1
done

mysqlslap -h {self.server_ip} -u testuser --password=testpass       \\
    --concurrency=1 --iterations=1              \\
    --query="SELECT * FROM testtable LIMIT 1;"  \\
    --create-schema=testdb --engine=innodb
"""


class SysbenchWorkload(Workload):

    def __init__(self):
        super().__init__()
        self.server_ip = instances_ips['server']
        self.client_ip = instances_ips['client']

    def prepare_client(self):
        return f"""
set -ex

busybox telnetd -l /bin/sh

until mysqladmin ping -h {self.server_ip} -u testuser --password=testpass --silent; do
    echo "Waiting for MySQL server at {self.server_ip} to be ready..."
    sleep 3
done

sysbench oltp_read_write \\
    --table-size=100 \\
    --mysql-host={self.server_ip} \\
    --mysql-db=testdb \\
    --mysql-user=testuser \\
    --mysql-password=testpass \\
    prepare
"""

    def bench_client(self):
        return f"""
set -ex

sysbench oltp_read_write \\
    --threads=1 \\
    --time=2 \\
    --mysql-host={self.server_ip} \\
    --mysql-db=testdb \\
    --mysql-user=testuser \\
    --mysql-password=testpass \\
    run
"""


class ControllerApp(CxlSimAppConfig):

    def __init__(self):
        super().__init__()
        self.compute_nodes = ['compute1', 'compute2']
        self.workload: Workload = None

    def prepare_pre_cp(self) -> tp.List[str]:
        """Commands to run to prepare this application before checkpointing."""
        ckp_file = self.CHECKPOINT_BARRIER_FILE

        server_ip = self.workload.server_ip
        client_ip = self.workload.client_ip

        cmds: list = super().prepare_pre_cp()
        script = f"""
source /root/env/user_openrc
for h in {' '.join(self.compute_nodes)}; do
    until openstack compute service list | grep $h | grep -q enabled.*up; do
        ping $h -c 1
        sleep 5
    done
done
sleep 10

openstack server start server client
sleep 120

# Wait until the guests are online
{self._wait_for_guest_boot('server', server_ip)}
{self._wait_for_guest_boot('client', client_ip)}

sleep 10

# Preare the server
ssh {server_ip} bash <<EOF
{self.workload.prepare_server()}
EOF

# Prepare the client
ssh {client_ip} bash <<EOF
{self.workload.prepare_client()}
EOF

# Do a dry run
echo Dry run...
until script -q -c "telnet {client_ip}" /dev/null <<EOF
until bash <<EOF1
{self.workload.bench_client()}
EOF1
do
    echo Bench commands failed, retrying...
done
EOF
do
    echo script failed, retrying...
done

# Notify checkpointing
for h in {' '.join(self.compute_nodes)}; do
    ssh $h touch {ckp_file}
done
"""
        cmds.append(script)
        return cmds

    def run_cmds(self, node) -> tp.List[str]:
        """Commands to run for this application."""
        cmds = []
        if CONFIG.net_direct:
            # Otherwise, the switches will exit after the host exit
            cmds += ['exit 0']
        else:
            cmds += ['m5 exit']
        return cmds

    def _wait_for_guest_boot(self, name, ip):
        return f"""
until ssh {ip} true; do
    openstack server show {name} -c status
    openstack console log show {name} | tail
    # Sometimes VMs can get stuck here and need reboot
    if openstack console log show {name} | grep -q "You are in emergency mode"; then
        if openstack server show {name} -c status | grep -q ACTIVE; then
            openstack server reboot {name}
        fi
        sleep 180
    fi
    sleep 10
done
"""


class Compute1App(IdleCheckpointApp):

    def run_cmds(self, node) -> tp.List[str]:
        cmds = []
        if CONFIG.interactive_post_ckp:
            cmds += ["echo 'Configured interactive mode after checkpointing'"]
        cmds += ["exit 0"]
        return cmds


class Compute2App(IdleCheckpointApp):

    def __init__(self):
        super().__init__()
        self.workload: Workload = None

    def run_cmds(self, node) -> tp.List[str]:
        """Commands to run for this application."""
        server_ip = self.workload.server_ip
        client_ip = self.workload.client_ip

        cmds = []
        if CONFIG.interactive_post_ckp:
            cmds += ["echo 'Configured interactive mode after checkpointing'"]
            cmds += ["exit 0"]

        script = f"""
until ping -c 1 {server_ip}; do sleep 1; done
until script -q -c "telnet {client_ip}" /dev/null <<EOF
until bash <<EOF1
{self.workload.bench_client()}
EOF1
do
    echo Bench commands failed, retrying...
done
EOF
do
    echo script failed, retrying...
done

# Notify other nodes to exit            
for n in compute1 controller; do
    (printf "m5 exit\\n" | script -q -c "telnet $n" /dev/null) || true
done
"""
        cmds.append(script)
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

    NCONFIG = getattr(CONFIG.hosts, node)

    config = CxlSimNodeConfig()
    config.disable_guestinit = CONFIG.interactive
    config.vmlinux_path = projenv.ubuntu_vmlinux_path
    config.initrd_path = projenv.ubuntu_initrd_path
    config.raw_disk_image_path = projenv.get_ubuntu_raw_disk(
        f'{disk_prefix}/{node}')
    config.cores = NCONFIG.cores
    config.memory = NCONFIG.memory
    config.cxl_memory = getattr(NCONFIG, 'cxl_memory', 0)
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

    management_mac = getattr(CONFIG.hosts, node).management_mac
    provider_mac = getattr(CONFIG.hosts, node).provider_mac

    if CONFIG.net_direct:
        host.add_netdirect(management_net)
        host.add_netdirect(provider_net)
        config.force_mac_addrs['eth0'] = management_mac
        config.force_mac_addrs['eth1'] = provider_mac
        config.ckp_unbind_eth = False
        config.eth_driver = 'e1000'
    else:
        management_nic = NIC_SIM()
        management_nic.name = 'management'
        management_nic.mac = management_mac
        e.add_nic(management_nic)
        host.add_nic(management_nic)
        management_nic.set_network(management_net)

        provider_nic = NIC_SIM()
        provider_nic.name = 'provider'
        provider_nic.mac = provider_mac
        e.add_nic(provider_nic)
        host.add_nic(provider_nic)
        provider_nic.set_network(provider_net)

    return host


workload = SysbenchWorkload()

controllerApp = ControllerApp()
controllerApp.workload = workload
compute1App = Compute1App()
compute2App = Compute2App()
compute2App.workload = workload

create_openstack_node('controller', controllerApp)
create_openstack_node('compute1', compute1App)
create_openstack_node('compute2', compute2App)

config_experiment_sync(
    e, sync=CONFIG.sync,
    pci_latency=CONFIG.pci_latency,
    eth_latency=CONFIG.eth_latency
)
config_experiment_checkpoint(e, CONFIG.cp)

experiments = [e]
