simbricks_run_script := $(simbricks_dir)experiments/run.py

SIMBRICKS_OPTIONS := --repo $(simbricks_dir) --workdir $(o) --outdir $(o) --cpdir $(o) --runs 1 --verbose \
	--parallel --force

sim_lib_files := $(filter-out %__pycache__/%,$(wildcard $(d)lib/**/*))
sim_common_deps := $(sim_lib_files) $(simbricks_run_script) $(config_yaml)

.PHONY: simbricks-build
simbricks-build: $(d)gem5_kvm.patch $(simbricks_dir) $(simbricks_dir)sims/external/gem5 $(simbricks_dir)sims/external/qemu
	patch -d $(simbricks_dir)sims/external/gem5 -p1 -N -r/dev/null < $< || true
	make -C $(simbricks_dir) -j`nproc` all sims/external/qemu/ready sims/external/gem5/ready
	make -C $(simbricks_dir) -j`nproc` build-images-min convert-images-raw

.PHONY: simbricks-clean
simbricks-clean:
	$(MAKE) -C $(simbricks_dir) clean-all

TS_FORMAT := "[%T]"
TS_PIPE := | ts $(TS_FORMAT)

$(o)%.log: $(d)exps/%.py $(simbricks_run_script) $(sim_lib_files) $(config_yaml) | $(o)
	python $(simbricks_run_script) $< $(SIMBRICKS_OPTIONS) 2>&1 $(TS_PIPE) | tee $@

.PHONY: run-simple-ping
run-simple-ping: $(o)simple_ping.log

.PHONY: run-ubuntu-mysql
run-ubuntu-mysql: $(o)ubuntu_mysql.log

$(o)ubuntu_mysql.log: $(d)exps/ubuntu_mysql.yaml \
	$(ubuntu_dimg_o)gateway_phase1/disk.qcow2 $(ubuntu_dimg_o)gateway_phase1/disk.raw $(ubuntu_input_tar_o)gateway_phase2.tar $(ubuntu_install_script_o)gateway_phase2.sh \
	$(ubuntu_dimg_o)controller_phase1/disk.qcow2 $(ubuntu_dimg_o)controller_phase1/disk.raw $(ubuntu_input_tar_o)controller_phase2.tar $(ubuntu_install_script_o)controller_phase2.sh \
	$(ubuntu_dimg_o)compute1_phase1/disk.qcow2 $(ubuntu_dimg_o)compute1_phase1/disk.raw  $(ubuntu_input_tar_o)compute1_phase2.tar $(ubuntu_install_script_o)compute1_phase2.sh \
	$(ubuntu_vmlinux) $(ubuntu_initrd)

.PHONY: run-ubuntu-ssh
run-ubuntu-ssh: $(o)ubuntu_ssh.log

$(o)ubuntu_ssh.log: $(ubuntu_dimg_o)base/disk.qcow2 $(ubuntu_dimg_o)base/disk.raw $(ubuntu_vmlinux) $(ubuntu_initrd)
