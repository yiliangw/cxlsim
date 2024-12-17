DOCKER_WORKDIR := /workspace

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
