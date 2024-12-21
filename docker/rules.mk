$(info inside docker/rules.mk)

DOCKER_BUILD_DIR := $(d) 
DOCKER_WORKDIR := /workspace

SIMBRICKS_DOCKER_IMAGE := simbricks/simbricks-build
SIMBRICKS_DOCKER_NAME := baize_simbricks_build_

UBUNTU_DOCKER_FILE := $(d)Dockerfile.ubuntu
UBUNTU_DOCKER_IMAGE := baize-ubuntu
UBUNTU_DOCKER_NAME := baize_ubuntu_   

define start_container # $(1) - container name, $(2) - image name
	$(call stop_container,$(1))
	docker run \
		--user $(shell id -u):$(shell id -g) \
    --group-add $(shell cat /etc/group | grep kvm | awk -F: '{print $$3}') \
		--rm -d -i --name $(1) \
		--mount type=bind,source=$(shell pwd),target=$(DOCKER_WORKDIR) \
    --volume /etc/group:/etc/group:ro \
    --volume /etc/passwd:/etc/passwd:ro \
    --volume /etc/shadow:/etc/shadow:ro \
    --device /dev/kvm --privileged \
		--workdir $(DOCKER_WORKDIR) \
		$(2)
endef

define stop_container
	docker rm -f $(1)
endef

.PHONY: pull-simbricks-docker start-simbricks-docker stop-simbricks-docker

pull-simbricks-docker:
	docker pull $(SIMBRICKS_DOCKER_IMAGE)	

start-simbricks-docker:
	$(call start_container,$(SIMBRICKS_DOCKER_NAME),$(SIMBRICKS_DOCKER_IMAGE))

stop-simbricks-docker:
	$(call stop_container,$(SIMBRICKS_DOCKER_NAME))

.PHONY: build-ubuntu-docker start-ubuntu-docker stop-ubuntu-docker
build-ubuntu-docker: $(UBUNTU_DOCKER_FILE) 
	docker build -f $< -t $(UBUNTU_DOCKER_IMAGE) $(DOCKER_BUILD_DIR)

start-ubuntu-docker:
	$(call start_container,$(UBUNTU_DOCKER_NAME),$(UBUNTU_DOCKER_IMAGE))

stop-ubuntu-docker:
	$(call stop_container,$(UBUNTU_DOCKER_NAME))
