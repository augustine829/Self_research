COMPONENT_TARGETS += $(TARGET_NAME_NOARCH)

COMPONENT_IS_3PP = true

SRC_DIR = RBTools-0.7.5
SRC_ARCHIVE = $(SRC_DIR).tar.gz

# This directory (containing a patched rbtools) is versioned so that users
# won't have to build anything after 'svn up':ing a devtools working copy.
# Any modification of rbtools should be done through patches as per usual.
versioned_build_result_dir = $(SRC_DIR)-prebuilt-DO_NOT_EDIT

PATCHES = patches

SETUP_TARGETS += .done
CLEANUP_FILES += .done

include ../../makesystem/common.mk

.done: $(SRC_ARCHIVE) $(PATCHES_DEP)
	$(UNPACK_SRC_ARCHIVE)
	$(APPLY_PATCHES)
	$(Q)rm -rf $(versioned_build_result_dir)
	$(Q)cp -r $(SRC_DIR) $(versioned_build_result_dir)
	$(Q)rm $(versioned_build_result_dir)/patches
	$(Q)touch $@
