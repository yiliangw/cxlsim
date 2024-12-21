
simbricks_docker_exec := docker exec $(SIMBRICKS_DOCKER_NAME) /bin/bash -c

simbricks_dir := $(d)simbricks
simbricks_run_script := $(simbricks_dir)/experiments/run.py
exp_script := $(d)exps/simple_ping.py


SIMBRICKS_OPTIONS := --repo $(simbricks_dir) --workdir $(o) --outdir $(o) --cpdir $(o) --runs 1 --verbose --force

.PHONY: build-simbricks
build-simbricks: pull-simbricks-docker
	git submodule update --init --recursive $(simbricks_dir)
	make start-simbricks-docker
	$(simbricks_docker_exec) 'make -C $(simbricks_dir) -j`nproc` all sims/external/qemu/ready sims/external/ns-3/ready sims/external/gem5/ready'
	$(simbricks_docker_exec) 'make -C $(simbricks_dir) -j`nproc` build-images-min convert-images-raw'
	make stop-simbricks-docker

.PHONY: run-exp
run-exp:
	mkdir -p $(o)
	make start-simbricks-docker
	$(simbricks_docker_exec) "python $(simbricks_run_script) $(SIMBRICKS_OPTIONS) $(exp_script)" 
	make stop-simbricks-docker
