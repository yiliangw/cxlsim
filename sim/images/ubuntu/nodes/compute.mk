$(b)compute1/input.tar: $(addprefix $(b)compute1/input/, $(ubuntu_common_input) install.sh chrony.conf \
	$(addprefix setup/, run.sh nova.sh nova.conf))
	mkdir -p $(@D)
	tar -C $(@D)/input -cf $@ .

$(b)compute1/input/%: $(d)input/compute/%
	mkdir -p $(@D)
	cp $< $@
$(b)compute1/input/%: $(d)input/common/%
	mkdir -p $(@D)
	cp $< $@
$(b)compute1/input/%: $(b)compute1.sed $(d)input/compute/%.tpl
	mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@
$(b)compute1/input/%: $(b)compute1.sed $(d)input/common/%.tpl
	mkdir -p $(@D)
	sed -f $(word 1, $^) $(word 2, $^) > $@
