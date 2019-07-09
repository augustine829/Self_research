# META: ifndef OSSK || BOSSK
# NOTE: The "META:" comments are for ossk and bootloader-ossk.
# NOTE: Key related text should not be in ossk.
# META: endif

# Make sure that this file is only included once
ifndef COMMON_MK

### Check for required make features.
required_features = else-if order-only target-specific
ifneq ($(sort $(filter $(required_features), $(.FEATURES))), $(required_features))
  $(error Error: Too old make version: $(shell $(MAKE) --version | head -1))
endif

### Utility functions

# Get the n-th part of a string (allowing empty parts).
#
# $(1): Part number (starting with 1).
# $(2): Part delimiter.
# $(3): The string.
_nth = $(subst _SPLITMARKER_,,$(word $(1),$(subst $(2), _SPLITMARKER_,$(3))))

# Uppercase a string
_uc = $(shell echo $(1) | tr '[:lower:]' '[:upper:]')

# capitalize a string
_cap = $(shell echo $(1) | sed 's/^./\u&/')

### Set up BSG_SRC, BSG_SRC_ABS and MAKESYSTEM variables
__pop = $(patsubst %/,%,$(dir $(1)))
__tmp := $(call __pop,$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST)))
# Special case for makesystem/Makefile
ifeq ($(__tmp),.)
__tmp := ../$(notdir $(CURDIR))
endif

ifndef BSG_SRC
BSG_SRC := $(call __pop,$(__tmp))
endif

ifndef BSG_SRC_ABS
BSG_SRC_ABS := $(CURDIR)
ifneq ($(BSG_SRC),.)
$(foreach ,$(subst /, ,$(BSG_SRC)),$(eval BSG_SRC_ABS := $(call __pop,$(BSG_SRC_ABS))))
endif
export BSG_SRC_ABS
endif

ifndef MAKESYSTEM
export MAKESYSTEM := $(BSG_SRC_ABS)/$(notdir $(__tmp))
endif

### Check unit test status
ifndef COMPONENT_IS_3PP
ifdef SRCS
ifndef TEST_TARGETS
ifndef NOT_SUITABLE_FOR_UNIT_TESTS
$(error Error: Component $(CURDIR) contains SRCS; it should define unit test status with "TEST_TARGETS = $$(empty)" if the component contains unit testable code or "NOT_SUITABLE_FOR_UNIT_TESTS = true" if it does not contain unit testable code)
endif # NOT_SUITABLE_FOR_UNIT_TESTS
endif # TEST_TARGETS
endif # SRCS
endif # COMPONENT_IS_3PP

### Set up targets etc

ifdef TARGETSETUP_MK
$(error Error: "targetsetup.mk" should not be included directly, include "constants.mk" instead)
endif

include $(MAKESYSTEM)/targetsetup.mk

# Include gcov setup

ifdef USE_GCOV
include $(MAKESYSTEM)/gcov.mk
endif

# Include klocwork setup

ifdef REVIEW
include $(MAKESYSTEM)/klocwork/klocwork.mk
endif

# Silent make

ifneq ($(V),)
export VERBOSE = 1
endif

ifeq ($(VERBOSE),)
ifeq ($(COMPONENT_IS_3PP),)
MAKEFLAGS += -s
endif
endif

ifeq ($(VERBOSE),)
Q = @
else
Q =
endif

MAKEFLAGS += --no-print-directory

### Parallel control

ifneq ($(PARALLEL_3PP),)
ifneq ($(PARALLEL_3PP),true)
$(error Error: PARALLEL_3PP must either be unset or equal to "true")
endif
endif

ifneq ($(COMPONENT_IS_3PP),)
ifeq ($(PARALLEL_3PP),)
ifneq ($(TARGET),)
MAKE += -j1
endif
endif
endif



###
### IDL Compiler stuff
###

IDL_COMPILER        = $(PYTHON_TOOLCHAIN_PATH)/bin/omniidl
IDL_BACKEND_PATH    = $(DIST_DIR)/bin
IDL_BACKENDS        = toaidl
IDL_COMPILER_ARGS   = -p$(IDL_BACKEND_PATH) -b$(IDL_BACKENDS) -Wb$(IDL_INCLUDE_PATH) $(IDL_INCPATH)

_idl_compiler_marker = $(DIST_DIR)/bin/.idl_compiler_marker
_idl_backend_include_path = interface

# INSTALL_DIR

ifneq ($(COMPONENT_IS_3PP),)
INSTALL_DIR = $(DIST_DIR)/3pp
TARGET_INSTALL_DIR = $(DIST_DIR)/$(TOOLCHAIN)/3pp
HOST_INSTALL_DIR = $(DIST_DIR)/$(HOST_TOOLCHAIN_NAME)/3pp
else
INSTALL_DIR = $(DIST_DIR)
TARGET_INSTALL_DIR = $(DIST_DIR)/$(TOOLCHAIN)
HOST_INSTALL_DIR = $(DIST_DIR)/$(HOST_TOOLCHAIN_NAME)
endif


# Test time limits

ifneq ($(COMPONENT_LONG_TEST),)
__unit_test_warning    = 120
ifneq ($(TEST_KILL_TIME),)
__unit_test_kill       = $(TEST_KILL_TIME)
else
__unit_test_kill       = 600
endif
else
__unit_test_warning    = 15
__unit_test_kill       = 120
endif


### Set up paths

ifeq ($(findstring $(PYTHON_TOOLCHAIN_PATH),$(PATH)),)
PATH := $(PYTHON_TOOLCHAIN_PATH)/bin:$(PATH)
endif

# During the first pass, no TARGET is set. In that case, don't do anything.
ifneq ($(TARGET),)
ifneq ($(TOOLCHAIN),$(HOST_TOOLCHAIN_NAME))
PATH := $(TOOLCHAIN_PATH)/bin:$(PATH)
else
PATH := $(PATH):$(TOOLCHAIN_PATH)/bin
endif
export PERLLIB := $(DIST_DIR)/bin
endif

# Don't use user's own PYTHONPATH.
export PYTHONPATH :=
# Don't write .pyc files in dist (or other places).
export PYTHONDONTWRITEBYTECODE = 1

# Enable sandbox building for 3pp components
ifndef USE_SANDBOX
ifneq ($(COMPONENT_IS_3PP),)
USE_SANDBOX = true
endif
endif

ifdef USE_FULL_SANDBOX
USE_SANDBOX = true
endif

# Enable limited build if 'most' goal was supplied
ifeq ($(TARGET),)
  ifneq ($(filter most,$(MAKECMDGOALS)),)
    export LIMITED_BUILD = true
  endif
endif

export DOC_EXAMPLE_DIST_DIR = $(DIST_DIR)/doc/doc-examples


### Compilation and link flags

# All include files are put in $(TOOLCHAIN_DIST_DIR)/include,
# $(TOOLCHAIN_3PP_DIST_DIR)/include,
# $(TOOLCHAIN_3PP_DIST_DIR)/$(DEVICE)/include

ifneq ($(USE_FULL_SANDBOX),)
__include_dir_top = $(__target_sandbox_dir)
__3pp_include_dir_top = $(__target_3pp_sandbox_dir)
else
__include_dir_top = $(TOOLCHAIN_DIST_DIR)
__3pp_include_dir_top = $(TOOLCHAIN_3PP_DIST_DIR)
endif

INCPATH += -I.
INCPATH += -I$(__include_dir_top)/include
ifneq ($(DEVICE),)
INCPATH += -isystem $(__3pp_include_dir_top)/$(DEVICE)/include
endif
INCPATH += -isystem $(__3pp_include_dir_top)/include

ifeq ($(filter $(NOARCH_TOOLCHAIN_NAME) $(STB_NOARCH_TOOLCHAIN_NAME), $(TOOLCHAIN)), )
INCPATH += -I$(DIST_DIR)/$(STB_NOARCH_TOOLCHAIN_NAME)/include
INCPATH += -isystem $(DIST_DIR)/$(STB_NOARCH_TOOLCHAIN_NAME)/3pp/include
endif
ifneq ($(TOOLCHAIN), $(NOARCH_TOOLCHAIN_NAME))
INCPATH += -I$(DIST_DIR)/$(NOARCH_TOOLCHAIN_NAME)/include
INCPATH += -isystem $(DIST_DIR)/$(NOARCH_TOOLCHAIN_NAME)/3pp/include
endif

# Optimization flags
ifdef USE_GCOV
  ifeq ($(TOOLCHAIN),$(HOST_TOOLCHAIN_NAME))
    OPTIMIZATION_FLAGS = -O0
  else
    OPTIMIZATION_FLAGS = -Os
  endif
else
  OPTIMIZATION_FLAGS = -Os
  # ARM experiences predictable crashes when throwing exceptions if built with -fomit-frame-pointer
  ifneq (,$(filter $(BCM15_TOOLCHAIN_NAME) $(ST9_TOOLCHAIN_NAME),$(TOOLCHAIN)))
    OPTIMIZATION_FLAGS += -fno-omit-frame-pointer
  endif
endif

# Architecture dependent compiler flags
ifneq ($(TOOLCHAIN),)
  ARCH_CPPFLAGS += -D__$(call _uc,$(TOOLCHAIN))__=1
endif

ifneq ($(DEVICE),)
  ARCH_CPPFLAGS += -D__$(call _uc,$(DEVICE))__=1
endif

ifneq ($(TOOLCHAIN),$(HOST_TOOLCHAIN_NAME))
ifeq ($(USE_KLIBC),true)
  _use_klibc = true
endif
endif

ifdef USE_EXTRA_DEBUG
  USE_HARDENING = true
  PRODUCES_STANDALONE_BINARY := $(empty)

  _extra_debug_cppflags = -D_GLIBCXX_DEBUG
  CPPFLAGS += $(_extra_debug_cppflags)
  # Linker version scripts don't work in combination with _GLIBCXX_DEBUG
  # (results in strange crashes) so the link_wrapper script is used to filter
  # out that flag.
  __link_wrapper = $(MAKESYSTEM)/link_wrapper
endif

ifneq ($(NO_DEBUG_LOGGING),)
  ifneq ($(TOOLCHAIN),$(HOST_TOOLCHAIN_NAME))
    CPPFLAGS += -DNO_DEBUG_LOGGING
  endif
endif

# Buffer overflow detection and stack protection
ifdef NO_HARDENING
  _use_hardening = false
else ifneq ($(MODULE_SRCS),)
  # No support for stack protection in the kernel
  _use_hardening = false
else ifneq ($(PRODUCES_STANDALONE_BINARY),)
  _use_hardening = false
