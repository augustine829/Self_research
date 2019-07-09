#
# Build macros, see makesystem/doc/README.mmd for documentation
#

### Sanity checks

ifdef COMMON_MK
$(error Do not include common.mk if using build.mk)
endif

ifdef SRCS
$(error Do not set SRCS when using build.mk)
endif

ifdef BIN_TARGETS
$(error Use BUILD_BIN instead of BIN_TARGETS when using build.mk)
endif

ifdef LIB_TARGETS
$(error Use BUILD_LIB_SO or BUILD_LIB_A instead of LIB_TARGETS when using build.mk)
endif

ifdef IIP_NAME
$(error Use BUILD_IIP instead of IIP_NAME when using build.mk)
endif

### Setup targets before including common.mk

# (name, sources)
define __build_bin_setup
BUILD_BIN_TARGET_$(1) = $$(TARGET_OBJS_DIR)/$(1)
BIN_TARGETS += $$(BUILD_BIN_TARGET_$(1))
SRCS += $(2)
_bin_$(1)_objs = $(patsubst %,$$(TARGET_OBJS_DIR)/%.o,$(basename $(2)))
endef

# (name, lc_suffix, uc_suffix, sources)
define __build_lib_setup
BUILD_LIB_$(3)_TARGET_$(1) = $$(TARGET_OBJS_DIR)/lib$(1).$(2)
LIB_TARGETS += $$(BUILD_LIB_$(3)_TARGET_$(1))
SRCS += $(4)
_lib_$(2)_$(1)_objs = $(patsubst %,$$(TARGET_OBJS_DIR)/%.o,$(basename $(4)))
endef

# (name, sources)
define __build_test_setup
BUILD_TEST_TARGET = $$(TARGET_OBJS_DIR)/$(1)
TEST_TARGETS += $$(BUILD_TEST_TARGET)
SRCS += $(2)
_bin_$(1)_objs = $(patsubst %,$$(TARGET_OBJS_DIR)/%.o,$(basename $(2)))
endef

# (name)
define __build_bin_link
$$(TARGET_OBJS_DIR)/$(1): $$(_bin_$(1)_objs)
	$$(LINK)
endef

# (name, test_srcs)
define __build_test_bin_link
# Disable optimization of unit tests to get a shorter turn-around time when
# developing tests.
$$(patsubst %,$$(TARGET_OBJS_DIR)/%.o,$$(basename $(2))): OPTIMIZATION_FLAGS =
$(eval $(call __build_bin_link,$(1)))
endef


__ver := -Wl,--version-script

# (name, ver)
define __build_so_lib_link
$$(BUILD_LIB_SO_TARGET_$(1)): $$(_lib_so_$(1)_objs) $(2)
	$$(LINK_SO) $(if $(2),$(__ver)=$(2))
endef

# (name)
define __build_a_lib_link
$$(BUILD_LIB_A_TARGET_$(1)): $$(_lib_a_$(1)_objs)
	$$(LINK_A)
endef

# (name, suffix)
define __build_iip_setup
iip_noarch$(strip $(2)) = $$(findstring $$(TOOLCHAIN),$$(STB_NOARCH_TOOLCHAIN_NAME))
iip_dir$(strip $(2)) = $$(if $$(iip_noarch$(strip $(2))),.,$$(TARGET_OBJS_DIR))
iip_depend$(strip $(2)) = $$(iip_dir$(strip $(2)))/.install_depends$(strip $(2))
iip_version$(strip $(2)) = $$(subst _,-,$$(BSG_BUILD_VERSION))
iip_target$(strip $(2)) = $$(iip_dir$(strip $(2)))/$(1)_$$(if $$(BUILD_IIP_INTERNAL_USE_ONLY),INTERNAL-USE-ONLY_)$$(iip_version$(strip $(2)))$$(if $$(iip_noarch$(strip $(2))),,_$$(TOOLCHAIN))$$(if $$(DEVICE),_$$(DEVICE)).iip
iip_ext_info$(strip $(2)) = $$(iip_target$(strip $(2))).iipinfo

BUILD_IIP_ARCHIVE = $$(iip_target$(strip $(2)))
PRODUCT_TARGETS += $$(iip_target$(strip $(2)))
CLEANUP_FILES += .install_depends* $(1)_*.iip
endef

