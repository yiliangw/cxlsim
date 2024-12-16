SIMBRICKS_DOCKER_IMAGE := simbricks/simbricks-build
SIMBRICKS_DOCKER_NAME := baize_simbricks_build_

DOCKER_WORKDIR := /workspace

simbricks_docker_exec := docker exec $(SIMBRICKS_DOCKER_NAME) /bin/bash -c

define start_container # $(1) - container name, $(2) - image name
	$(call stop_container,$(1))
	docker run \
		--user $(shell id -u):$(shell id -g) \
		--rm -d -i --name $(1) \
		--mount type=bind,source=$(shell pwd),target=$(DOCKER_WORKDIR) \
		--workdir $(DOCKER_WORKDIR) \
		$(2)
endef


define stop_container
	@if docker ps -q -f name="^$(1)$$"; then \
		echo "Stopping container $(1)"; \
		docker rm -f $(1); \
	else \
		echo "Container $(1) not running"; \
	fi
endef

.PHONY: pull-simbricks-docker start-simbricks-docker stop-simbricks-docker

pull-simbricks-docker:
	docker pull $(SIMBRICKS_DOCKER_IMAGE)	

start-simbricks-docker:
	$(call start_container,$(SIMBRICKS_DOCKER_NAME),$(SIMBRICKS_DOCKER_IMAGE))

stop-simbricks-docker:
	$(call stop_container,$(SIMBRICKS_DOCKER_NAME))

