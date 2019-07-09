### Sanity check KIT_CONFIG and check if kit is deliverable or only includable:

ifndef KIT_NAME_PREFIX
  KIT_NAME_PREFIX = kreatv
endif

ifndef KIT_CONFIG
  $(error KIT_CONFIG is undefined)
endif

ifneq ($(or $(KIT_TARGETS),$(KIT_NAME)),)
  ifndef KIT_TARGETS
    $(error KIT_TARGETS must be defined if KIT_NAME is defined)
  endif
  ifndef KIT_NAME
    $(error KIT_NAME must be defined if KIT_TARGETS is defined)
  endif
  _kit_is_deliverable = true
else
  _kit_is_deliverable = false
endif

# Catch direct invocations of make most in a kit component
# (before common.mk has been included)
ifneq ($(filter most,$(MAKECMDGOALS)),)
  export LIMITED_BUILD = true
endif

# Kit should not be built if ALWAYS_BUILD != true for limited builds
_should_build_kit = true
ifneq ($(ALWAYS_BUILD),true)
  ifeq ($(LIMITED_BUILD),true)
    _should_build_kit = false
  endif
endif

# Kit sanity check - some kits don't exist in some kreatv version
ifneq (,$(filter 4%,$(BSG_BUILD_VERSION)))
  ifneq (,$(filter 5%, $(KIT_KREATV_VERSION)))
    _kit_is_disabled = true
  endif 
endif
ifneq (,$(filter 5%,$(BSG_BUILD_VERSION)))
  ifneq (,$(filter 4%, $(KIT_KREATV_VERSION)))
    _kit_is_disabled = true
  endif
endif

ifeq ($(_kit_is_disabled),true)
  $(info The kit you are trying to build does not exist for BSG_BUILD_VERSION $(BSG_BUILD_VERSION))
  _should_build_kit = false
endif

ifdef KIT_KREATV_VERSION
  ifeq (,$(filter $(KIT_KREATV_VERSION),4 5))
    $(error KIT_KREATV_VERSION has an invalid value. Valid values are 4 and 5.)
  endif
endif

# To prevent duplicate SDK filenames
ifeq (,$(filter 4%,$(BSG_BUILD_VERSION)))
  ifeq (,$(filter 5%, $(KIT_KREATV_VERSION)))
    _kit_version_prefix = $(KIT_KREATV_VERSION)
  endif
endif



# Targets

_dist_tools_dir = $(DIST_DIR)/bin
_dist_bs_support_dir = $(DIST_DIR)/noarch/kits-build-server-support
_dist_on_demand_bsg_root = $(_dist_bs_support_dir)/on-demand-bsg-root
_dist_component_kit_dir = $(_dist_on_demand_bsg_root)/$(COMPONENT)

_disted_kit_config = $(_dist_component_kit_dir)/kit_config
_kit_config_disted = .kit_config_disted
NOARCH_TARGETS += $(_kit_config_disted)
CLEANUP_FILES += $(_kit_config_disted)

ifeq ($(_kit_is_deliverable),true)
  ifeq ($(KIT_INTERNAL_USE_ONLY),true)
    _archive_suffix = INTERNAL-USE-ONLY_$(BSG_BUILD_VERSION).tgz
  else
    _archive_suffix = $(BSG_BUILD_VERSION).tgz
  endif
  _archive = $(KIT_NAME_PREFIX)$(_kit_version_prefix)-$(KIT_NAME)_$(_archive_suffix)
  _build_script = noarch/build_$(_archive).sh

  ifeq ($(_should_build_kit),true)
    NOARCH_TARGETS += $(_archive)
  endif

  _build_script_disted = .build_script_disted
  NOARCH_TARGETS += $(_build_script_disted)
  CLEANUP_FILES += $(_build_script_disted)
  _disted_build_script = $(_dist_component_kit_dir)/$(_build_script)

  _build_kit = $(_dist_tools_dir)/build_kit

  _slashless_component=$(subst /,_,$(subst _,__,$(COMPONENT)))
  _description_file = $(NOARCH_TOOLCHAIN_NAME)/$(_slashless_component).json
  _disted_description_file = \
    $(_dist_bs_support_dir)/deliverable_kits/$(_slashless_component).json
  ifneq ($(_kit_is_disabled),true)
    NOARCH_TARGETS += $(_description_file)
  endif
