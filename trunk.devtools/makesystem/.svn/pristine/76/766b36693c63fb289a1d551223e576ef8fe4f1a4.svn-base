NEEDS_ABS_PATHS = true

# Check mandatory BOOT_IMAGE_xyz variables

ifndef BOOT_IMAGE_CONFIG
  $(error BOOT_IMAGE_CONFIG is undefined)
endif

ifneq ($(filter /%,$(BOOT_IMAGE_CONFIG)),)
  $(error BOOT_IMAGE_CONFIG must be specified using a relative path)
endif

ifndef BOOT_IMAGE_NAME
  $(error BOOT_IMAGE_NAME is undefined)
endif

ifdef ALWAYS_BUILD
  ifeq ($(filter true false,$(ALWAYS_BUILD)),)
    $(error If present, ALWAYS_BUILD must be either 'true' or 'false')
  endif
endif

# If FLAVOURS or <target>_FLAVOURS is set, FLAVOUR will be set by makesystem
ifdef FLAVOUR
  $(error FLAVOURS are not allowed for boot image components; for each \
	  component, at most one boot image per device may be built)
endif

# Catch direct invocations of make most in a boot-image component
# (before common.mk has been included)
ifneq ($(filter most,$(MAKECMDGOALS)),)
  export LIMITED_BUILD = true
endif


# Decide whether to build products or only sanity check configuration

ifndef _build_products
  _build_products = true
  ifeq ($(LIMITED_BUILD),true)
    ifneq ($(ALWAYS_BUILD),true)
      _build_products = false
    endif
  endif
  export _build_products
endif


# Determine product files

_valid_products = boot-image kernel rootdisk debug-symbols lib-dependency-info
ifndef BOOT_IMAGE_PRODUCTS
  BOOT_IMAGE_PRODUCTS = $(_valid_products)
endif
ifneq ($(filter-out $(_valid_products), $(BOOT_IMAGE_PRODUCTS)),)
  $(error Invalid BOOT_IMAGE_PRODUCTS. \
	Was: "$(BOOT_IMAGE_PRODUCTS)". \
	Valid products: "$(_valid_products)")
endif

ifeq ($(BOOT_IMAGE_INTERNAL_USE_ONLY),true)
  _internal_token = _INTERNAL-USE-ONLY
else
  _internal_token =
endif
_version = $(BOOT_IMAGE_NAME)$(_internal_token)_$(BSG_BUILD_VERSION)_$(TOOLCHAIN)_$(DEVICE)

_bi_target = $(TARGET_OBJS_DIR)/kreatv-bi-$(_version).bin
_bi_nosec_target = $(TARGET_OBJS_DIR)/kreatv-bi-$(_version).bin.nosec
_kernel_target = $(TARGET_OBJS_DIR)/kreatv-kernel-nfs-$(_version)
_rootdisk_target = $(TARGET_OBJS_DIR)/kreatv-rootdisk-$(_version).tgz
_debug_symbols_target = $(TARGET_OBJS_DIR)/kreatv-debug-$(_version).tgz
_lib_dependency_info_target = $(TARGET_OBJS_DIR)/kreatv-libdep-$(_version).txt

_products =
ifneq ($(filter boot-image,$(BOOT_IMAGE_PRODUCTS)),)
  _products += $(_bi_target)
  _products += $(_bi_nosec_target)
endif
ifneq ($(filter kernel,$(BOOT_IMAGE_PRODUCTS)),)
  _products += $(_kernel_target)
endif
ifneq ($(filter rootdisk,$(BOOT_IMAGE_PRODUCTS)),)
  _products += $(_rootdisk_target)
endif
ifneq ($(filter debug-symbols,$(BOOT_IMAGE_PRODUCTS)),)
  _products += $(_debug_symbols_target)
endif
ifneq ($(filter lib-dependency-info,$(BOOT_IMAGE_PRODUCTS)),)
  _products += $(_lib_dependency_info_target)
endif