else ifdef USE_HARDENING
  _use_hardening = true
else ifeq ($(TOOLCHAIN),$(HOST_TOOLCHAIN_NAME))
  _use_hardening = true
endif

ifeq ($(_use_hardening),true)
  ifneq ($(_use_klibc),true)
    # No support for stack protection options in klibc.
    _hardening_common_flags = -fstack-protector-all --param ssp-buffer-size=4
  endif

  _hardening_cppflags = -D_FORTIFY_SOURCE=2 -Wno-unused-result

  COMMON_FLAGS += $(_hardening_common_flags)
  CPPFLAGS += $(if $(filter -O%, $(filter-out -O0,$(OPTIMIZATION_FLAGS))), \
                   $(_hardening_cppflags))
endif

# Symbol visibility
ifeq ($(COMPONENT_IS_3PP),)
ifdef USE_SYMBOL_VISIBILITY_HIDDEN
  COMMON_FLAGS += -fvisibility=hidden
endif
ifndef NO_SYMBOL_VISIBILITY_MACROS
  CPPFLAGS += -include $(MAKESYSTEM)/Visibility.h
endif
endif

ifeq ($(TOOLCHAIN),$(ST40_TOOLCHAIN_NAME))
  OPTIMIZATION_FLAGS += -finline-limit=50
  CXXFLAGS += -fvisibility-inlines-hidden
endif

# Sanitize
ifdef USE_SANITIZE
ifeq ($(COMPONENT_IS_3PP)$(_use_klibc)$(MODULE_SRCS),)
ifeq ($(TOOLCHAIN),$(HOST_TOOLCHAIN_NAME))
  ARCH_FLAGS += -fsanitize=address
  ARCH_FLAGS += -fsanitize=undefined
endif
endif
endif

ifeq ($(TOOLCHAIN),$(HOST_TOOLCHAIN_NAME))
ifeq ($(PRODUCES_STANDALONE_BINARY)$(USE_EXTRA_DEBUG),)
  ARCH_FLAGS += -Wdate-time
endif
endif

# Preprocessor flags
CPPFLAGS += $(KLIBC_CPPFLAGS) $(INCPATH) $(ARCH_CPPFLAGS)

ifneq (,$(filter $(BCM15_TOOLCHAIN_NAME) $(ST9_TOOLCHAIN_NAME),$(TOOLCHAIN)))
  # Turn off warning: note: the mangling of 'va_list' has changed in GCC 4.4
  ARCH_FLAGS += -Wno-psabi
endif

# Compilation flags
DEBUG_FLAGS = -g
COMMON_FLAGS += $(DEBUG_FLAGS) $(OPTIMIZATION_FLAGS) $(ARCH_FLAGS)
ifeq ($(COMPONENT_IS_3PP),)
  COMMON_FLAGS += -Wall -Wextra -Wformat-security -Wpointer-arith -pipe
  CXXFLAGS += -Wnon-virtual-dtor
  ifeq ($(USE_SYSTEM_TOOLCHAIN_FOR_HOST),) # Could be GCC 4.4
    # We don't consider empty format strings to be problematic.
    CXXFLAGS += -Wno-format-zero-length
  endif
  CPPFLAGS += -D_GNU_SOURCE
  CPPFLAGS += -D_REENTRANT
  CPPFLAGS += -D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE
  CPPFLAGS += -D__STDC_FORMAT_MACROS
endif

CFLAGS += $(COMMON_FLAGS) $(KLIBC_FLAGS)
ifeq ($(COMPONENT_IS_3PP),)
CFLAGS += -std=gnu99
endif

CXXFLAGS += $(COMMON_FLAGS) $(KLIBC_FLAGS)
ifeq ($(COMPONENT_IS_3PP),)
  CXXFLAGS += $(_$(TOOLCHAIN)_cxxflags)
endif

NOPIC = -fno-PIC -ffunction-sections -fdata-sections -DNOPIC
ifeq ($(TOOLCHAIN),$(BCM45_TOOLCHAIN_NAME))
NOPIC += -mno-abicalls
endif

ifeq ($(MODULE_LINUX_FLAVOUR),)
  MODULE_LINUX_FLAVOUR = linux
endif

_module_include_dir = $(TOOLCHAIN_3PP_DIST_DIR)/$(DEVICE)/$(MODULE_LINUX_FLAVOUR)

MODULE_CFLAGS += $(COMMON_FLAGS)
MODULE_CPPFLAGS += -D__KERNEL__ -DMODULE
MODULE_CPPFLAGS += -isystem $(_module_include_dir)/include

ifeq ($(TOOLCHAIN), $(ST40_TOOLCHAIN_NAME))
MODULE_CPPFLAGS += -include $(_module_include_dir)/include/linux/autoconf.h
else
MODULE_CPPFLAGS += -include $(_module_include_dir)/include/linux/kconfig.h
endif

MODULE_CFLAGS += -fno-common -fomit-frame-pointer -fno-strict-aliasing -w
MODULE_CFLAGS += -ffreestanding
ifeq ($(TOOLCHAIN),$(ST40_TOOLCHAIN_NAME))
# The -m4-nofpu flag replaces the __SH4__ define with __SH4_NOFPU__ but to
# avoid having different defines for kernel and user space we define __SH4__
# ourselves.
MODULE_CFLAGS += -m4-300-nofpu
MODULE_CPPFLAGS += -D__SH4__=1
else ifeq ($(TOOLCHAIN),$(ST9_TOOLCHAIN_NAME))
MODULE_CFLAGS += -D__LINUX_ARM_ARCH__=7
MODULE_CPPFLAGS += -isystem $(_module_include_dir)/arch/arm/mach-sti/include
MODULE_CPPFLAGS += -isystem $(_module_include_dir)/arch/arm/include/generated
MODULE_CPPFLAGS += -isystem $(_module_include_dir)/arch/arm/include
else ifeq ($(TOOLCHAIN),$(BCM15_TOOLCHAIN_NAME))
MODULE_CFLAGS += -D__LINUX_ARM_ARCH__=7
MODULE_CFLAGS += -mfpu=vfp -msoft-float
MODULE_CPPFLAGS += -isystem $(_module_include_dir)/arch/arm/include/generated
MODULE_CPPFLAGS += -isystem $(_module_include_dir)/arch/arm/include
else ifeq ($(TOOLCHAIN),$(BCM45_TOOLCHAIN_NAME))
MODULE_CFLAGS += -fno-pic -mno-abicalls -mlong-calls -G 0
MODULE_CFLAGS += -msoft-float
MODULE_CPPFLAGS += -isystem $(_module_include_dir)/include/asm/mach-brcmstb
MODULE_CPPFLAGS += -isystem $(_module_include_dir)/include/asm/mach-generic
endif

MODULE_CPPFLAGS += -D'KBUILD_STR(s)=\#s'
MODULE_CPPFLAGS += -D'KBUILD_BASENAME=KBUILD_STR($(MODULE_NAME))'
MODULE_CPPFLAGS += -D'KBUILD_MODNAME=KBUILD_STR($(MODULE_NAME))'


# Setup library include path
# Include target directory first so that testcases can link with a library built
# in the same component as the testcase without having to wait for dist install.
ifeq ($(COMPONENT_IS_3PP),)
LIBPATH += -L$(TARGET_OBJS_DIR)
endif

ifneq ($(TOOLCHAIN),$(HOST_TOOLCHAIN_NAME))
ifneq ($(_use_klibc),true)
LIBPATH += -L$(TOOLCHAIN_PATH)/$(TARGET_ARCH)/lib
LIBPATH += -L$(TOOLCHAIN_PATH)/$(TARGET_ARCH)/sys-root/lib
LIBPATH += -L$(TOOLCHAIN_PATH)/$(TARGET_ARCH)/sys-root/usr/lib
endif
else ifeq ($(PRODUCES_STANDALONE_BINARY),)
  RPATH += -Wl,-rpath,$(DIST_DIR_ABS)/$(TOOLCHAIN)/lib
  RPATH += -Wl,-rpath,$(DIST_DIR_ABS)/$(TOOLCHAIN)/3pp/lib
endif

ifneq ($(USE_SANDBOX),)
__target_dist_dir_top = $(__target_sandbox_dir)
__lib_dir = $(__target_sandbox_dir)/lib
__3pp_lib_dir = $(__target_3pp_sandbox_dir)/lib
else
__target_dist_dir_top = $(TOOLCHAIN_DIST_DIR)
__lib_dir = $(TOOLCHAIN_DIST_DIR)/lib
__3pp_lib_dir = $(TOOLCHAIN_3PP_DIST_DIR)/lib
endif

ifdef DEVICE
  LIBPATH += -L$(__target_dist_dir_top)/$(DEVICE)/lib
  LIBPATH += -L$(__target_dist_dir_top)/3pp/$(DEVICE)/lib
endif
LIBPATH += -L$(__lib_dir)
LIBPATH += -L$(__3pp_lib_dir)

RPATH += -Wl,-rpath-link,$(__3pp_lib_dir)
RPATH += -Wl,-rpath-link,$(__lib_dir)
ifdef DEVICE
  RPATH += -Wl,-rpath-link,$(__target_dist_dir_top)/$(DEVICE)/lib
  RPATH += -Wl,-rpath-link,$(__target_dist_dir_top)/3pp/$(DEVICE)/lib
endif

LDFLAGS += $(LIBPATH)
LDFLAGS += $(RPATH)
LDFLAGS += -Wl,--no-add-needed
LDFLAGS += -Wl,-O1
ifeq ($(COMPONENT_IS_3PP),)
LDFLAGS += -Wl,-z,defs
endif

ifeq ($(TOOLCHAIN),$(BCM45_TOOLCHAIN_NAME))
  LDFLAGS += -Wl,-z,max-page-size=0x1000
endif

# idl compilation
IDL_INCPATH += -I$(DIST_DIR)/idl
IDL_INCPATH += -I$(DIST_DIR)/idl/cpp
IDL_INCPATH += -I$(DIST_DIR)/idl/cpp/toi
IDL_INCPATH += -I$(DIST_DIR)/idl/$(RPC_EXPORT_PATH)
IDL_INCPATH += -I$(CURDIR)

GENERIC_IDL_PATH = $(DIST_DIR)/idl/generic
CPP_IDL_PATH  = $(DIST_DIR)/idl/cpp
JS_IDL_PATH = $(DIST_DIR)/idl/js
TOI_IDL_PATH = $(GENERIC_IDL_PATH)/toi
TOI_CPP_IDL_PATH  = $(CPP_IDL_PATH)/toi
TOI_JS_IDL_PATH = $(JS_IDL_PATH)/toi
JS_COMMON_PATH = $(DIST_DIR)/src/js_common
TOIWEB_JS_IDL_PATH = $(DIST_DIR)/idl/toiweb

