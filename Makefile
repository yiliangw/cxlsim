include docker.mk

simbricks_dir := sim/simbricks

.PHONY: build-simbricks
build-simbricks:
	git submodule update --init --recursive $(simbricks_dir)
	make start-simbricks-docker
	$(simbricks_docker_exec) 'make -C $(simbricks_dir) -j`nproc` all sims/external/qemu/ready sims/external/ns-3/ready'
	make stop-simbricks-docker