# (name, install, description, flags, suffix, install_kit)
define __build_iip_no_dist
$$(iip_target$(strip $(5))): $(2) $(3) $(6)
	$$(DIST_DIR)/bin/iip_build \
	  --name $(1) \
	  --version $$(iip_version$(strip $(5))) \
	  --branch $$(BSG_BUILD_BRANCH) \
	  --date $$(BSG_BUILD_DATE) \
	  --time $$(BSG_BUILD_TIME) \
	  --external_iip_info $$(iip_ext_info$(strip $(5))) \
	  $$(if $$(iip_noarch$(strip $(5))),,--toolchain $$(TOOLCHAIN)) \
	  $$(if $$(DEVICE), --device $$(DEVICE)) \
	  $$(if $(3),--description $(3)) \
	  $$(if $(2),--install buildtime:$(strip $(2))) \
	  --install kit:$(strip $(6)) \
	  --out_dir $$(if $$(iip_noarch$(strip $(5))),.,$$(TARGET_OBJS_DIR)) \
	  $$(addprefix --depends ,$$(IIP_DEPENDS$(strip $(5)))) \
	  $(4)
	$$(MAKESYSTEM)/dist_targets $$(iip_ext_info$(strip $(5))) $$(DIST_DIR)/products
	rm -rf $$(iip_ext_info$(strip $(5)))
endef

# (name, dist, install, description, flags, suffix, deps, install_kit)
define __build_iip
-include $$(iip_depend$(strip $(6)))
$$(iip_target$(strip $(6))): $(2) $(3) $(4) $(7) $(8)
	$$(DIST_DIR)/bin/iip_dist_build \
	  --name $(1) \
	  --version $$(iip_version$(strip $(6))) \
	  --branch $$(BSG_BUILD_BRANCH) \
	  --date $$(BSG_BUILD_DATE) \
	  --time $$(BSG_BUILD_TIME) \
	  --external_iip_info $$(iip_ext_info$(strip $(6))) \
	  $$(if $$(iip_noarch$(strip $(6))),,--toolchain $$(TOOLCHAIN)) \
	  --source $$(if $$(BUILD_IIP_SOURCE),$$(BUILD_IIP_SOURCE),$$(DIST_DIR)) \
	  --dist $(2) \
	  $$(if $$(DEVICE), --device $$(DEVICE)) \
	  $$(if $(4),--description $(4)) \
	  $$(addprefix --depends ,$$(IIP_DEPENDS$(strip $(6)))) \
	  $$(if $(3),--install buildtime:$(strip $(3))) \
	  --install kit:$(strip $(8)) \
	  --out_dir $$(if $$(iip_noarch$(strip $(6))),.,$$(TARGET_OBJS_DIR)) \
	  --dep_name $$@ \
	  --dep_file $$(iip_depend$(strip $(6))) \
	  $$(if $$(iip_noarch$(strip $(6))),,--var toolchain $$(TOOLCHAIN)) \
	  $$(if $$(iip_noarch$(strip $(6))),,--var toolchaindevice $$(TOOLCHAIN)$$(if $$(DEVICE),/$$(DEVICE))) \
	  --var device $$(if $$(DEVICE),$$(DEVICE), none) \
	  --var sysroot $$(TOOLCHAIN_PATH)/$$(TARGET_ARCH)/sys-root \
	  --var dist $$(DIST_DIR_ABS) \
	  --var dist_dir $$(DIST_DIR_ABS) \
	  --var config $$(DIST_DIR_ABS)/config \
	  --var scripts $$(DIST_DIR_ABS)/bin \
	  $$(if $$(OBJCOPY),--objcopy "$$(DIST_DIR_ABS)/bin/objcopy_tree $$(OBJCOPY)") \
	  $$(if $$(STRIP),--strip "$$(DIST_DIR_ABS)/bin/strip_tree $$(STRIP)") \
	  $(5)
	$$(MAKESYSTEM)/dist_targets --rename $$(iip_depend$(strip $(6))) $$(DIST_DIR)/iipdepfiles/$$(__slashless_component)@$(strip $(6))_$$(TARGET)_$$(FLAVOUR)
	$$(MAKESYSTEM)/dist_targets $$(iip_ext_info$(strip $(6))) $$(DIST_DIR)/products
	rm -rf $$(iip_ext_info$(strip $(6)))