_platform_helpers_interface_path = platform/helpers

# Transports the development environment into configure scripts and foreign
# makes
BSG_DEVSETUP  = PATH=$(PATH)
BSG_DEVSETUP += BSG_SRC=$(BSG_SRC)
BSG_DEVSETUP += CC="$(CC)" CXX="$(CXX)" AS="$(AS)" AR="$(AR)" LD="$(LD)" RANLIB="$(RANLIB)" SIZE="$(SIZE)" STRIP="$(STRIP)" NM="$(NM)"
BSG_DEVSETUP += HOST_CC="$(HOST_CC)" HOST_CXX="$(HOST_CXX)" HOST_AS="$(HOST_AS)" HOST_AR="$(HOST_AR)" HOST_LD="$(HOST_LD)" HOST_RANLIB="$(HOST_RANLIB)" HOST_SIZE="$(HOST_SIZE)" HOST_STRIP="$(HOST_STRIP)" HOST_NM="$(HOST_NM)"
BSG_DEVSETUP += CPPFLAGS="$(CPPFLAGS)"
BSG_DEVSETUP += CFLAGS="$(CFLAGS)"
BSG_DEVSETUP += CXXFLAGS="$(CXXFLAGS)"
BSG_DEVSETUP += LDFLAGS="$(LIBPATH) $(KLIBC_BASE) $(KLIBC_LDFLAGS) $(_hardening_common_flags)"
BSG_DEVSETUP += LDLIBS="$(KLIBC_LDLIBS)"
BSG_DEVSETUP += PKG_CONFIG=true

ifneq ($(TOOLCHAIN),$(HOST_TOOLCHAIN_NAME))
TEST_TARGETS =
else
ifneq ($(TESTS_ONLY),)
BIN_TARGETS =
LIB_TARGETS =
OTHER_TARGETS =
PRODUCT_TARGETS =
endif
endif

ifneq ($(BUILD_TEST), true)
TEST_TARGETS =
endif


### Cleanup files

__source_dirs = $(sort $(dir $(SRCS)))
CLEANUP_FILES += .test_time
CLEANUP_FILES += .dist.*
CLEANUP_FILES += .sources.*
CLEANUP_FILES += .componenthash
CLEANUP_FILES += .libdepends*
CLEANUP_FILES += .requires
CLEANUP_FILES += .requires_setup
CLEANUP_FILES += .requires_depend
CLEANUP_FILES += .requires_list
CLEANUP_FILES += .failed_components
CLEANUP_FILES += .install_depends
CLEANUP_FILES += .installed_headers_marker
CLEANUP_FILES += $(PRODUCT_TARGETS)
CLEANUP_FILES += core
CLEANUP_FILES += $(addsuffix *.o,$(__source_dirs))
CLEANUP_FILES += $(addsuffix *.d,$(__source_dirs))
CLEANUP_FILES += $(addsuffix *.rpo,$(__source_dirs))
CLEANUP_FILES += $(addsuffix *~,$(__source_dirs))
CLEANUP_FILES += $(addsuffix *.gcov,$(__source_dirs))
CLEANUP_FILES += $(rpc_srcs)
CLEANUP_FILES += $(_rpc_mock_srcs) $(_rpc_mock_headers)
CLEANUP_FILES += $(RPC_OBJS)
CLEANUP_FILES += $(rpc_base_headers)
CLEANUP_FILES += $(rpc_code_headers)
CLEANUP_FILES += $(_all_available_toolchains)
CLEANUP_FILES += $(NOARCH_TOOLCHAIN_NAME)
CLEANUP_FILES += $(STB_NOARCH_TOOLCHAIN_NAME)
CLEANUP_FILES += .gcov_*
CLEANUP_FILES += $(SRC_DIR)
CLEANUP_FILES += $(SRC_DIR).bak.??????

### Klocwork
_klocwork_dir = .klocwork
_klocwork_project_dir  = $(_klocwork_dir)/.kwlp
_klocwork_settings_dir = $(_klocwork_dir)/.kwps
_klocwork_project_dirs += $(_klocwork_project_dir)
_klocwork_project_dirs += $(_klocwork_settings_dir)
_klocwork_build_spec = $(_klocwork_dir)/kw_build_spec
_klocwork_result = $(_klocwork_dir)/kw_analysis_result
CLEANUP_FILES += $(_klocwork_dir)


### KreaTV idl files
# Note: From each XYY.idl file, the compiler generates the following files
# IYY.h, TYYCaller.{h,cpp} and TYYDispatcher.{h,cpp}
ifdef RPC_INTERFACE
rpc_idls = $(addsuffix .idl,$(RPC_INTERFACE))

rpc_observer_idls = $(filter I%Observer.idl,$(rpc_idls))

rpc_base_headers += $(rpc_idls:%.idl=%.h)

rpc_idl_files = $(notdir $(rpc_idls))

ifdef RPC_COMPONENT
  _rpc_caller_factory_name = $(RPC_COMPONENT)Callers
  rpc_code_headers += I$(_rpc_caller_factory_name).h
  rpc_code_headers += T$(_rpc_caller_factory_name).h
  rpc_srcs += T$(_rpc_caller_factory_name).cpp
  _rpc_mock_caller_factory_name = T$(RPC_COMPONENT)MockCallers
  _rpc_mock_headers += mocks/$(_rpc_mock_caller_factory_name).h
  _rpc_mock_srcs += mocks/$(_rpc_mock_caller_factory_name).cpp
endif

_rpc_mock_headers += $(rpc_idl_files:I%.idl=mocks/TMock%.h)
_rpc_mock_srcs += $(rpc_idl_files:I%.idl=mocks/TMock%.cpp)

rpc_code_headers += $(rpc_idl_files:I%.idl=T%Caller.h)
rpc_code_headers += $(rpc_idl_files:I%.idl=T%Dispatcher.h)
rpc_code_headers += $(rpc_observer_idls:I%.idl=T%Adapter.h)

rpc_srcs += $(rpc_idl_files:I%.idl=T%Caller.cpp)
rpc_srcs += $(rpc_idl_files:I%.idl=T%Dispatcher.cpp)

RPC_SRCS = $(rpc_srcs)
RPC_OBJS += $(addprefix $(TARGET_OBJS_DIR)/,$(rpc_srcs:%.cpp=%.o))
ifeq ($(__build_test),true)
  ifdef RPC_COMPONENT
    __interface_mock_h_dist += $(_rpc_mock_headers)
  endif
  __interface_mock_obj += \
    $(addprefix $(TARGET_OBJS_DIR)/,$(_rpc_mock_srcs:%.cpp=%.o))
endif

CLEANUP_FILES += $(patsubst I%,T%Adapter.h,$(RPC_INTERFACE))
CLEANUP_FILES += $(patsubst I%,T%Base.h,$(RPC_INTERFACE))

INTERFACE_HEADERS += $(rpc_base_headers)
INTERFACE_HEADERS += $(rpc_code_headers)
endif # RPC_COMPONENT

include $(MAKESYSTEM)/idl.mk

# Make sure headers are disted before building as code often depend on
# header paths only available in dist.
_installed_headers_marker =
ifeq ($(COMPONENT_IS_3PP),)
ifdef INTERFACE_HEADERS
_installed_headers_marker = .installed_headers_marker

# Install headers for each enabled toolchain.
__install_headers_targets = \
  $(foreach tc, $(_toolchains_to_build), \
    .install_headers^$(tc))
$(_installed_headers_marker): $(__install_headers_targets)
	@touch $@
$(__install_headers_targets): $(INTERFACE_HEADERS)
endif
endif


### Automatic generation of mocks

include $(MAKESYSTEM)/mock.mk


### Install targets

ifneq ($(strip $(BIN_TARGETS)),)
_install_bins := .install_bins
endif

ifneq ($(strip $(CONFIG_TARGETS)),)
_install_configs := .install_configs
endif

ifneq ($(strip $(DOC_TARGETS)),)
_install_docs := .install_docs
endif

ifneq ($(strip $(INTERFACE_HEADERS)),)
_install_headers := .install_headers
ifneq ($(USE_FULL_SANDBOX),)
_install_headers_to_sandbox := .install_self_headers_to_sandbox
.PHONY: $(_install_headers_to_sandbox)
endif
endif

ifeq ($(__build_test),true)
  ifeq ($(TOOLCHAIN),)
    ifneq ($(__interface_mock_h_dist),)
      _install_mock_headers := .install_mock_headers
    endif
  endif
  ifeq ($(TOOLCHAIN),$(HOST_TOOLCHAIN_NAME))
    ifneq ($(__interface_mock_lib),)
      _install_mock_lib := .install_mock_lib
    endif
  endif
endif

ifneq ($(strip $(JAVA_TARGETS)),)
_install_java := .install_java
endif

ifneq ($(strip $(LIB_TARGETS)),)
_install_libs := .install_libs
endif

ifneq ($(strip $(MODULE_TARGETS)),)
_install_modules := .install_modules
endif

ifneq ($(strip $(PRODUCT_TARGETS)),)
  ifneq ($(filter $(SETUP_TARGETS),$(PRODUCT_TARGETS)),)
    _install_products_setup := .install_products_setup
  endif

  ifneq ($(filter-out $(SETUP_TARGETS),$(PRODUCT_TARGETS)),)
    _install_products := .install_products
  endif
endif

ifneq ($(strip $(RPC_INTERFACE)),)
_install_idl_headers := .install_idl_headers
endif

ifneq ($(strip $(SCRIPT_TARGETS)),)
_install_scripts := .install_scripts
endif

ifneq ($(strip $(KATT_TARGETS)),)
_install_katt := .install_katt
endif

ifneq ($(strip $(KATTENV_TARGETS)),)
_install_kattenv := .install_kattenv
endif


### Build rules

# Default rule: build required components first, then the current


PRINT_PROGRESS = printf '  %-11s %s\n'

ifdef KLOCWORK

ifeq ($(wildcard /usr/bin/kwcheck),)
$(info Please install klocwork-motorola by running:)
$(info )
$(info su -c 'yum install klocwork-motorola')
$(info )
$(error Error: klocwork-motorola not found)
endif

