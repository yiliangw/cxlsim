# output directory 
O ?= out/
B ?= build/

O := $(if $(filter %/,$(O)),$(O),$(O)/)
B := $(if $(filter %/,$(B)),$(B),$(B)/)

d := ./
o := $(O)
b := $(B)
project_root := $(d)

current_makefile := $(firstword $(MAKEFILE_LIST))
makefile_stack := $(current_makefile)

define update_current_makefile
	$(eval current_makefile := $(firstword $(makefile_stack)))
	$(eval d := $(dir $(current_makefile)))
	$(eval o := $(subst /.,,$(O)$(d)))
	$(eval b := $(subst /.,,$(B)$(d)))
endef

PREPARE_ALL :=
ALL_ALL :=
CLEAN_ALL := 
EXTERNAL_CLEAN_ALL := 
INPUT_TAR_ALL :=

define include_rules
	$(eval makefile_stack := $(1) $(makefile_stack))
	$(eval $(call update_current_makefile))
	$(eval include $(1))
	$(eval makefile_stack := $(wordlist 2, $(words $(makefile_stack)),$(makefile_stack)))
	$(eval $(call update_current_makefile))
endef

include arch_arm.mk

.PHONY: help
help:
	@echo "Hello CXLSim"

simbricks_dir := $(d)sim/simbricks/

$(eval $(call include_rules,$(d).devcontainer/rules.mk))
$(eval $(call include_rules,$(d)configs/rules.mk))
$(eval $(call include_rules,$(d)utils/rules.mk))
$(eval $(call include_rules,$(d)images/rules.mk))
$(eval $(call include_rules,$(d)sim/rules.mk))

.PHONY: install-dependencies
install-dependencies:
	sudo apt-get update && sudo apt-get install -y \
		build-essential libpcap-dev libboost-dev libboost-fiber-dev \
		libboost-iostreams-dev libboost-coroutine-dev \
		qemu-system-x86 guestfish cloud-image-utils \
		scons m4 scons zlib1g zlib1g-dev libprotobuf-dev protobuf-compiler \
		libprotoc-dev libgoogle-perftools-dev \
		moreutils \
		libglib2.0-dev libpixman-1-dev ninja-build \
		libelf-dev \
		unzip \
		qemu-system-aarch64 qemu-efi-aarch64
	sudo sysctl -w kernel.perf_event_paranoid=0
	$(MAKE) $(INSTALL_DEPS_ALL)

.PHONY: all
all: $(ALL_ALL)

.PRECIOUS: $(INPUT_TAR_ALL)
.PHONY: input
input: $(INPUT_TAR_ALL)

.PHONY: clean
clean: 
	rm -rf $(CLEAN_ALL)

.PHONY: clean-external
clean-external: $(EXTERNAL_CLEAN_ALL)

$(o)%/ $(b)%/:
	mkdir -p $@

