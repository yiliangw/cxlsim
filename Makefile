# output directory root
O ?= out
O := $(if $(filter %/,$(O)),$(O),$(O)/)

makefile_stack := $(lastword $(MAKEFILE_LIST))
# source directory
d = $(dir $(lastword $(makefile_stack)))
# output directory
o = $(O)$(d)
# build directory
b = $(o)build/

ALL_ALL :=
CLEAN_ALL := 
EXTERNAL_CLEAN_ALL := 

.PHONY: all
all: $(ALL_ALL)
	@echo "Hello Baize :)"

.PHONY: clean
clean: 
	rm -rf $(CLEAN_ALL)

.PHONY: clean-external
clean-external: $(EXTERNAL_CLEAN_ALL)

define include_rules
	$(eval rules := $(d)$(1))
	$(eval makefile_stack := $(makefile_stack) $(rules))
	$(eval include $(rules))
	$(eval makefile_stack := $(wordlist 1,$(shell echo $$(($(words $(makefile_stack))-1))),$(makefile_stack)))
endef

$(call include_rules,docker/rules.mk)
$(call include_rules,sim/rules.mk)