_dist_bs_support_dir = $(DIST_DIR)/noarch/boot-image-build-server-support
_dist_on_demand_bsg_root = $(_dist_bs_support_dir)/on-demand-bsg-root
_dist_bi_component_dir = $(_dist_on_demand_bsg_root)/$(COMPONENT)

_bi_component_json = \
  $(NOARCH_TOOLCHAIN_NAME)/boot-image-component.json
_disted_bi_component_json = $(_dist_bi_component_dir)/$(_bi_component_json)

_device_products_txt = $(NOARCH_TOOLCHAIN_NAME)/device-products_$(TARGET).txt
_disted_device_products_txt = $(_dist_bi_component_dir)/$(_device_products_txt)

_disted_bi_config = $(_dist_bi_component_dir)/$(BOOT_IMAGE_CONFIG)

ifneq ($(ALWAYS_BUILD),true)
  _parameter_dependencies_txt = \
    $(NOARCH_TOOLCHAIN_NAME)/parameter_dependencies_$(TARGET).txt
  _dist_bi_parameter_dependencies_dir = \
    $(DIST_DIR)/noarch/boot-image-parameter-dependencies/$(COMPONENT)
  _disted_parameter_dependencies_txt = \
    $(_dist_bi_parameter_dependencies_dir)/$(_parameter_dependencies_txt)
endif


# Set up boot image options

ifeq ($(BOOT_IMAGE_USE_DEBUG_KERNEL),true)
  _bbi_bi_option = --debug_boot_image
  _gbibs_bi_option = --debug-boot-image
else
  _bbi_bi_option = --boot_image
  _gbibs_bi_option = --boot-image
endif


# Set up common.mk target variables

ifdef TOOLCHAIN
  ifeq ($(_build_products),true)
    PRODUCT_TARGETS += $(_products)
  else
    OTHER_TARGETS += $(_products)
  endif
endif
NOARCH_TARGETS += $(_bi_component_json) $(_disted_bi_config)
OTHER_TARGETS += $(_device_products_txt)


include $(subst bootimage,common,$(lastword $(MAKEFILE_LIST)))


ifdef TOOLCHAIN
  _build_script = $(TARGET_OBJS_DIR)/build_boot_image.sh
  .PHONY: run_build_script
  .PHONY: run_sanity_check
  ifeq ($(_build_products),true)
$(PRODUCT_TARGETS): run_build_script
  else
$(OTHER_TARGETS): run_sanity_check
  endif
endif

_bi_build_dir = .bi_build_dir
CLEANUP_FILES += $(_bi_build_dir)

_comp_rel_path = $(subst $(COMPONENT_ROOT),,$(1))

$(_disted_bi_config): $(BOOT_IMAGE_CONFIG)
	@$(MAKESYSTEM)/dist_targets $(BOOT_IMAGE_CONFIG) $(dir $@)

$(_device_products_txt): .makefile
	mkdir -p $(dir $@)
	echo -n "" >$@
	for path in $(foreach p,$(_products),$(call _comp_rel_path,$(p))); do \
	  echo $$path >>$@; \
	done
	@$(MAKESYSTEM)/dist_targets $@ $(dir $(_disted_device_products_txt))

$(_bi_component_json): .makefile
	mkdir -p $(dir $@)
	> $@ printf '{\n'
	>>$@ printf '    "boot_image_name": "$(BOOT_IMAGE_NAME)",\n'
	>>$@ printf '    "boot_image_config": "$(BOOT_IMAGE_CONFIG)",\n'
	>>$@ printf '    "boot_image_always_build": %s,\n' \
	  $(if $(ALWAYS_BUILD),$(ALWAYS_BUILD),false)
	>>$@ printf '    "component_path": "$(COMPONENT)"\n'
	>>$@ printf "}\n"
	@$(MAKESYSTEM)/dist_targets $@ $(dir $(_disted_bi_component_json))

