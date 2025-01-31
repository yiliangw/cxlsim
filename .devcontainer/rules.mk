COMPOSE_PROJECT_NAME ?= baize
CONTAINER_USER_NAME ?= $(USER)
CONTAINER_USER_UID ?= $(shell id -u)
CONTAINER_USER_GID ?= $(shell id -g)

$(d).env:
	echo "COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME)" > .devcontainer/.env
	echo "CONTAINER_USER_NAME=$(CONTAINER_USER_NAME)" >> .devcontainer/.env
	echo "CONTAINER_USER_UID=$(CONTAINER_USER_UID)" >> .devcontainer/.env
	echo "CONTAINER_USER_GID=$(CONTAINER_USER_GID)" >> .devcontainer/.env

$(d)verilator.patch: $(project_root)sim/simbricks/docker/verilator.patch
	cp $< $@

$(project_root)sim/simbricks/docker/verilator.patch:
	git submodule update --init --recursive sim/simbricks

docker_compose_yml := $(d)docker-compose.yml

devcontainer_deps := $(docker_compose_yml) $(d)Dockerfile.ubuntu $(d).env $(d)verilator.patch

.PHONY: devcontainer
devcontainer: $(devcontainer_deps)
	docker compose -f $(docker_compose_yml) build

.PHONY: run-devcontainer
run-devcontainer: $(devcontainer_deps)
	docker compose -f $(docker_compose_yml) run --rm -u$(CONTAINER_USER_NAME) ubuntu-dev bash
