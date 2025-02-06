# output directory 
O ?= out/
# build directory
B ?= $(O)build/

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

.PHONY: help
help:
	@echo "Hello Baize :)"

simbricks_dir := $(d)sim/simbricks/

$(eval $(call include_rules,$(d).devcontainer/rules.mk))
$(eval $(call include_rules,$(d)config/rules.mk))
$(eval $(call include_rules,$(d)utils/rules.mk))
$(eval $(call include_rules,$(d)images/rules.mk))
$(eval $(call include_rules,$(d)sim/rules.mk))

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