endef

# (name, install, description, flags, suffix, install_kit, doc_build_dir)
define __build_iip_doc
$$(if $$(TARGET_OBJS_DIR),$$(shell mkdir -p $(7)))
$$(iip_target$(strip $(5))): $(2) $(3) $(6) $$(BUILD_DOCPART_LOCAL_INSTALL)
	$$(DIST_DIR)/bin/iip_data_build \
	  --name $(1) \
	  --version $$(iip_version$(strip $(5))) \
	  --branch $$(BSG_BUILD_BRANCH) \
	  --date $$(BSG_BUILD_DATE) \
	  --time $$(BSG_BUILD_TIME) \
	  --external_iip_info $$(iip_ext_info$(strip $(5))) \
	  $$(if $$(iip_noarch$(strip $(5))),,--toolchain $$(TOOLCHAIN)) \
	  $$(if $$(DEVICE), --device $$(DEVICE)) \
	  $$(if $(3),--description $(3)) \
	  $$(if $(2),--install buildtime:$(strip $(2))) \
	  --install kit:$(strip $(6)) \
	  --out_dir $$(if $$(iip_noarch$(strip $(5))),.,$$(TARGET_OBJS_DIR)) \
	  --data_build_dir $(7) \
	  $$(addprefix --depends ,$$(IIP_DEPENDS$(strip $(5)))) \
	  $(4)
	$$(MAKESYSTEM)/dist_targets $$(iip_ext_info$(strip $(5))) $$(DIST_DIR)/products
	rm -rf $$(iip_ext_info$(strip $(5)))
endef

# (name, install, description, flags, suffix, install_kit, data_build_dir)
define __build_iip_data_build
$$(if $$(TARGET_OBJS_DIR),$$(shell mkdir -p $(7)))
$$(iip_target$(strip $(5))): $(2) $(3) $(6)
	$$(DIST_DIR)/bin/iip_data_build \
	  --name $(1) \
	  --version $$(iip_version$(strip $(5))) \
	  --branch $$(BSG_BUILD_BRANCH) \
	  --date $$(BSG_BUILD_DATE) \
	  --time $$(BSG_BUILD_TIME) \
	  --external_iip_info $$(iip_ext_info$(strip $(5))) \
	  $$(if $$(iip_noarch$(strip $(5))),,--toolchain $$(TOOLCHAIN)) \
	  $$(if $$(DEVICE), --device $$(DEVICE)) \
	  $$(if $(3),--description $(3)) \
	  $$(if $(2),--install buildtime:$(strip $(2))) \
	  --install kit:$(strip $(6)) \
	  --out_dir $$(if $$(iip_noarch$(strip $(5))),.,$$(TARGET_OBJS_DIR)) \
	  --data_build_dir $(7) \
	  $$(addprefix --depends ,$$(IIP_DEPENDS$(strip $(5)))) \
	  $(4)
	$$(MAKESYSTEM)/dist_targets $$(iip_ext_info$(strip $(5))) $$(DIST_DIR)/products
	rm -rf $$(iip_ext_info$(strip $(5)))
endef

# Function for expanding * but not checking for existence otherwise, useful
# when explicit files are generated.
__expand = $(foreach s,$(1),$(if $(findstring *,$(s)),$(wildcard $(s)),$(s)))


BUILD_BIN_SRCS := $(call __expand,$(BUILD_BIN_SRCS))
$(foreach b,$(BUILD_BINS),$(eval BUILD_BIN_SRCS_$(b) := $(call __expand,$(BUILD_BIN_SRCS_$(b)))))
BUILD_LIB_SRCS := $(call __expand,$(BUILD_LIB_SRCS))
$(foreach l,$(BUILD_LIBS_SO),$(eval BUILD_LIB_SRCS_$(l) := $(call __expand,$(BUILD_LIB_SRCS_$(l)))))
$(foreach l,$(BUILD_LIBS_A),$(eval BUILD_LIB_SRCS_$(l) := $(call __expand,$(BUILD_LIB_SRCS_$(l)))))