all tree_all local_all:
	@$(foreach dir, $(_klocwork_project_dirs), [ -d $(dir) ] && ) true; \
	if [ $$? -ne 0 ]; then \
	  rm -rf $(_klocwork_project_dirs); \
	  mkdir -p $(_klocwork_dir); \
	  kwcheck create -pd $(_klocwork_project_dir) -sd $(_klocwork_settings_dir); \
	fi
	@kwinject -c $(MAKESYSTEM)/klocwork/kwfilter.conf -u \
	   -o $(_klocwork_build_spec) $(MAKE) $@ KLOCWORK=
	@exit_code=$$?; \
	if [ $$exit_code -eq 0 ]; then \
	  $(PRINT_PROGRESS) ANALYZING code... ; \
	  kwcheck run -b $(_klocwork_build_spec) --report $(_klocwork_result) \
	          -pd $(_klocwork_project_dir) ; \
	  cat $(_klocwork_result); \
	fi

else # else branch of 'ifdef KLOCWORK'

all: tree_all
	@$(MAKE) local_all

tree_all: .requires
	@rm -f .failed_components
	@$(MAKE) -f .requires TREE_RULE=local_all INTERMEDIATE_COMPONENT=true; \
	exit_code=$$?; \
	if [ $$exit_code -ne 0 ]; then \
	  for component in $$(sort .failed_components); do \
	    echo "*** FAILED: Build of component $$component" >&2; \
	  done; \
	  exit $$exit_code; \
	fi

most: all

# Setup targets are built before proper targets and will do necessary setup for
# the build, like unpacking a tarball or generating code.
__setup_targets += $(SETUP_TARGETS) $(rpc_srcs) $(rpc_code_headers)
__setup_targets += $(NOARCH_TARGETS) .patches
__setup_targets += $(_installed_headers_marker) $(_install_configs) $(_install_scripts)
__setup_targets += $(_install_idl_headers) $(_install_docs)
__setup_targets += $(_install_products_setup) $(_rpc_mock_headers)
__setup_targets += $(_install_katt) $(_install_kattenv)
__setup_targets += $(_install_mock_headers)

.setup: .sources
ifneq ($(_enabled_toolchains),)
.setup: $(__setup_targets)
$(__setup_targets): | .sources
endif

ifneq ($(USE_SANDBOX),)
CLEANUP_FILES += $(__sandbox_dir)
CLEANUP_FILES += .sandbox_setup

# Trigger rebuild of sandbox if the set of enabled targets has changed.
ifneq ($(_enabled_targets),)  # Only rebuild sandbox in the setup phase.
  $(shell test "$(_enabled_targets)" = "$$(cat .sandbox_setup 2>/dev/null)" \
          || rm -f .sandbox_setup)
endif

.sandbox_setup: .requires
	@rm -rf $(__sandbox_dir)
	@$(MAKESYSTEM)/build_sandbox $(COMPONENT) ".requires_list" $(USE_FULL_SANDBOX)
	@echo "$(_enabled_targets)" >.sandbox_setup
endif

__slashless_component = $(subst /,_,$(subst _,__,$(__component_fs_name)))
__distname = $(__slashless_component).dist

ifeq ($(TARGET),)
# No target selected: run through the different targets and flavours. Calls
# ".target^$(target)^$(flavour)", where $(flavour) may be empty.

__targets := \
  $(foreach target, $(_targets_to_build), \
    $(if $($(call _uc,$(target))_FLAVOURS)$(FLAVOURS), \
      $(foreach flavour, $($(call _uc,$(target))_FLAVOURS) $(FLAVOURS), \
        .target^$(target)^$(flavour)), \
      .target^$(target)^$(empty)))

$(__targets): .setup

.do_install: $(__targets)

COMPONENTCACHE_COMPATIBILITY_MODE = 3
COMPONENTCACHE = /usr/bin/componentcache

ifeq ($(MAKECMDGOALS),local_all)
ifeq ($(NO_COMPONENTCACHE),)
ifndef USE_GCOV
ifneq ($(wildcard $(COMPONENTCACHE)),)
USE_COMPONENTCACHE = true
endif
endif
endif
endif

ifeq ($(USE_COMPONENTCACHE),)

ifdef USE_SANDBOX
.setup: .sandbox_setup
endif

# gcovparse needs .sources even if there is nothing to build due to disabled
# toolchains.
ifdef USE_GCOV
  local_all: .sources
endif

local_all: $(__targets)
# For non-update builds, generate and dist a file with accumulated source
# dependencies for the check_requires postbuild script to analyze.
	@deps_file=$(_depfiles_dir)/deps; \
	if [ ! -f $$deps_file ]; then \
	  d_files="$$(ls $(_depfiles_dir)/*.d 2>/dev/null)"; \
	  if [ -n "$$d_files" ]; then \
	    cat $$d_files > $$deps_file; \
	    $(MAKESYSTEM)/dist_targets --rename \
	      $$deps_file $(DIST_DIR)/deps/$(__slashless_component).d; \
	  else \
	    mkdir -p $(_depfiles_dir); \
	    touch $$deps_file; \
	  fi; \
	fi
	@if [ -f .test_time ]; then \
	  $(MAKESYSTEM)/dist_targets --rename .test_time \
	    $(DIST_DIR)/testtime/$(__slashless_component).txt; \
	  rm -f .test_time; \
	fi
	@touch .dist
	@if [ "$$(echo .dist.*)" != ".dist.*" ]; then \
	  grep -v '^testtime/' .dist | sort -u -o .dist .dist.* -; \
	fi
	@mkdir -p $(DIST_DIR)/distfiles
	@cp .dist $(DIST_DIR)/distfiles/$(__distname)
	@rm -f .dist.*
	$(_gcov_parse)
ifneq ($(COMPONENT_IS_3PP)$(COMPONENT_HAS_KTVLICENSE),)
	@$(MAKESYSTEM)/check_3pp_ktv_license $(MAKESYSTEM)/print_progress
endif
	@rmdir $(_all_available_toolchains) 2>/dev/null || true
else
local_all:
	@python2 -S $(COMPONENTCACHE) make-local-all $(COMPONENTCACHE_COMPATIBILITY_MODE) $(MAKE) $(__component_fs_name) $(BSG_SRC_ABS) $(DIST_DIR) $(MAKESYSTEM)/print_progress
endif

# .target^<target>^<flavour>
.target^%: TARGET = $(call _nth,2,^,$@)
.target^%: FLAVOUR = $(call _nth,3,^,$@)
.target^%: TOOLCHAIN = $(call _toolchain_for_target,$(TARGET))
.target^%: DEVICE = $(call _device_for_target,$(TARGET))
.target^%: .makefile .sources
	@$(PRINT_PROGRESS) BUILD "$(COMPONENT) [$(TARGET)$(if $(FLAVOUR),/$(FLAVOUR))]"
	@TARGET=$(TARGET) FLAVOUR=$(FLAVOUR) TOOLCHAIN=$(TOOLCHAIN) DEVICE=$(DEVICE) \
	DISABLE_TESTS=$(DISABLE_TESTS) $(MAKE) local_all

include $(MAKESYSTEM)/binfiles.mk

else # else branch of 'ifeq ($(TARGET),)'
# Target is selected: build it

ifneq ($(filter $(_all_available_toolchains), $(TOOLCHAIN)),)
  TARGET_OBJS_DIR := $(TOOLCHAIN)$(if $(DEVICE),/$(DEVICE))$(if $(FLAVOUR),/$(FLAVOUR))
  $(shell mkdir -p $(TARGET_OBJS_DIR))
else
  TARGET_OBJS_DIR = .
endif

local_all: .do_install tests
ifeq ($(filter $(NOARCH_TOOLCHAIN_NAME) $(STB_NOARCH_TOOLCHAIN_NAME),$(TOOLCHAIN)),)
ifeq ($(COMPONENT_IS_3PP),)
local_all: $(TARGET_DIR)/.libdepends
endif
endif

ifndef COMPONENT_IS_3PP
  ifneq ($(INTERFACE_HEADERS),)
    ifeq ($(INTERFACE_PATH),)
      $(error Error: Please define an INTERFACE_PATH for INTERFACE_HEADERS)
    endif
  endif
endif

# As binaries may depend on libraries built in the same component we
# must make sure libraries are built first.
$(BIN_TARGETS) $(MODULE_TARGETS) $(OTHER_TARGETS) $(TEST_TARGETS): | $(_install_libs)

.do_install: $(if $(FLAVOURS), $(foreach flavour, $(FLAVOURS), .install_flavour^$(flavour)), .install)

endif # end of else branch of 'ifeq ($(TARGET),)'

endif # end of else branch of 'ifdef KLOCWORK'

$(PRODUCT_TARGETS): REQUIRE_FILE=$(CURDIR)/.requires
export REQUIRE_FILE  # Used by install_parts

dist_clean:
	@if [ -f .dist ]; then \
	  $(MAKESYSTEM)/dist_clean $(DIST_DIR); \
	  rm -f .dist $(DIST_DIR)/distfiles/$(__distname); \
	fi

# Install files

# Install for all flavours if FLAVOURS is set. FLAVOURS is unset if FLAVOUR is
# set (see targetsetup.mk).

export COMPONENT_ROOT = $(CURDIR)

.install_flavour^%:
	@FLAVOUR=$(call _nth,2,^,$@) $(MAKE) .install

# .install_headers^target
.install_headers^%: TARGET = $(call _nth,2,^,$@)
.install_headers^%: TOOLCHAIN = $(call _toolchain_for_target,$(TARGET))
.install_headers^%:
	@TARGET=$(TARGET) TOOLCHAIN=$(TOOLCHAIN) $(MAKE) .install_headers

.install: .others
# Headers are installed in the setup step for non-3pp's.
ifneq ($(COMPONENT_IS_3PP),)
.install: $(_install_headers)
endif
.install: $(_install_scripts)
.install: $(_install_headers_to_sandbox)
.install: $(_install_mock_headers) $(_install_mock_lib)
.install: $(_install_libs) $(_install_bins)
.install: $(_install_java) $(_install_configs)
.install: $(_install_products) $(_install_idl_headers) $(_install_docs)
.install: $(_install_modules) $(_install_kattenv)

$(_install_bins): $(BIN_TARGETS)
	@$(MAKESYSTEM)/dist_targets $(BIN_TARGETS) $(TARGET_INSTALL_DIR)/$(if $(DEVICE),$(DEVICE)/)bin

$(_install_modules): $(MODULE_TARGETS)
	@$(MAKESYSTEM)/dist_targets $(MODULE_TARGETS) $(TARGET_INSTALL_DIR)/$(if $(DEVICE),$(DEVICE),bin)/modules

$(_install_scripts): $(SCRIPT_TARGETS)
	@TOOLCHAIN= DEVICE= FLAVOUR= $(MAKESYSTEM)/dist_targets $(SCRIPT_TARGETS) $(INSTALL_DIR)/bin

