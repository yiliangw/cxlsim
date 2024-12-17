d := $(shell dirname $(lastword $(MAKEFILE_LIST)))

SIMBRICKS_DOCKER_IMAGE := simbricks/simbricks-build
SIMBRICKS_DOCKER_NAME := baize_simbricks_build_

simbricks_docker_exec := docker exec $(SIMBRICKS_DOCKER_NAME) /bin/bash -c

simbricks_dir := $(d)/simbricks
simbricks_run_script := $(simbricks_dir)/experiments/run.py
output_dir := $(d)/out
exp_script := $(d)/exps/simple_ping.py


SIMBRICKS_OPTIONS := --repo $(simbricks_dir) --workdir $(output_dir) --outdir $(output_dir) --cpdir $(output_dir) --runs 1 --verbose --force

.PHONY: pull-simbricks-docker start-simbricks-docker stop-simbricks-docker

pull-simbricks-docker:
	docker pull $(SIMBRICKS_DOCKER_IMAGE)	

start-simbricks-docker:
	$(call start_container,$(SIMBRICKS_DOCKER_NAME),$(SIMBRICKS_DOCKER_IMAGE))

stop-simbricks-docker:
	$(call stop_container,$(SIMBRICKS_DOCKER_NAME))

.PHONY: build-simbricks
build-simbricks:
	git submodule update --init --recursive $(simbricks_dir)
	make start-simbricks-docker
	$(simbricks_docker_exec) 'make -C $(simbricks_dir) -j`nproc` all sims/external/qemu/ready sims/external/ns-3/ready sims/external/gem5/ready'
	$(simbricks_docker_exec) 'make -C $(simbricks_dir) -j`nproc` build-images-min convert-images-raw'
	make stop-simbricks-docker

.PHONY: run-exp
run-exp:
	mkdir -p $(output_dir)
	make start-simbricks-docker
	$(simbricks_docker_exec) "python $(simbricks_run_script) $(SIMBRICKS_OPTIONS) $(exp_script)" 
	make stop-simbricks-docker

$(output_dir):
	mkdir -p $(output_dir)