BUILD_TEST_SRCS := $(call __expand,$(BUILD_TEST_SRCS))
ifneq ($(strip $(BUILD_TEST_SRCS)),)
__build_test_other_srcs += $(BUILD_BIN_SRCS) $(BUILD_LIB_SRCS)
__build_test_other_srcs += $(foreach b,$(BUILD_BINS), $(BUILD_BIN_SRCS_$(b)))
__build_test_other_srcs += $(foreach l,$(BUILD_LIBS_SO), $(BUILD_LIB_SRCS_$(l)))
__build_test_other_srcs += $(foreach l,$(BUILD_LIBS_A), $(BUILD_LIB_SRCS_$(l)))
__build_test_other_srcs := $(filter-out main.%,$(__build_test_other_srcs))
$(foreach p,$(call __expand,$(BUILD_TEST_EXCLUDE)), \
  $(eval BUILD_TEST_SRCS := $(filter-out $(p),$(BUILD_TEST_SRCS))) \
  $(eval __build_test_other_srcs := $(filter-out $(p),$(__build_test_other_srcs))))
__build_test_bin_name := unittest
endif


# IIP parts

ifdef BUILD_IIP_DOC
BUILD_IIP=$(BUILD_IIP_DOC)
BUILD_IIP_DOC_BUILD_DIR = .build
endif

ifdef BUILD_IIP

ifndef BUILD_IIP_KIT_INSTALL
$(error When using BUILD_IIP set BUILD_IIP_KIT_INSTALL to the kit script)
endif

ifdef TOOLCHAIN
ifndef BUILD_IIP_DESCRIPTION
$(error When using BUILD_IIP set BUILD_IIP_DESCRIPTION to description xml file, eg description.xml)
endif
ifndef BUILD_IIP_DOC
ifndef BUILD_IIP_DIST
$(error When using BUILD_IIP set BUILD_IIP_DIST to dist file, or use $$(empty) if no dist is needed)
endif
endif # BUILD_IIP_DOC
endif # TOOLCHAIN

BUILD_IIP_DATA_BUILD_DIR = $(TARGET_OBJS_DIR)/.build

ifdef BUILD_IIP_INTERNAL_USE_ONLY
BUILD_IIP_FLAGS += --internal_use_only
endif
ifdef BUILD_IIP_CAPABILITIES
BUILD_IIP_FLAGS += $(addprefix --provides_capability ,$(BUILD_IIP_CAPABILITIES))
endif
ifdef BUILD_IIP_CONTENT_VERSION
BUILD_IIP_FLAGS += --content_version $(BUILD_IIP_CONTENT_VERSION)
endif
ifdef BUILD_IIP_VARS
BUILD_IIP_FLAGS += $(foreach v,$(BUILD_IIP_VARS),--var $(subst =, ,$(v)))
endif

endif # BUILD_IIP


# (var, source var name)
define __checksrc
$(if $($(2)),,$(error When using $(1) set $(2) to sources))
endef

ifdef BUILD_BIN
$(call __checksrc,BUILD_BIN,BUILD_BIN_SRCS)
$(eval $(call __build_bin_setup,$(BUILD_BIN),$(BUILD_BIN_SRCS)))
BUILD_BIN_TARGET = $(TARGET_OBJS_DIR)/$(BUILD_BIN)
endif

$(foreach b,$(BUILD_BINS), \
  $(call __checksrc,BUILD_BINS,BUILD_BIN_SRCS_$(b)))
$(foreach b,$(BUILD_BINS), \
  $(eval $(call __build_bin_setup,$(b),$(BUILD_BIN_SRCS_$(b)))))

ifdef BUILD_LIB_SO
$(call __checksrc,BUILD_LIB_SO,BUILD_LIB_SRCS)
$(eval $(call __build_lib_setup,$(BUILD_LIB_SO),so,SO,$(BUILD_LIB_SRCS)))
BUILD_LIB_SO_TARGET = $(TARGET_OBJS_DIR)/lib$(BUILD_LIB_SO).so
endif

$(foreach l,$(BUILD_LIBS_SO), \
  $(call __checksrc,BUILD_LIBS_SO,BUILD_LIB_SRCS_$(l)))