__katt_metadata = .katt_metadata
CLEANUP_FILES += $(__katt_metadata)

$(__katt_metadata): $(KATT_TARGETS) | .sources
	@$(DIST_DIR)/bin/create_katt_tests_metadata $(COMPONENT) $@ $^

$(_install_katt): $(__katt_metadata)
	@TOOLCHAIN= DEVICE= $(MAKESYSTEM)/dist_targets --rename $< $(INSTALL_DIR)/katt/metadata/$(__slashless_component).py
	@TOOLCHAIN= DEVICE= $(MAKESYSTEM)/dist_targets $(KATT_TARGETS) $(INSTALL_DIR)/katt/testcases/$(COMPONENT) --preserve-source-dir=true

$(_install_kattenv): $(KATTENV_TARGETS)
	@TOOLCHAIN= DEVICE= $(MAKESYSTEM)/dist_targets $(KATTENV_TARGETS) $(DIST_DIR)/katt/environment/$(KATTENV_PATH) --preserve-source-dir=$(KATTENV_PRESERVE_SOURCE_DIR)

$(_install_libs): $(LIB_TARGETS)
	@$(MAKESYSTEM)/dist_targets $(LIB_TARGETS) $(TARGET_INSTALL_DIR)/$(if $(DEVICE),$(DEVICE)/)lib

$(_install_products_setup): $(filter $(SETUP_TARGETS),$(PRODUCT_TARGETS))
	@TOOLCHAIN= DEVICE= $(MAKESYSTEM)/dist_targets $(filter $(SETUP_TARGETS),$(PRODUCT_TARGETS)) $(DIST_DIR)/products

$(_install_products): $(filter-out $(SETUP_TARGETS), $(PRODUCT_TARGETS))
	@$(MAKESYSTEM)/dist_targets $(filter-out $(SETUP_TARGETS), $(PRODUCT_TARGETS)) $(DIST_DIR)/products

$(_install_java): $(JAVA_TARGETS)
	@$(MAKESYSTEM)/dist_targets $(JAVA_TARGETS) $(INSTALL_DIR)/java

$(_install_headers): $(INTERFACE_HEADERS)
	@DEVICE= $(MAKESYSTEM)/dist_targets $(INTERFACE_HEADERS) $(TARGET_INSTALL_DIR)/include/$(INTERFACE_PATH) --preserve-source-dir=$(INTERFACE_PRESERVE_SOURCE_DIR)

$(_install_headers_to_sandbox): $(INTERFACE_HEADERS) $(__interface_mock_h_dist)
	@$(MAKESYSTEM)/build_sandbox $(COMPONENT) self_exported_headers $(TARGET_INSTALL_DIR)/include/$(INTERFACE_PATH) $(INTERFACE_HEADERS)
ifneq ($(__interface_mock_h_dist),)
	@$(MAKESYSTEM)/build_sandbox $(COMPONENT) self_exported_headers $(TARGET_INSTALL_DIR)/include/$(INTERFACE_PATH) $(__interface_mock_h_dist)
endif

$(_install_mock_headers): $(__interface_mock_h_dist)
	@DEVICE= $(MAKESYSTEM)/dist_targets $(__interface_mock_h_dist) $(DIST_DIR)/$(HOST_TOOLCHAIN_NAME)/include/$(INTERFACE_PATH)/mocks --preserve-source-dir=$(INTERFACE_PRESERVE_SOURCE_DIR)

$(_install_mock_lib): $(__interface_mock_lib)
	DEVICE= $(MAKESYSTEM)/dist_targets $(__interface_mock_lib) $(TARGET_INSTALL_DIR)/lib

$(_install_configs): $(CONFIG_TARGETS)
	@TOOLCHAIN= DEVICE= FLAVOUR= $(MAKESYSTEM)/dist_targets $(CONFIG_TARGETS) $(INSTALL_DIR)/config/$(CONFIG_PATH) --preserve-source-dir=$(CONFIG_PRESERVE_SOURCE_DIR)

$(_install_docs): $(DOC_TARGETS)
	@TOOLCHAIN= DEVICE= FLAVOUR= $(MAKESYSTEM)/dist_targets $(DOC_TARGETS) $(INSTALL_DIR)/doc/$(DOC_PATH)/$(COMPONENT) --preserve-source-dir=$(DOC_PRESERVE_SOURCE_DIR)

__quick_targets := help local_clean 3pp_local_clean dist_clean platforms.mk $(BOOT_IMAGE_CONFIG) $(HACK_TARGETS) $(KIT_CONFIG)
__quick_targets += getvar-%

__wildcard_variables = TOI_IDLS SRCS INTERFACE_HEADERS


.sources: .makefile
ifndef TARGET # Only consider cleaning in the setup phase to avoid parallel
              # build problems when $(__wildcard_variables) expands differently
              # in target build submakes.
ifndef COMPONENT_IS_3PP
ifneq ($(if $(MAKECMDGOALS),$(filter-out $(__quick_targets),$(MAKECMDGOALS)),true),)
	@temp=$$(mktemp $@.XXXXXX); \
	echo $(sort $(foreach v,$(__wildcard_variables),$($(v)))) > $$temp; \
	if [ -f $@ ] && ! diff -q $@ $$temp >/dev/null; then \
	  $(PRINT_PROGRESS) DISTCLEAN "$(CURDIR) (new sources)"; \
	  mv $$temp $@; \
	  $(MAKE) dist_clean; \
	  if ! $(MAKE) local_clean; then rm -f $@; fi; \
	else \
	  mv $$temp $@; \
        fi
endif
endif
endif

.makefile: Makefile
ifneq ($(if $(MAKECMDGOALS),$(filter-out $(__quick_targets),$(MAKECMDGOALS)),true),)
	@$(PRINT_PROGRESS) DISTCLEAN "$(CURDIR) (new Makefile)"
	@touch $@
	@$(MAKE) dist_clean
	@if $(MAKE) local_clean; then true; else rm -f $@; fi
endif

# Generate library dependencies. These make sure that we relink if a static
# library on which we depend has been rebuilt.
MAKE_LIB_DEPEND = \
	$(MAKESYSTEM)/parse_link_map $(file) $(file).linkmap \
	  > $(TARGET_DIR)/.libdepends_$(notdir $(file))

ifeq ($(COMPONENT_IS_3PP),)
$(TARGET_DIR)/.libdepends: $(BIN_TARGETS) $(LIB_TARGETS) $(TEST_TARGETS)
	@$(foreach file,$(filter-out %.a,$?),$(MAKE_LIB_DEPEND) ; )
else
$(TARGET_DIR)/.libdepends:
endif


# Other targets
.others: $(OTHER_TARGETS)


# Build directory dependencies into .requires which is used as a Makefile for
# tree builds

# Used by build_requires when parsing kit/bootimage configuration files
export KITS_DIR = $(BSG_SRC_ABS)
export BOOT_IMAGE_DIR = $(BSG_SRC_ABS)/products/ip-stb/boot_image

.requires_depend: .requires ;
.requires_setup: .requires ;

.requires: .makefile
ifneq ($(if $(MAKECMDGOALS),$(filter-out $(__quick_targets),$(MAKECMDGOALS)),true),)
	@$(PRINT_PROGRESS) DEPS "$(CURDIR)"; \
    PERL5LIB=$(BSG_SRC_ABS)/bootimage/tools:$(BSG_SRC_ABS)/bootimage/iip:$(MAKESYSTEM) \
      $(MAKESYSTEM)/build_requires \
	    $(addprefix --skip-dir , \
	    $(notdir $(DIST_DIR)) \
	    $(_all_available_toolchains) \
	    3pp testcases unittests) \
	  $(MAKESYSTEM) $(BSG_SRC_ABS) $(COMPONENT)
endif

# Clean up base rule
.local_clean:
	$(call cmdheader,CLEAN,$(CURDIR), \
	  rm -rf $(filter-out /%,$(CLEANUP_FILES)) \
		 $(filter $(CURDIR)/%,$(CLEANUP_FILES)))


# Clean up default rule
# Can be overridden in the following way
# local_clean: .local_clean
#        <Add extra cleanup here>
# If you just want to remove extra files do it this way
# CLEANUP_FILES += <files>
clean: tree_clean
	@$(MAKE) local_clean

3pp_local_clean local_clean: .local_clean

3pp_tree_clean tree_clean: .requires
	@TREE_RULE=local_clean \
	$(MAKE) -f .requires

remove_hidden_files:
	find . -regex '.*/\.depend\(\.bak\)?\|.*/\.requires_?.*\|.*/\.libdepends_?.*\|.*/\.linkmap_.*\|.*/\.makefile\|.*/\.run_tests\|.*/\.install_depends.*' -exec rm -f {} \;

test_target_decorator :=

ifneq ($(DEVICE),)
ifneq ($(FLAVOUR),)
  test_target_decorator := $(test_target_decorator)_$(FLAVOUR)_$(DEVICE)
else
  test_target_decorator := $(test_target_decorator)_$(DEVICE)
endif
else
ifneq ($(FLAVOUR),)
  test_target_decorator := $(test_target_decorator)_$(FLAVOUR)
endif
endif

ifneq ($(USE_VALGRIND),)
  VALGRIND_FLAGS = --leak-check=full --show-reachable=yes -v --error-limit=no --gen-suppressions=all
  __suppression_file=$(shell svn pg --strict kbs:valgrind_suppression_file $(BSG_SRC))
  ifneq ($(__suppression_file),)
    VALGRIND_FLAGS +=  --suppressions=$(BSG_SRC)/$(__suppression_file)
  endif
  VALGRIND = valgrind --error-exitcode=1 $(VALGRIND_FLAGS)
  test_target_decorator := $(test_target_decorator)_valgrind
endif

ifneq ($(filter $(_all_available_toolchains),$(TOOLCHAIN)),)
  RUN_TESTS=$(TARGET_OBJS_DIR)/.run_tests$(test_target_decorator)
else
  RUN_TESTS=.run_tests$(test_target_decorator)
endif

# Build all test programs, run code coverage analysis after the autotests are
# done.
tests: $(RUN_TESTS) .do_install

# Runs and builds all automatic tests. Tests are killed if they haven't
# finished after $(__unit_test_kill) seconds. The target is "built" only if all
# tests complete successfully.

test_target_counter = $(TARGET_DIR)/.run_tests_counter$(test_target_decorator)

