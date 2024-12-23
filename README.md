Baize
-----

Quick Start
===========

Prerequisites:

- `git`, `make` and `docker` is installed on the system

- sudo is enabled for the current user

Steps:

1. Initialize submodules
```bash
git submodules update --init --recursive --depth 1
```

2. Add the current user to group `docker` and `kvm`
```bash
sudo usermod -aG docker $USER
sudo usermod -aG kvm $USER
```

3. Prepare docker images
```bash
make build-docker-images
```

4. Build Simbricks
```bash
make build-simbricks
```