$(foreach l,$(BUILD_LIBS_SO), \
  $(eval $(call __build_lib_setup,$(l),so,SO,$(BUILD_LIB_SRCS_$(l)))))

ifdef BUILD_LIB_A
$(call __checksrc,BUILD_LIB_A,BUILD_LIB_SRCS)
$(eval $(call __build_lib_setup,$(BUILD_LIB_A),a,A,$(BUILD_LIB_SRCS)))
BUILD_LIB_A_TARGET = $(TARGET_OBJS_DIR)/lib$(BUILD_LIB_A).a
endif

$(foreach l,$(BUILD_LIBS_A), \
  $(call __checksrc,BUILD_LIBS_A,BUILD_LIB_SRCS_$(l)))
$(foreach l,$(BUILD_LIBS_A), \
  $(eval $(call __build_lib_setup,$(l),a,A,$(BUILD_LIB_SRCS_$(l)))))

ifdef __build_test_bin_name
$(eval $(call __build_test_setup,$(__build_test_bin_name),$(BUILD_TEST_SRCS) $(__build_test_other_srcs)))
endif

ifdef BUILD_IIP
$(eval $(call __build_iip_setup,$(BUILD_IIP)))
endif


# Documentation parts

ifdef BUILD_IIP_DOC

ifndef BUILD_IIP_DOC_BUILD_DIR
$(error Required variable BUILD_IIP_DOC_BUILD_DIR is empty)
endif
CLEANUP_FILES += $(BUILD_IIP_DOC_BUILD_DIR)

__build_docpart_name = $(subst kreatv-doc-,,$(BUILD_IIP_DOC))
__build_docpart_manual_parts_bsgdir = manuals/parts
__build_docpart_manual_tools_bsgdir = manuals/tools
BUILD_DOCPART_LOCAL_INSTALL = .docdist
CLEANUP_FILES += $(BUILD_DOCPART_LOCAL_INSTALL)

# Doc parts automatically include static files in the directory "files"
__build_docpart_static_files = $(shell find files -path '*/.svn' -prune -o -type f -print 2>/dev/null)
__build_docpart_static_files += $(wildcard toc_*.json)


# Doxygen variables
__build_docpart_mandatory_doxy_vars = BUILD_DOCPART_DOXY_INPUT_FILES BUILD_DOCPART_DOXY_TAB
BUILD_DOCPART_DOCDIST_DIR = $(BUILD_IIP_DOC_BUILD_DIR)/$(__build_docpart_manual_parts_bsgdir)/$(__build_docpart_name)/$(BUILD_DOCPART_LOCAL_INSTALL)
BUILD_DOCPART_TOC_FILE = $(BUILD_DOCPART_DOCDIST_DIR)/toc_$(__build_docpart_name).json

$(foreach part,$(BUILD_DOCPART_DOXY_PARTS), \
  $(foreach variable_prefix,$(__build_docpart_mandatory_doxy_vars), \
    $(if $(value $(variable_prefix)_$(part)),, \
      $(error $(part) is in BUILD_DOCPART_DOXY_PARTS, but $(variable_prefix)_$(part) is empty))))


BUILD_DOCPART_TOOLS_DIR = $(DIST_DIR)/doc/$(__build_docpart_manual_tools_bsgdir)

ifdef BUILD_DOCPART_DOXY_PARTS
__build_docpart_doxy_common = $(BUILD_DOCPART_TOOLS_DIR)/doxygen
CLEANUP_FILES += .build_docpart_doxy_*.conf
CLEANUP_FILES += .build_docpart_doxy_*.html
endif

# (doxygen part name)
define __build_docpart_doxy_vars_setup
__build_docpart_doxy_conf_$(1) = .build_docpart_doxy_$(1).conf
__build_docpart_doxy_header_$(1) = .build_docpart_doxy_header_$(1).html
BUILD_DOCPART_DOXY_HTML_DIR_$(1) = $(BUILD_DOCPART_DOCDIST_DIR)/$$(BUILD_DOCPART_DOXY_TAB_$(1))/$(1)
__build_docpart_archive_contents += $$(BUILD_DOCPART_DOXY_HTML_DIR_$(1))
endef

