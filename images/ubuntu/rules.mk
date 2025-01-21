UBUNTU_ISO_URL := https://cloud-images.ubuntu.com/daily/server/jammy/20241217/jammy-server-cloudimg-amd64.img
UBUNTU_ISO_CKSUM_URL := https://cloud-images.ubuntu.com/daily/server/jammy/20241217/SHA256SUMS

UBUNTU_ROOT_DISK_SZ := 250G
UBUNTU_SECONDARY_DISK_SZ := 250G


# Disk images output directory
ubuntu_dimg_o := $(o)disks/
ubuntu_dimgs :=

$(eval $(call include_rules,$(d)base/rules.mk))
$(eval $(call include_rules,$(d)hosts/rules.mk))

.PRECIOUS: $(ubuntu_dimgs)
