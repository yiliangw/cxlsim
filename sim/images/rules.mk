linux_src_dir := $(build_dir)linux-$(linux_version)/

.PHONY: build-linux
build-linux: $(vmlinuz)

$(vmlinuz): $(linux_src_dir)arch/x86/boot/bzImage
	mkdir -p $(@D)
	cp $< $@

$(linux_src_dir)arch/x86/boot/bzImage: $(dir)linux/config-$(linux_version) $(legoos_docker_ready) $(linux_src_dir) 
	mkdir -p $(linux_src_dir)
	cp $< $(linux_src_dir).config
	$(MAKE) start-container-legoos
	$(legoos_container_exec) "make -C$(container_root)$(linux_src_dir) -j$$(nproc)"
	$(MAKE) stop-docker-legoos

$(linux_src_dir): $(build_dir)linux-$(linux_version).tar.xz
	tar -xf $< -C $(shell dirname $@)
