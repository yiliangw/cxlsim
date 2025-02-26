Baize
-----

Quick Start
===========

Most of the project's dependencies are managed with Docker.
After building the images, you can access the environment either by working with Visual Studio Code's dev container or by starting the container with an interactive shell.

Prerequisites:

- x86 linux machine with at least 32 CPU cores, 32G memory and 350G free disk space.

- KVM is available.

- `git`, `make` and `docker` (with docker compose plugin) have been installed on the system.

- sudo is enabled for the current user.

Steps:

1. Initialize submodules:
    ```bash
    git submodules update --init --recursive --depth 1
    ```

2. Add the current user to `docker` and `kvm` groups:
    ```bash
    sudo usermod -aG docker $USER
    sudo usermod -aG kvm $USER
    ```

3. Configure the image's user information in `.devcontainer/rules.mk`. By default, the created user will have the same user ID and group ID as the current user on the host. This avoids any conflicts in the file system. 

4. Build the docker image for the dev container:
    ```bash
    make devcontainer
    ```

5. Access the environment with either of the two options:
    - Reopen the project in the dev container with Visual Studio Code.
    - Run the container and start an interacting shell by running `make run-devcontainer`. 

The following steps should be executed inside the container.

6. Build SimBricks:
    ```bash
    make simbricks-build
    ```

7. Run the example experiment:
    ```bash
    make run-ubuntu-mysql
    ```
    This experiment builds up an OpenStack system with a controller, a compute node and a gateway.
    After setting up, a MySQL server and a client will be launched as instances on the provider network and run some simple workload. 