endif

ifneq ($(ALWAYS_BUILD),true)
  _parameter_dependencies_txt = \
    $(NOARCH_TOOLCHAIN_NAME)/parameter_dependencies.txt
  _dist_kit_parameter_dependencies_dir = \
    $(DIST_DIR)/noarch/kit-parameter-dependencies/$(COMPONENT)
  _disted_parameter_dependencies_txt = \
    $(_dist_kit_parameter_dependencies_dir)/$(_parameter_dependencies_txt)
endif


include $(subst kit,common,$(lastword $(MAKEFILE_LIST)))


### Verify KIT_TARGETS and set up _kit_devices and _kit_devices_<toolchain> variables.

ifeq ($(_kit_is_deliverable),true)
  _kit_toolchains := $(filter $(_all_available_toolchains),$(KIT_TARGETS))
  _kit_devices := $(filter-out $(_all_available_toolchains),$(KIT_TARGETS))
  $(foreach toolchain,$(_kit_toolchains),\
    $(eval _toolchain_expanded_devices += $($(call _uc,$(toolchain))_DEVICES)))
  _kit_devices := $(_toolchain_expanded_devices) $(filter-out $(_toolchain_expanded_devices),$(_kit_devices))

  $(foreach toolchain,$(_all_available_toolchains),\
    $(eval _kit_devices_$(toolchain) := $(filter $($(call _uc,$(toolchain))_DEVICES),$(_kit_devices))))

  _invalids = $(filter-out $(_all_available_devices),$(_kit_devices))
  ifneq ($(_invalids),)
    $(error Invalid toolchain/device: $(_invalids))
  endif

  _disabled_kit_devices = $(filter-out $(_enabled_targets),$(_kit_devices))
endif # _kit_is_deliverable

ifeq ($(wildcard $(KIT_CONFIG)),)
  $(error $(KIT_CONFIG) does not exist)
endif

### Rules for disting files

$(_kit_config_disted): $(KIT_CONFIG)
	$(MAKESYSTEM)/dist_targets --rename $< $(_disted_kit_config)
	touch $@


ifeq ($(_kit_is_deliverable),true)

### Rules etc. for generating wrapper build script

CLEANUP_FILES += $(_build_script)

ifeq ($(_should_build_kit),false)
# build_kit will automatically sanity check the configuration when building a
# kit, but if we won't be building the kit, we'll do a separate sanity check.
_kit_config_is_sane = .kit_config_is_sane
$(_build_script): $(_kit_config_is_sane)
CLEANUP_FILES += $(_kit_config_is_sane)
endif

$(_build_script): $(KIT_CONFIG)
	mkdir -p $(@D)
	$(MAKESYSTEM)/generate_kit_build_script \
	  $(foreach toolchain, \
		$(_all_available_toolchains), \
		--toolchain_info "name:$(toolchain),devices:$($(call _uc,$(toolchain))_DEVICES),cxx:$($(call _uc,$(toolchain))_CXX)") \
	  --devices $(_kit_devices) \
	  --kit-config $(KIT_CONFIG) \
	  $(if $(filter true,$(KIT_NOT_SUITABLE_FOR_TESTS)), \
	    , \
	    --test-program dist/test/TestFramework/run_tests) \
	  --build-script $@

$(_build_script_disted): $(_build_script)
	$(MAKESYSTEM)/dist_targets $< $(dir $(_disted_build_script))
	touch $@


### Rules for updating JSON kit description file