ifneq ($(VERBOSE),)
# The magic below pipes the output from the test to tee (to get the output on
# the screen and in a file simultaneous) and makes the exit code from the test
# be the exit code of the whole pipe. It does the same as "set -o pipefail" but
# without being bash specific.
#
# From http://www.spinics.net/lists/dash/msg00165.html:
# Basically, save the original stdout in fd 3, then use a command substitution
# where we save the substitution's stdout in fd 4, restore the original stdout,
# and perform the pipe. Then, by modifying the first command of the pipe to
# feed the result of the command substitution, we are now able to guarantee
# non-zero status if either (or both) the test or tee fail.
run_test_prelude = exec 3>&1; s=$$(exec 4>&1 >&3; {
run_test_logger = 2>&1 4>&-; echo $$? >&4; } | tee -a $(RUN_TESTS).tmp); test $$s -eq 0
else
run_test_logger = >> $(RUN_TESTS).tmp 2>&1
endif

# META: ifndef OSSK || BOSSK
RUN_TEST_TARGET = $(PRINT_PROGRESS) TEST "$(test)"; \
	$(run_test_prelude) \
	if [ -t 1 ]; then export GTEST_COLOR=yes; fi; \
	MALLOC_CHECK_=3 LIBC_FATAL_STDERR_=1 \
	$(TEST_TARGET_ENV) \
	  command time -f "%e %U %S $(COMPONENT) $(test)" \
	               -a -o .test_time \
	    $(HOST_DIST_DIR)/bin/testrunner \
	      $(__unit_test_warning) $(__unit_test_kill) \
	      $(VALGRIND) \
	      ./$(test) $(run_test_logger) && \
	        expr $$(cat $(test_target_counter)) + 1 > $(test_target_counter)

# Don't run long tests on slow build servers. HOSTSPEED is set by build_system
# to a positive integer.
ifneq ($(COMPONENT_LONG_TEST),)
  ifneq ($(filter 1 2,$(HOSTSPEED)),)
    __no_tests_reason = not run because of slow build server
  endif
endif

ifdef NO_TESTS
  __no_tests_reason = not run because NO_TESTS is defined
endif

ifdef __no_tests_reason
define RUN_TEST_TARGETS
	@$(foreach _test,$?,$(PRINT_PROGRESS) TEST "$(_test) $(__no_tests_reason)"; )
endef
else
define RUN_TEST_TARGETS
	@echo "0" > $(test_target_counter)
	@rm -f $(RUN_TESTS).tmp
	@$(foreach test,$?,$(RUN_TEST_TARGET); ) true
	@if [ "$$(cat $(test_target_counter))" = "$(words $?)" ]; then \
	  test ! "$(VERBOSE)" && \
	    sed -rn 's/Test Result: SUCCESS.*|\[  PASSED  \].*|YOU HAVE [0-9]+ DISABLED TESTS?/&/p' $(RUN_TESTS).tmp \
	      | { if [ -t 1 ]; then sed -r 's/DISABLED TESTS?/&\x1b\[m/'; else cat; fi; }; \
	  mv $(RUN_TESTS).tmp $(RUN_TESTS) ; \
	else \
	  test ! "$(VERBOSE)" && cat $(RUN_TESTS).tmp ; \
	  exit 1 ; \
	fi
	@rm -f $(test_target_counter)
endef
endif
# META: endif

ifneq ($(TEST_TARGETS),)
$(TEST_TARGETS): CXXFLAGS += -Wno-deprecated-declarations
$(RUN_TESTS): $(TEST_TARGETS)
# META: ifndef OSSK || BOSSK
	$(call RUN_TEST_TARGETS)
# META: endif
else
$(RUN_TESTS):
endif

# Run local KATT tests
ifeq ($(VERBOSE),)
_verbose_flag=
else
_verbose_flag=--verbose
endif

# By default we try all testcases
_level_option=--level

ifneq ($(KATT_TESTS),)
_tests_to_run = $(KATT_TESTS)
# We ignore KATT keywords for KATT_TESTS
_ignore_disabled_flag=--ignore_disabled
_ignore_requires_flag=--ignore_requires
else
ifneq ($(KATT_TARGETS),)
# Now we simulate level 1 tests
_tests_to_run = $(KATT_TARGETS)
_test_level=$(_level_option) 1

ifeq ($(IGNORE_DISABLED),)
_ignore_disabled_flag=
else
_ignore_disabled_flag=--ignore_disabled
endif

ifeq ($(IGNORE_REQUIRES),)
_ignore_requires_flag=
else
_ignore_requires_flag=--ignore_requires
endif

endif
endif

ifeq ($(PRESERVE_LOGS),)
_preserve_logs_flag=
else
_preserve_logs_flag=--preserve_logs
endif

# Override level
ifneq ($(TEST_LEVEL),)
_test_level=$(_level_option) $(TEST_LEVEL)
endif


local_katt_tests: $(_tests_to_run)
ifneq ($(_tests_to_run),)
	$(Q)python2 $(DIST_DIR)/bin/run_katt_tests.py $(_verbose_flag) $(_ignore_disabled_flag) $(_ignore_requires_flag) $(_test_level) $(_preserve_logs_flag) --environment $(DIST_DIR)/katt/environment $(_tests_to_run)
else
	$(Q)echo "No tests specified as KATT_TARGETS in Makefile or by KATT_TESTS parameter."
endif

katt_tests: .requires
	@TREE_RULE=local_katt_tests \
	$(MAKE) -f .requires

# Print the used versions of various development tools
version:
	@echo "bash v $$BASH_VERSION"
	@echo " "
	$(CXX) -v
	@echo " "
	$(AR) V
	@echo " "
	$(MAKE) -v

# Print help information
help:
	@more $(MAKESYSTEM)/doc/README.mmd


### Declare some targets as phony

.PHONY: .target*
.PHONY: .setup
.PHONY: .sources
.PHONY: .patches
.PHONY: remove_hidden_files
.PHONY: all local_all tree_all local_clean clean tests dist_clean
.PHONY: katt_tests local_katt_tests
.PHONY: .others version
.PHONY: .do_install .install .install_flavour^* .install_headers^*
.PHONY: $(_install_bins) $(_install_scripts) $(_install_libs) $(_install_products)
.PHONY: $(_install_headers) $(_install_configs) $(_install_idl_headers)
.PHONY: $(_install_docs) $(_install_modules)
.PHONY: $(_install_mock_headers) $(_install_mock_lib)
.PHONY: $(_install_java) $(_install_katt) $(_install_kattenv)
.PHONY: most

.SUFFIXES:


### Generic rules

# Link rule, used to build binaries. Use it this way
# $(target): $(objs)
#        $(LINK)

# If any source is a cpp file use $(CXX) to link otherwise use $(CC)
LINKER = $(__link_wrapper) $(if $(filter .cpp,$(suffix $(SRCS) $(rpc_srcs))),$(CXX),$(CC))

# Workaround weird problem with uclibc.
ifneq ($(_use_klibc),true)
  __lpthread = $(if $(filter pthread,$(REMOVE_LIBS)),,-lpthread)
endif

ifeq ($(NO_AS_NEEDED),)
  __as_needed = -Wl,--as-needed
else
  __as_needed = -Wl,--no-as-needed
endif

ifeq ($(COMPONENT_IS_3PP),)
LINKMAP = -Wl,-Map,$@.linkmap
endif

__unique = $(if $1,$(strip $(word 1,$1) $(call $0,$(filter-out $(word 1,$1),$1))))
__ldfiles = $(call __unique,$(strip $(subst :, ,$(subst $(subst $(space),:,$(LIBDEPENDS_$(@F))),,$(subst $(space),:,$+)))))
BASIC_LDOPTS = -o $@ $(KLIBC_BASE) $(filter %.o,$(__ldfiles)) $(filter %.a,$(__ldfiles)) $(__lpthread) $(__as_needed) $(filter %.so,$(__ldfiles))
BASIC_LDOPTS += $(LDFLAGS) $(filter-out $(addprefix -l,$(REMOVE_LIBS)),$(_auto_ldflags)) $(KLIBC_LDFLAGS) $(LINKMAP) $(LDLIBS) $(KLIBC_LDLIBS)
BASIC_LDOPTS += $(if $(findstring $(CC),$(LINKER)),$(CFLAGS),$(CXXFLAGS))

ifeq ($(VERBOSE),)
cmdheader = @$(PRINT_PROGRESS) "$(1)" "$(2)"; $(3)
else
define cmdheader
  @$(PRINT_PROGRESS) "$(1)" "$(2)"
  $(3)
endef
endif

LINK = $(call cmdheader,LINK,$@,$(LINKER) $(BASIC_LDOPTS))

# LINK_C overrides the automatic linker selection provided with LINK and always
# uses gcc. Useful when building both C and C++ targets in the same component:
LINK_C = $(call cmdheader,LINK_C,$@,$(CC) $(BASIC_LDOPTS))

LINK_SO = $(call cmdheader,LINK_SO,$@, $(LINKER) $(BASIC_LDOPTS) -shared -Wl$(comma)-soname$(comma)$(notdir $@))

LINK_A = $(call cmdheader,LINK_A,$@,$(AR) cru $@ $^)

BUILD_JAR = $(call cmdheader,BUILD_JAR,$@, \
	mkdir -p $(dir $@) && \
	$(JAVAC) $(JFLAGS) -d $(dir $@) $^ && \
	$(JAR) -cf $@ $(addprefix $(dir $@)/,$(notdir $(^:%.java=%.class))))

# Link linux kernel module

ifdef DEVICE
  _modpost = $(_module_include_dir)/scripts/mod/modpost \
             -i $(_module_include_dir)/Module.symvers
  KSYMHASH := $(_module_include_dir)/scripts/mod/ksymhash
  KSYMHASH := $(if $(wildcard $(KSYMHASH)),$(KSYMHASH),true)
else
  _modpost = false
  KSYMHASH = false
endif

ifeq ($(TOOLCHAIN),$(BCM45_TOOLCHAIN_NAME))
  _module_link_ld_options = -G 0
endif

ifneq ($(TOOLCHAIN),$(ST40_TOOLCHAIN_NAME))
  # To make kernel modules build ok in Linux 3.x:
  _module_link_secondary_ld_options = -T $(_module_include_dir)/scripts/module-common.lds
endif