$(_build_script): $(MAKESYSTEM)/generate_boot_image_build_script
	if [ "$(DEVICE)" = "" ]; then \
	  echo "Error: Boot images must not have toolchains as COMPONENT_TARGETS."; \
	  exit 1; \
	fi;
	BOOT_IMAGE_NAME=$(BOOT_IMAGE_NAME) \
	BSG_BUILD_BRANCH=$(BSG_BUILD_BRANCH) \
	BSG_BUILD_VERSION=$(BSG_BUILD_VERSION) \
	TOOLCHAIN=$(TOOLCHAIN) \
	DEVICE=$(DEVICE) \
	  $< \
	    --config=$(call _comp_rel_path,$(BOOT_IMAGE_CONFIG)) \
	    --toolchain-path=$($(call _uc,$(TOOLCHAIN))_TOOLCHAIN_PATH) \
	    $(if $(filter boot-image,$(BOOT_IMAGE_PRODUCTS)), \
	      $(_gbibs_bi_option)=$(call _comp_rel_path,$(_bi_target)),) \
	    $(if $(filter rootdisk,$(BOOT_IMAGE_PRODUCTS)), \
	      --rootdisk=$(call _comp_rel_path,$(_rootdisk_target)),) \
	    $(if $(filter kernel,$(BOOT_IMAGE_PRODUCTS)), \
	      --nfs-kernel=$(call _comp_rel_path,$(_kernel_target)),) \
	    $(if $(filter debug-symbols,$(BOOT_IMAGE_PRODUCTS)), \
	      --debug-symbols=$(call _comp_rel_path,$(_debug_symbols_target)),) \
	    $(if $(filter lib-dependency-info,$(BOOT_IMAGE_PRODUCTS)), \
	      --lib-dependency-info=$(call _comp_rel_path,$(_lib_dependency_info_target)),) \
	    $(if $(BOOT_IMAGE_ADDITIONAL_BUILD_ARGUMENTS), \
	      --additional-build-arguments="$(BOOT_IMAGE_ADDITIONAL_BUILD_ARGUMENTS)",) \
	    $(_build_script)
	@$(MAKESYSTEM)/dist_targets --parents $@ $(_dist_bi_component_dir)

run_build_script: $(_build_script)
	mkdir -p $(_bi_build_dir)/$(TARGET_OBJS_DIR)
	TMPDIR=$(abspath $(_bi_build_dir)) \
	$(if $(_parameter_dependencies_txt), \
	PARAMETER_DEPENDENCIES_TARGET=$(CURDIR)/$(_parameter_dependencies_txt)) \
	  $(_build_script) \
	    $(DIST_DIR)/bin \
	    $(BSG_SRC_ABS) \
	    $(DIST_DIR)/products
ifneq ($(_parameter_dependencies_txt),)
	@$(MAKESYSTEM)/dist_targets \
	  $(_parameter_dependencies_txt) $(dir $(_disted_parameter_dependencies_txt))
endif

run_sanity_check: $(_build_script)
	$(if $(_parameter_dependencies_txt), \
	PARAMETER_DEPENDENCIES_TARGET=$(CURDIR)/$(_parameter_dependencies_txt)) \
	$(DIST_DIR)/bin/build_boot_image \
	  --source $(DIST_DIR)/products \
	  --dry-run \
	  --toolchain_path $(TOOLCHAIN_PATH) \
	  $(_bbi_bi_option) $(_bi_target) \
	  --rootdisk $(_rootdisk_target) \
	  --debug_symbols $(_debug_symbols_target) \
	  --kernel $(_kernel_target) \
	  --config $(BOOT_IMAGE_CONFIG) \
	  --toolchain $(TOOLCHAIN) \
	  --device $(DEVICE) \
	  --info branch $(BSG_BUILD_BRANCH) \
	  --info company "ARRIS Enterprises, Inc." \
	  --info configuration $(BOOT_IMAGE_NAME) \
	  --info version $(BSG_BUILD_VERSION) \
	  $(BOOT_IMAGE_ADDITIONAL_BUILD_ARGUMENTS)
ifneq ($(_parameter_dependencies_txt),)
	@$(MAKESYSTEM)/dist_targets \
	  $(_parameter_dependencies_txt) $(dir $(_disted_parameter_dependencies_txt))
endif