_deliverables_dir = products/kits/deliverables
_deliverable_kit_path = $(COMPONENT:$(_deliverables_dir)/%=%)

ifeq ($(_should_build_kit),true)
$(_description_file):
	$(MAKESYSTEM)/create_deliverable_kit_description always-built \
	  --product-filename=$(_archive) \
	  --description-file=$(_description_file) \
	  $(_deliverable_kit_path)
	@$(MAKESYSTEM)/dist_targets $@ $(dir $(_disted_description_file))
else
$(_description_file):
	$(MAKESYSTEM)/create_deliverable_kit_description on-demand \
	  $(if $(filter true,$(KIT_TEST_BUILDS_3PP_CODE)), \
	       --test-builds-3pp-code, \
	       ) \
	  --description-file=$(_description_file) \
	  $(_deliverable_kit_path)
	@$(MAKESYSTEM)/dist_targets $@ $(dir $(_disted_description_file))
endif


### Sanity check a deliverable kit (using KIT_CONFIG, KIT_TARGETS and IIP dir.)

# We only sanity check kit_config for those devices enabled in platforms.mk
_kit_sanity_check_devices = $(filter $(_enabled_targets),$(_kit_devices))

$(_kit_config_is_sane): $(KIT_CONFIG) $(_build_kit)
ifneq ($(_kit_sanity_check_devices),)
	PERL5LIB=$(_dist_tools_dir) \
	$(if $(_parameter_dependencies_txt), \
	PARAMETER_DEPENDENCIES_TARGET=$(CURDIR)/$(_parameter_dependencies_txt)) \
	$(_build_kit) \
	  --dry-run \
	  --config $(KIT_CONFIG) \
	  --source $(DIST_DIR)/products \
	  $(foreach toolchain,$(_all_available_toolchains),\
	    $(addprefix --architecture $(toolchain)_,$(filter $(_enabled_targets),$(_kit_devices_$(toolchain))))) \
	  --kit $(_archive);
ifneq ($(_parameter_dependencies_txt),)
	@$(MAKESYSTEM)/dist_targets \
	  $(_parameter_dependencies_txt) $(dir $(_disted_parameter_dependencies_txt))
endif
endif
	@touch $@

CLEANUP_FILES += $(_archive)
_kit_build_dir = .kit_build_dir
_build_script_env += TMPDIR=$(abspath $(_kit_build_dir))
_build_script_env += CCACHE=$(CCACHE)
_build_script_env += CPPFLAGS="$(_hardening_cppflags) $(_extra_debug_cppflags)"
_build_script_env += CXXFLAGS="$(_hardening_common_flags)"
ifneq ($(_parameter_dependencies_txt),)
_build_script_env += PARAMETER_DEPENDENCIES_TARGET=$(CURDIR)/$(_parameter_dependencies_txt)
endif

_build_script_args = $(foreach path,\
                               $(DIST_DIR)/products \
                               $(BSG_SRC_ABS) \
                               $(_dist_tools_dir) \
                               $(_kit_build_dir)/$(_archive), \
                               $(abspath $(path)))

$(_archive): $(_build_script)
ifeq ($(_disabled_kit_devices),)
	mkdir -p $(_kit_build_dir)
	rm -rf $(_kit_build_dir)/*
	+cd $(_kit_build_dir) && \
	  $(_build_script_env) ../$< $(_build_script_args)
	mv $(_kit_build_dir)/$(_archive) $@
	@$(MAKESYSTEM)/dist_targets $@ $(DIST_DIR)/products
ifneq ($(_parameter_dependencies_txt),)
	@$(MAKESYSTEM)/dist_targets \
	  $(_parameter_dependencies_txt) $(dir $(_disted_parameter_dependencies_txt))
endif
else
	echo "Warning: Not all needed devices are enabled in platforms.mk. The kit will not be built."
endif
	rm -rf $(_kit_build_dir)
endif