define __build_docpart_create_doxy_header_rule
$$(__build_docpart_doxy_header_$(1)): $$(__build_docpart_doxy_common)/header.html
	sed 's/%DEPENDENCIES%/@dependencies=$$(BUILD_DOCPART_DOXY_DEPS_$(1))/' $$< > $$@
endef

# (doxygen part name)
define __build_docpart_create_doxy_conf_rule
$$(__build_docpart_doxy_conf_$(1)): $$(BUILD_DOCPART_DOXY_INPUT_FILES_$(1)) $$(__build_docpart_doxy_header_$(1))
	mkdir -p $(DOC_EXAMPLE_DIST_DIR)
	echo "INPUT = $$(BUILD_DOCPART_DOXY_INPUT_FILES_$(1))" > $$@
	if [ "$$(BUILD_DOCPART_DOXY_IMAGE_DIRS_$(1))" != "" ]; then \
	  echo "IMAGE_PATH = $$(BUILD_DOCPART_DOXY_IMAGE_DIRS_$(1))" >> $$@; \
	fi
	echo "HTML_OUTPUT = $$(BUILD_DOCPART_DOXY_HTML_DIR_$(1))" >> $$@
	echo "HTML_HEADER = $$(__build_docpart_doxy_header_$(1))" >> $$@
	echo "HTML_FOOTER = $(__build_docpart_doxy_common)/footer.html" >> $$@
	echo "LAYOUT_FILE = $(__build_docpart_doxy_common)/DoxygenLayout.xml" >> $$@
	echo "GENERATE_LATEX = NO" >> $$@
	echo "WARN_IF_UNDOCUMENTED = NO" >> $$@
	echo "SEARCHENGINE = NO" >> $$@
	echo 'DISABLE_INDEX = YES' >> $$@
	echo 'SHOW_USED_FILES = NO' >> $$@
	echo 'GENERATE_TODOLIST = NO' >> $$@
	echo 'ALIASES += "techpreview=\xrefitem techpreviews \"Technical Preview\" \"Technical Previews\""' >> $$@
	echo "EXAMPLE_PATH = $(DOC_EXAMPLE_DIST_DIR)" >> $$@
endef

# (doxygen part name)
define __build_docpart_create_run_doxygen_rule
$$(BUILD_DOCPART_DOXY_HTML_DIR_$(1)): $$(__build_docpart_doxy_conf_$(1))
	mkdir -p $$@
	$$(Q)$$(DOXYGEN) $$(__build_docpart_doxy_conf_$(1)) >/dev/null
	$(__build_docpart_doxy_common)/fix-all-filenames.sh $$@
	$(__build_docpart_doxy_common)/remove-unused.sh $$@
endef


# (component relative file path)
define __build_docpart_create_static_file_target
__build_docpart_archive_contents += $$(BUILD_IIP_DOC_BUILD_DIR)/$$(__build_docpart_manual_parts_bsgdir)/$$(__build_docpart_name)/$(1)
$$(BUILD_IIP_DOC_BUILD_DIR)/$$(__build_docpart_manual_parts_bsgdir)/$$(__build_docpart_name)/$(1): $(1)
	mkdir -p $$(dir $$@)
	cp $$^ $$@
endef

endif # BUILD_IIP_DOC

# Always preserve source for developer files
ifeq ($(DOC_PATH),dev)
  DOC_PRESERVE_SOURCE_DIR = true
endif

### Include common.mk

include $(subst build,common,$(lastword $(MAKEFILE_LIST)))


### Rules

$(foreach b,$(BUILD_BINS), \
  $(eval $(call __build_bin_link,$(b))))

ifdef BUILD_BIN
$(eval $(call __build_bin_link,$(BUILD_BIN)))
endif

ifdef BUILD_LIB_A
$(eval $(call __build_a_lib_link,$(BUILD_LIB_A)))
endif

$(foreach l,$(BUILD_LIBS_A), \
  $(eval $(call __build_a_lib_link,$(l))))

ifdef BUILD_LIB_SO
$(eval $(call __build_so_lib_link,$(BUILD_LIB_SO),$(BUILD_LIB_VER)))
endif

$(foreach l,$(BUILD_LIBS_SO), \
  $(eval $(call __build_so_lib_link,$(l),$(BUILD_LIB_VER_$(l)))))