MODULE_LINK = \
  $(call cmdheader,LINK_MODULE,$@, \
    mkdir -p $(dir $@) && \
    $(LD) $(_module_link_ld_options) -r -o $@.tmp $(filter %.o,$^) $(MODULE_LDFLAGS) && \
    $(_modpost) -w $@.tmp >/dev/null 2>&1 && \
    $(CC) -c $(MODULE_CFLAGS) $(MODULE_CPPFLAGS) $(CPPFLAGS) $@.tmp.mod.c -o $@.tmp.mod.o && \
    $(LD) $(_module_link_ld_options) -r -o $@ $@.tmp $@.tmp.mod.o $(MODULE_LDFLAGS) $(_module_link_secondary_ld_options) && \
    $(KSYMHASH) $@ && \
    $(STRIP) -S $@)

# Assemble non shared code with -mno-shared on mips.
ifeq ($(TOOLCHAIN),$(BCM45_TOOLCHAIN_NAME))
$(BIN_TARGETS): COMMON_FLAGS += -Wa,-mno-shared
endif

ifeq ($(_use_klibc),true)
KLIBC_FLAGS += -Wno-long-long -fno-common -ffreestanding -fno-builtin -ffunction-sections -fdata-sections

ifneq ($(TOOLCHAIN),$(BCM45_TOOLCHAIN_NAME))
  KLIBC_FLAGS += -fgnu89-inline
endif

KLIBC_CPPFLAGS += -D__KLIBC__=1
KLIBC_CPPFLAGS += \
	-isystem $(TOOLCHAIN_3PP_DIST_DIR)/include/klibc \
	-isystem $(TOOLCHAIN_3PP_DIST_DIR)/include/klibc/bits32 \
	-isystem $(TOOLCHAIN_3PP_DIST_DIR)/include \
	-I$(CURDIR)/include
ifeq ($(TOOLCHAIN),$(ST40_TOOLCHAIN_NAME))
  KLIBC_CPPFLAGS += -isystem $(TOOLCHAIN_3PP_DIST_DIR)/include/klibc/arch/sh
else ifneq ($(filter $(TOOLCHAIN),$(BCM15_TOOLCHAIN_NAME) $(ST9_TOOLCHAIN_NAME)),)
  KLIBC_CPPFLAGS += -isystem $(TOOLCHAIN_3PP_DIST_DIR)/include/klibc/arch/arm
else
  KLIBC_CPPFLAGS += -isystem $(TOOLCHAIN_3PP_DIST_DIR)/include/klibc/arch/mips
endif

KLIBC_LDFLAGS += -nodefaultlibs -nostdlib -nostdinc -nostartfiles -static -Wl,--gc-sections

# ARM EABI specifics is that idiv*() in libgcc have dependency on
# raise() and abort() which are located in libkc_klibc itself
# This gives us a circular dependency every time we need a div operation
# Known examples are
# firmware/boot/cmds/multicast
# firmware/boot/cmds/tftp
ifneq ($(filter $(TOOLCHAIN),$(BCM15_TOOLCHAIN_NAME) $(ST9_TOOLCHAIN_NAME)),)
  KLIBC_LDLIBS += -Wl,--start-group -lkc_klibc -lgcc -Wl,--end-group
else
  KLIBC_LDLIBS += -lkc_klibc -lgcc
endif

KLIBC_BASE += $(TOOLCHAIN_3PP_DIST_DIR)/lib/klibcbase.o

endif # ifeq ($(_use_klibc),true)

# Compile potentially shared code with -fPIC.
$(LIB_TARGETS): COMMON_FLAGS += -fPIC

# Set up rpath for test targets unless compiling a standalone binary.
ifneq ($(PRODUCES_STANDALONE_BINARY),)
  $(TEST_TARGETS): RPATH += -Wl,-rpath,$(DIST_DIR_ABS)/$(TOOLCHAIN)/lib
  $(TEST_TARGETS): RPATH += -Wl,-rpath,$(DIST_DIR_ABS)/$(TOOLCHAIN)/3pp/lib
endif

# AVR

ifeq ($(TOOLCHAIN),$(AVR_TOOLCHAIN_NAME))
CFLAGS = -pipe -g -Os -Wall -Wextra -std=gnu99
CFLAGS += -ffreestanding -fno-inline-small-functions -fno-split-wide-types -fno-tree-scev-cprop -fpack-struct -fshort-enums -funsigned-bitfields -funsigned-char
CPPFLAGS =
LDFLAGS = -Wl,--relax
BASIC_LDOPTS = -o $@ $(__ldfiles) $(CFLAGS)
endif


### Rules for automatic mock generation

include $(MAKESYSTEM)/mockrules.mk


### Source dependencies

_depfiles_dir := .depfiles
CLEANUP_FILES += $(_depfiles_dir)

$(__targets): | $(_depfiles_dir)

# .sources might remove .depfiles, so build .sources before .depfiles.
$(_depfiles_dir): .sources
	@mkdir -p $@

_flatten_path = $(subst /,_,$(subst ./,,$(1)))
_d_file = $(_depfiles_dir)/$(patsubst %.o,%.d,$(call _flatten_path,$@))
DEPSETUP = -MD -MP -MF $(_d_file) -MT $@

# Only enable gcov for ordinary object files (not MODULE_TARGETS)
$(BIN_TARGETS) $(LIB_TARGETS) $(TEST_TARGETS): _enable_gcov = true

### .cpp -> .o
%.o: %.cpp
	@$(PRINT_PROGRESS) CXX "$@"
	$(Q)$(CXX) -c $(CXXFLAGS) $(CPPFLAGS) $< -o $@ $(DEPSETUP)
	$(_gcov_store)

$(TARGET_OBJS_DIR)/%.o: %.cpp
	@$(PRINT_PROGRESS) CXX "$@"
	@mkdir -p $(dir $@)
	$(Q)$(CXX) -c $(CXXFLAGS) $(CPPFLAGS) $< -o $@ $(DEPSETUP)
	$(_gcov_store)

### .cc -> .o
%.o: %.cc
	@$(PRINT_PROGRESS) CXX "$@"
	$(Q)$(CXX) -c $(CXXFLAGS) $(CPPFLAGS) $< -o $@ $(DEPSETUP)
	$(_gcov_store)

$(TARGET_OBJS_DIR)/%.o: %.cc
	@$(PRINT_PROGRESS) CXX "$@"
	@mkdir -p $(dir $@)
	$(Q)$(CXX) -c $(CXXFLAGS) $(CPPFLAGS) $< -o $@ $(DEPSETUP)
	$(_gcov_store)

### .c -> .o
%.o: %.c
	@$(PRINT_PROGRESS) CC "$@"
	$(Q)$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@ $(DEPSETUP)
	$(_gcov_store)

$(MODULE_SRCS:.c=.o): %.o: %.c
	@$(PRINT_PROGRESS) CC "$@"
	$(Q)$(CC) -c $(MODULE_CFLAGS) $(MODULE_CPPFLAGS) $(CPPFLAGS) $< -o $@ $(DEPSETUP)

$(TARGET_OBJS_DIR)/%.o: %.c
	@$(PRINT_PROGRESS) CC "$@"
	@mkdir -p $(dir $@)
	$(Q)$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@ $(DEPSETUP)
	$(_gcov_store)

$(addprefix $(TARGET_OBJS_DIR)/,$(MODULE_SRCS:.c=.o)): $(TARGET_OBJS_DIR)/%.o: %.c
	@$(PRINT_PROGRESS) CC "$@"
	@mkdir -p $(dir $@)
	$(Q)$(CC) -c $(MODULE_CFLAGS) $(MODULE_CPPFLAGS) $(CPPFLAGS) $< -o $@ $(DEPSETUP)

$(TARGET_OBJS_DIR)/%.no: %.c
	@$(PRINT_PROGRESS) CC "$@"
	@mkdir -p $(dir $@)
	$(Q)$(CC) -c $(CFLAGS) $(NOPIC) $(CPPFLAGS) $< -o $@

### .S -> .o
%.o: %.S
	@$(PRINT_PROGRESS) CC "$@"
	$(Q)$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

$(TARGET_OBJS_DIR)/%.o: %.S
	@$(PRINT_PROGRESS) CC "$@"
	@mkdir -p $(dir $@)
	$(Q)$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@


### .s -> .o
%.o: %.s
	@$(PRINT_PROGRESS) CC "$@"
	$(Q)$(CC) -c $(CFLAGS) $(CPPFLAGS) $< -o $@

$(TARGET_OBJS_DIR)/%.o: %.s
	@$(PRINT_PROGRESS) CC "$@"
	@mkdir -p $(dir $@)
	$(Q)$(CC) -c $(CFLAGS) $(CPPFLAGS) -x assembler-with-cpp $< -o $@


### .msc -> .png
%.png: %.msc
	@$(PRINT_PROGRESS) MSCGEN "$@"
	$(Q)$(MSCGEN) -T png -i $< -o $@

$(TARGET_OBJS_DIR)/%.png: %.msc
	@$(PRINT_PROGRESS) MSCGEN "$@"
	@mkdir -p $(dir $@)
	$(Q)$(MSCGEN) -T png -i $< -o $@


# Kreatel idl
ifneq ($(RPC_INTERFACE),)

ifdef RPC_COMPONENT

$(_install_headers): install_rpc_helper_headers

install_rpc_helper_headers: $(rpc_srcs)
	$(MAKESYSTEM)/dist_targets T*Base.h $(TARGET_INSTALL_DIR)/include/$(_platform_helpers_interface_path)

.PHONY: install_rpc_helper_headers

endif

I%.h: I%.idl $(_idl_compiler_marker)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
ifdef RPC_COMPONENT
	$(Q)$(IDL_COMPILER) $(IDL_COMPILER_ARGS) -Wb$(RPC_COMPONENT) -K -C $(dir $<) $<
else
	$(Q)$(IDL_COMPILER) $(IDL_COMPILER_ARGS) -K -C $(dir $<) $<
endif

mocks/TMock%.h: I%.idl $(_idl_compiler_marker)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -p$(IDL_BACKEND_PATH) -K -bcppmock -Wbh $(IDL_INCPATH) -C $(@D) $<

mocks/TMock%.cpp: I%.idl mocks/TMock%.h $(_idl_compiler_marker)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -p$(IDL_BACKEND_PATH) -K -bcppmock -Wbcpp $(IDL_INCPATH) -C $(@D) $<

ifdef RPC_COMPONENT
I$(_rpc_caller_factory_name).h: $(rpc_idls) $(_idl_compiler_marker)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)/mocks
	$(Q)python2 $(DIST_DIR)/bin/callerfactory.py $(IDL_INCPATH) $(@D) $(RPC_COMPONENT) $(_idl_backend_include_path) $(rpc_idls)

T$(_rpc_caller_factory_name).h: I$(_rpc_caller_factory_name).h
mocks/$(_rpc_mock_caller_factory_name).h: I$(_rpc_caller_factory_name).h
endif

