COMPONENT_TARGETS += $(TARGET_NAME_NOARCH)
COMPONENT_IS_3PP = true

version = 36a0f44c54ee6301a5a208a12c08f97e59fcaa42
SRC_ARCHIVE = uncrustify-$(version).tar.gz
SRC_DIR = uncrustify-$(version)

SETUP_TARGETS += $(SRC_DIR)/.done
BIN_TARGETS += $(SRC_DIR)/src/uncrustify
PATCHES = patches

include ../../makesystem/common.mk

$(SRC_DIR)/.done: $(SRC_ARCHIVE) $(PATCHES_DEP)
	$(UNPACK_SRC_ARCHIVE)
	$(APPLY_PATCHES)
	$(Q)touch $@

$(BIN_TARGETS): $(SRC_DIR)/.done
	$(Q)cd $(SRC_DIR) && CXXFLAGS=-m32 ./configure
	$(Q)$(BSG_DEVSETUP) $(MAKE) -C $(SRC_DIR)

install_prebuilt:
	cp $(SRC_DIR)/src/uncrustify uncrustify_prebuilt
	strip uncrustify_prebuilt
