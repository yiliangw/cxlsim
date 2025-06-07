import typing as tp
from simbricks.orchestration.nodeconfig import AppConfig
from .env import projenv
from .sim import OpenstackNodeConfig


class UbuntuNodeConfig(OpenstackNodeConfig):

    def __init__(self):
        super().__init__()
        self.vmlinux_path = projenv.ubuntu_vmlinux_path
        self.initrd_path = projenv.ubuntu_initrd_path


class UbuntuAppConfig(AppConfig):

    def __init__(self):
        self.input_tar_path = None
        self.install_script_path = None

    def config_files(self) -> tp.Dict[str, tp.IO]:
        files = {}
        if self.input_tar_path is not None:
            files['input.tar'] = open(self.input_tar_path, 'rb')
        if self.install_script_path is not None:
            files['install.sh'] = open(self.install_script_path, 'rb')
        return files

    def prepare_pre_cp(self) -> tp.List[str]:
        cmds = []
        if self.input_tar_path is not None:
            cmd = 'bash /tmp/guest/install.sh'
            if self.input_tar_path is not None:
                cmd = 'INPUT_TAR=/tmp/guest/input.tar ' + cmd
            cmds.append(cmd)
        return cmds