$(_install_idl_headers): $(rpc_idls)
	@TOOLCHAIN= DEVICE= $(MAKESYSTEM)/dist_targets $(rpc_idls) $(INSTALL_DIR)/idl/$(RPC_EXPORT_PATH)

$(rpc_code_headers): $(rpc_base_headers)

$(rpc_srcs): $(rpc_code_headers)

.SECONDARY: $(rpc_srcs) $(rpc_base_headers) $(rpc_code_headers)
endif

include $(MAKESYSTEM)/idlrules.mk

### Source archive and patch handling

QUILT := /usr/bin/quilt
ifeq ($(wildcard $(QUILT)),)
  $(error Error: Please install "$(QUILT)" by running "su -c 'yum install quilt'"))
endif
GUARDS := /usr/bin/guards
ifeq ($(wildcard $(GUARDS)),)
  $(error Error: "$(GUARDS)" not found even though "$(QUILT)" was found)
endif
ifneq ($(filter /%, $(PATCHES)),)
  $(error Error: Directory paths in PATCHES must be relative)
endif

define __patches_setup
$(1)/%.patch: $(1)/%.patch.bz2
	$(Q)bunzip2 -c $$< >$$@

PATCHES_DEP += $(1)/series
PATCHES_DEP += \
  $(addprefix \
    $(1)/, \
    $(shell sed -r -e '/^#/d' -e 's/(^|\s)[+-]\S+//g' $(1)/series))
CLEANUP_FILES += $(subst .bz2.bref,,$(wildcard $(1)/*.bz2.bref))
endef

$(foreach dir, $(PATCHES), $(eval $(call __patches_setup, $(dir))))

.patches: $(PATCHES_DEP)

# Set CREATE_SRC_BASE to create source base directory
ifneq ($(CREATE_SRC_BASE),)
SRC_DIR_BASE = $(SRC_DIR)
else
SRC_DIR_BASE = $(dir $(SRC_DIR))
endif

# Unpack SRC_ARCHIVE in SRC_DIR and backup old SRC_DIR
UNPACK_SRC_ARCHIVE = \
	$(Q)$(PRINT_PROGRESS) UNPACK "$(SRC_ARCHIVE)"; \
	if [ -d $(SRC_DIR) ]; then mv $(SRC_DIR) $$(mktemp -d $(SRC_DIR).bak.XXXXXX); fi; \
	mkdir -p $(SRC_DIR_BASE) && \
	$(if $(filter %.rpm,$(SRC_ARCHIVE)), \
	  cd $(SRC_DIR_BASE) && rpm2cpio $(SRC_ARCHIVE) | cpio -id --quiet, \
	  $(if $(filter %.zip,$(SRC_ARCHIVE)), \
	    unzip -q -d $(SRC_DIR_BASE) $(SRC_ARCHIVE), \
	    tar -xf $(SRC_ARCHIVE) -C $(SRC_DIR_BASE))) && \
	chmod -R u+w $(SRC_DIR)

CHECK_FUZZY_PATCHES = \
	if [ -z "$(ALLOW_FUZZY_PATCHES)" ] && grep -qE 'Hunk.*(fuzz|offset -?[0-9]{3,})' $$tmpfile; then \
		cat $$tmpfile; \
		echo "Error: Some patches were applied with fuzz or with a large offset (>= 100" >&2; \
		echo "lines). Please make sure that they were correctly applied and then refresh" >&2; \
		echo "them, or build with ALLOW_FUZZY_PATCHES=true to ignore this check temporarily." >&2; \
		echo "You can refresh a patch with \"quilt refresh <patchname> [-f]\" or you can run" >&2; \
		echo "\"<devtools>/bin/refresh-quilt-patches\" to refresh all patches." >&2; \
		false; \
	fi

# Apply patches in specified directories on SRC_DIR
ifeq ($(USE_QUILT_GUARDS),)
# The standard, easy case. $(SRC_DIR)/patches is set up as a symlink to
# $(CURDIR)/$(patches), which means that all Quilt commands will modify the
# correct series and patches files.
  APPLY_PATCHES_IN_DIR = \
	$(Q)cd $(SRC_DIR) && \
	if [ -L patches ]; then rm -f patches; fi && \
	if [ -e patches ]; then mv patches patches.original; fi && \
	tmpfile=$$(mktemp) && \
	trap "rm -f $$tmpfile" EXIT && \
	if [ -t 1 ]; then color="--color=always"; fi && \
	$(foreach dir, $(1), \
		rm -f patches && \
		rm -rf .pc && \
		ln -s $(CURDIR)/$(dir) patches && \
		if [ -s $(CURDIR)/$(dir)/series ]; then \
			if $(QUILT) push $$color -a >>$$tmpfile; then \
				$(CHECK_FUZZY_PATCHES); \
			else \
				cat $$tmpfile; \
				false; \
			fi; \
		fi && \
	) \
	cat $$tmpfile && \
	if [ -e patches.original ]; then rm -f patches; mv patches.original patches; fi
else
# The complex case when we want to use guards to select which patches to apply.
# $(SRC_DIR)/patches is created as a directory containing symlinks to the
# patches in $(CURDIR)/patches and $(SRC_DIR)/patches/series is created from
# $(CURDIR)/patches/series using /usr/bin/guards. It will then be possible to
# refresh a patch and have the changes end up in the correct place, but
# creating, deleting and renaming patches must be done without Quilt.
  _restore_patch_opts = \
	orig=$(strip $(1)) && \
	generated=$(strip $(2)) && \
	mv $$generated $$generated.tmp && \
	for patch in $$(cat $$generated.tmp); do \
	  patch_opt=$$(perl -ne '/\b\Q'$$patch'\E(.*)/ && print $$1' $$orig); \
	  echo "$$patch$$patch_opt" >>$$generated; \
	done && \
	rm -f $$generated.tmp

  APPLY_PATCHES_IN_DIR = \
	$(Q) \
	if [ $(words $(1)) -ne 1 ]; then \
		echo "Error: PATCHES must contain exactly one directory when USE_QUILT_GUARDS is set" >&2; \
		false; \
	fi && \
	patches_dir=$(strip $(1)) && \
	cd $(SRC_DIR) && \
	if [ -e patches ]; then \
		echo "Error: $(SRC_DIR)/patches already exists" >&2; \
		false; \
	fi && \
	rm -rf .pc && \
	mkdir patches && \
	cp --symbolic-link $(CURDIR)/$$patches_dir/*.patch patches && \
	$(GUARDS) --config=$(CURDIR)/$$patches_dir/series TOOLCHAIN_$(TOOLCHAIN) DEVICE_$(DEVICE) FLAVOUR_$(FLAVOUR) >patches/series && \
	$(call _restore_patch_opts, $(CURDIR)/$$patches_dir/series, patches/series) && \
	tmpfile=$$(mktemp) && \
	trap "rm -f $$tmpfile" EXIT && \
	if [ -t 1 ]; then color="--color=always"; fi && \
	if [ -s $$patches_dir/series ]; then \
		if $(QUILT) push $$color -a >>$$tmpfile; then \
			$(CHECK_FUZZY_PATCHES); \
		else \
			cat $$tmpfile; \
			false; \
		fi; \
	fi && \
	cat $$tmpfile
endif

# Apply patches in all directories in PATCHES on SRC_DIR
APPLY_PATCHES = $(call APPLY_PATCHES_IN_DIR, $(PATCHES))

# Example rule
#
#$(SRC_DIR)/.done: $(SRC_ARCHIVE) $(PATCHES_DEP)
#	$(UNPACK_SRC_ARCHIVE)
#	$(APPLY_PATCHES)
#       <other stuff that needs to be done to the source,
#         should be empty in most cases>
#	@touch $@


### Eclipse

eclipse_projects: .requires
	@TREE_RULE=eclipse_project \
	$(MAKE) -f .requires

eclipse_project:
ifeq ($(COMPONENT_IS_3PP),)
ifneq ($(COMPONENT_TARGETS),$(TARGET_NAME_NOARCH))
	@mkdir -p $(BSG_SRC_ABS)/eclipse
	@$(MAKESYSTEM)/eclipse/make-eclipse-project.py $(CURDIR) $(BSG_SRC_ABS) no3pp $(REQUIRES)
endif
else
ifneq ($(COMPONENT_TARGETS),$(TARGET_NAME_NOARCH))
	@mkdir -p $(BSG_SRC_ABS)/eclipse
	@$(MAKESYSTEM)/eclipse/make-eclipse-project.py $(CURDIR) $(BSG_SRC_ABS) 3pp $(REQUIRES)
endif
endif


### Syntax check rule, use with Eclipse, Emacs flymake or similar

ifdef CHK_SOURCES
CCACHE=
CHK_CC=$(if $(filter .cpp,$(suffix $(CHK_SOURCES))),$(CXX),$(CC))
ifdef MODULE_SRCS
CHK_CFLAGS=$(MODULE_CFLAGS) $(MODULE_CPPFLAGS)
else
CHK_CFLAGS=$(if $(filter .cpp,$(suffix $(CHK_SOURCES))),$(CXXFLAGS),$(CFLAGS))
endif
check-syntax:
	$(CHK_CC) -fsyntax-only $(CHK_SOURCES) $(CHK_CFLAGS) $(CPPFLAGS)
endif

### Strip control

ifneq ($(NO_STRIP),)
STRIP = :
endif

### Single compilation unit macro
# Usage: $(eval $(call ENABLE_SCU,<srcs_var_name>,<objs_var_name>))

define ENABLE_SCU
ifeq ($(NO_SCU),)
$(2) := $$(TARGET_OBJS_DIR)/.scu_$(1).o
CLEANUP_FILES += .scu_$(1).cpp
.setup: .scu_$(1).cpp
.scu_$(1).cpp: $$($(1))
	$(Q)$(PRINT_PROGRESS) GENERATE "$$@"
	($$(foreach src,$$^, echo '#include "$$(src)"';)) >$$@.$$$$$$$$; mv $$@.$$$$$$$$ $$@
endif
endef


### Get the value of a variable target

getvar-%:
	@echo $($*)

###
### Include dependencies if they exist
###

ifneq ($(TARGET),)
# Only include the .d files for the current target to avoid parallel build
# errors caused by the current make process reading a .d file which is being
# written to by the make process of different target (gcc does not generate .d
# files atomically).
-include $(_depfiles_dir)/$(call _flatten_path,$(TARGET_OBJS_DIR))*.d
endif

-include .requires_depend

-include .requires_setup

-include ./$(TARGET_OBJS_DIR)/.libdepends_*

COMMON_MK := 1
endif
