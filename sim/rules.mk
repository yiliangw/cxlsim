simbricks_run_script := $(simbricks_dir)experiments/run.py

SIMBRICKS_OPTIONS := --repo $(simbricks_dir) --workdir $(o) --outdir $(o) --cpdir $(o) --runs 1 --verbose \
	--parallel --force

sim_lib_files := $(filter-out %__pycache__/%,$(wildcard $(d)exps/lib/**/*))
sim_common_deps := $(sim_lib_files) $(simbricks_run_script) $(config_yaml)

.PHONY: build-simbricks
build-simbricks: $(simbricks_dir) $(simbricks_dir)sims/external/gem5
	make -C $(simbricks_dir) -j`nproc` all sims/external/gem5/ready

.PHONY: clean-simbricks
clean-simbricks:
	$(MAKE) -C $(simbricks_dir) clean-all

TS_FORMAT := "[%T]"
TS_PIPE := | ts $(TS_FORMAT)

define exp_rules	# $1: experiment name; $2: dependencies 
$(o)$(1).log: $(d)exps/$(1).py $(simbricks_run_script) $(sim_lib_files) $(config_yaml) $(2)
	@mkdir -p $$(@D)
	PYTHONPATH=$(d)exps/:$${PYTHONPATH} python $(simbricks_run_script) $$< $(SIMBRICKS_OPTIONS) 2>&1 $(TS_PIPE) | tee $$@

.PHONY: run-exp-$(1)
run-exp-$(1): $(o)$(1).log

.PHONY: clean-exp-$(1)
clean-exp-$(1):
	rm -rf $(o)$(1).log
endef

$(eval $(call exp_rules,single_host,$(ubuntu_vmlinux) $(ubuntu_initrd) ubuntu-raw-mysql/basic))
$(eval $(call exp_rules,mysql_basic,$(d)exps/mysql_basic.yaml $(ubuntu_vmlinux) $(ubuntu_initrd) ubuntu-raw-mysql/basic))
