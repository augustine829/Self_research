ifndef COMMON_MK
  $(error toolchains.mk is expected to be included after common.mk)
endif

# This is set to false in source kits (e.g. HDK).
__install_toolchains = true

ifeq ($(__install_toolchains),true)
  .setup: $(__toolchains_to_install)
endif

define __toolchain_install_template
CLEANUP_FILES += $(MAKESYSTEM)/toolchains/$(subst /,_,$(subst $(KREATV_DIR)/,,$(1))).tar.bz2
$(1):
	archive=$(MAKESYSTEM)/toolchains/$(subst /,_,$(subst $(KREATV_DIR)/,,$(1))).tar.bz2 && \
	  $(PRINT_PROGRESS) GET_BINARY $$$$archive && \
	  $(MAKESYSTEM)/binary_file get $$$$archive && \
	  $(MAKESYSTEM)/install_toolchain $$$$archive
endef

$(foreach toolchain_path,$(__toolchains_to_install),\
  $(eval $(call __toolchain_install_template,$(toolchain_path))))
