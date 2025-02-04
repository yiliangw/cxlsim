simbricks_run_script := $(simbricks_dir)experiments/run.py

SIMBRICKS_OPTIONS := --repo $(simbricks_dir) --workdir $(o) --outdir $(o) --cpdir $(o) --runs 1 --verbose --force

sim_lib_files := $(filter-out %__pycache__/%,$(wildcard $(d)lib/**/*))
sim_common_deps := $(sim_lib_files) $(simbricks_run_script) $(config_yaml)

.PHONY: build-simbricks
build-simbricks:
	make -C $(simbricks_dir) -j`nproc` all sims/external/qemu/ready sims/external/ns-3/ready sims/external/gem5/ready
	make -C $(simbricks_dir) -j`nproc` build-images-min convert-images-raw

.PHONY: exp-simple-ping
exp-simple-ping: $(o)simple_ping.log

$(o)simple_ping.log: $(d)exps/simple_ping.py $(sim_common_deps)
	python $(simbricks_run_script) $(SIMBRICKS_OPTIONS) $< 2>&1 | tee $@

.PHONY: exp-ubuntu
exp-ubuntu: $(o)ubuntu.log

$(o)ubuntu.log: $(d)exps/ubuntu.py $(ubuntu_dimg_o)base/disk.raw $(ubuntu_vmlinux) $(sim_common_deps)
	python $(simbricks_run_script) $< $(SIMBRICKS_OPTIONS) 2>&1 | tee $@