ifdef __build_test_bin_name
_bin_$(__build_test_bin_name)_objs += $(MOCK_OBJS)
$(eval $(call __build_test_bin_link,$(__build_test_bin_name),$(BUILD_TEST_SRCS)))
endif


ifdef BUILD_IIP_DOC

$(foreach part,$(BUILD_DOCPART_DOXY_PARTS), \
  $(eval $(call __build_docpart_doxy_vars_setup,$(part))))

$(foreach part,$(BUILD_DOCPART_DOXY_PARTS), \
  $(eval $(call __build_docpart_create_doxy_header_rule,$(part))))

$(foreach part,$(BUILD_DOCPART_DOXY_PARTS), \
  $(eval $(call __build_docpart_create_doxy_conf_rule,$(part))))

$(foreach part,$(BUILD_DOCPART_DOXY_PARTS), \
  $(eval $(call __build_docpart_create_run_doxygen_rule,$(part))))

ifdef __build_docpart_static_files
$(foreach file,$(__build_docpart_static_files), \
  $(eval $(call __build_docpart_create_static_file_target,$(file))))
endif

$(BUILD_DOCPART_TOC_FILE): $(__build_docpart_archive_contents)
	if [ -d "$(BUILD_DOCPART_DOCDIST_DIR)" ]; then \
	  $(BUILD_DOCPART_TOOLS_DIR)/generate-toc $(BUILD_DOCPART_DOCDIST_DIR) $(__build_docpart_name) $(BUILD_DOCPART_LOCAL_INSTALL); \
	fi

# Copy/create the docdist dir to part bsg dir for local editing support
$(BUILD_DOCPART_LOCAL_INSTALL): $(BUILD_DOCPART_TOC_FILE) $(__build_docpart_archive_contents)
	if [ -d $(BUILD_DOCPART_DOCDIST_DIR) ]; then \
	  rm -rf $@; \
	  cp -r $(BUILD_DOCPART_DOCDIST_DIR) $@; \
	else \
	  mkdir -p $@; \
	fi
	$(BUILD_DOCPART_TOOLS_DIR)/check-toc


# (name, install, description, flags, suffix, install_kit, doc_build_dir)
$(eval $(call __build_iip_doc, \
	$(BUILD_IIP), \
	$(BUILD_IIP_INSTALL), \
	$(BUILD_IIP_DESCRIPTION), \
	$(BUILD_IIP_FLAGS), \
	, \
	$(BUILD_IIP_KIT_INSTALL), \
	$(BUILD_IIP_DOC_BUILD_DIR)))
else

ifdef BUILD_IIP

ifeq ($(BUILD_IIP_DATA_BUILD_DIR_ENABLED),true)
# (name, install, description, flags, suffix, install_kit, data_build_dir)
$(eval $(call __build_iip_data_build, \
	$(BUILD_IIP), \
	$(BUILD_IIP_INSTALL), \
	$(BUILD_IIP_DESCRIPTION), \
	$(BUILD_IIP_FLAGS), \
	, \
	$(BUILD_IIP_KIT_INSTALL), \
	$(BUILD_IIP_DATA_BUILD_DIR)))
else
ifneq ($(BUILD_IIP_DIST),)
# (name, dist, install, description, flags, suffix, deps, install_kit)
$(eval $(call __build_iip, \
	$(BUILD_IIP), \
	$(BUILD_IIP_DIST), \
	$(BUILD_IIP_INSTALL), \
	$(BUILD_IIP_DESCRIPTION), \
	$(BUILD_IIP_FLAGS), \
	, \
	$(BUILD_IIP_DEPS), \
	$(BUILD_IIP_KIT_INSTALL)))
else
# (name, install, description, flags, suffix, install_kit)
$(eval $(call __build_iip_no_dist, \
	$(BUILD_IIP), \
	$(BUILD_IIP_INSTALL), \
	$(BUILD_IIP_DESCRIPTION), \
	$(BUILD_IIP_FLAGS), \
	, \
	$(BUILD_IIP_KIT_INSTALL)))
endif
endif # BUILD_IIP_DATA_BUILD_DIR_ENABLED

endif # BUILD_IIP

endif # BUILD_IIP_DOC
