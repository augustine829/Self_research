# Make sure that this file is only included once
ifndef TARGETSETUP_MK

# COMPONENT: component display name (examples: ., a/b/c)
# __component_fs_name: used when constructing filenames containing the
# component name (examples: top, a/b/c)
COMPONENT := $(patsubst /%,%,$(subst $(BSG_SRC_ABS),,$(CURDIR)))
ifeq ($(COMPONENT),)
  COMPONENT = .
  __component_fs_name = top
else
  __component_fs_name = $(COMPONENT)
endif
export COMPONENT

# Convenience macro for checking shell command result
kreatv-shell = $(or $(shell $(1)),$(error Error: Shell command with empty result: $(1)))


### Set up build information

ifeq ($(BSG_BUILD_DATE),)
BSG_BUILD_DATE := $(call kreatv-shell,date +%Y%m%d)
endif

ifeq ($(BSG_BUILD_YEAR),)
BSG_BUILD_YEAR := $(call kreatv-shell,date +%Y)
endif

ifeq ($(BSG_BUILD_TIME),)
BSG_BUILD_TIME := $(call kreatv-shell,date +%H%M%S)
endif

ifeq ($(BSG_BUILD_BRANCH),)
BSG_BUILD_BRANCH := $(call kreatv-shell,$(MAKESYSTEM)/get_version $(BSG_SRC_ABS)/Makefile)
endif

ifeq ($(BSG_BUILD_VERSION),)
BSG_BUILD_VERSION := $(subst _,-,$(BSG_BUILD_BRANCH))
endif

BSG_BUILD_HOST := $(call kreatv-shell,hostname)

ifeq ($(BSG_BUILD_USER),)
BSG_BUILD_USER := $(call kreatv-shell,id -un)
endif

include $(MAKESYSTEM)/constants.mk

### Targets, toolchains and devices

# Mapping from target to toolchain and device associated with the target.
#
#                 target                      toolchain for the target       device for the target
_target_map := -> $(TARGET_NAME_BCM45)      _ $(BCM45_TOOLCHAIN_NAME)      _ $(empty)
_target_map += -> $(TARGET_NAME_VIP29X2)    _ $(BCM45_TOOLCHAIN_NAME)      _ $(TARGET_NAME_VIP29X2)

_target_map += -> $(TARGET_NAME_BCM15)      _ $(BCM15_TOOLCHAIN_NAME)      _ $(empty)
_target_map += -> $(TARGET_NAME_VIP35X0)    _ $(BCM15_TOOLCHAIN_NAME)      _ $(TARGET_NAME_VIP35X0)
_target_map += -> $(TARGET_NAME_VIP55X2)    _ $(BCM15_TOOLCHAIN_NAME)      _ $(TARGET_NAME_VIP55X2)
_target_map += -> $(TARGET_NAME_VIP43X2)    _ $(BCM15_TOOLCHAIN_NAME)      _ $(TARGET_NAME_VIP43X2)

_target_map += -> $(TARGET_NAME_ST40)       _ $(ST40_TOOLCHAIN_NAME)       _ $(empty)
_target_map += -> $(TARGET_NAME_VIP28X3)    _ $(ST40_TOOLCHAIN_NAME)       _ $(TARGET_NAME_VIP28X3)

_target_map += -> $(TARGET_NAME_ST9)        _ $(ST9_TOOLCHAIN_NAME)        _ $(empty)
_target_map += -> $(TARGET_NAME_VIP43X3)    _ $(ST9_TOOLCHAIN_NAME)        _ $(TARGET_NAME_VIP43X3)

_target_map += -> $(TARGET_NAME_HOST)       _ $(HOST_TOOLCHAIN_NAME)       _ $(empty)
_target_map += -> $(TARGET_NAME_TEST)       _ $(HOST_TOOLCHAIN_NAME)       _ $(empty)

_target_map += -> $(TARGET_NAME_AVR)        _ $(AVR_TOOLCHAIN_NAME)        _ $(empty)

_target_map += -> $(TARGET_NAME_NOARCH)     _ $(NOARCH_TOOLCHAIN_NAME)     _ $(empty)
_target_map += -> $(TARGET_NAME_STB_NOARCH) _ $(STB_NOARCH_TOOLCHAIN_NAME) _ $(empty)

# Transform entries to a list of "target_toolchain_device" entries, where
# device is empty for toolchain level targets
_target_map := $(subst ->,$(space), $(subst $(space),,$(_target_map)))

# Lookup macros
_target_lookup = $(strip $(call _nth,$(1),_,$(filter $(strip $(2))_%, $(_target_map))))
_toolchain_for_target = $(call _target_lookup, 2, $(1))
_device_for_target = $(call _target_lookup, 3, $(1))
_devices_for_toolchain = \
  $(foreach x, \
            $(filter $(1)_%, \
                     $(foreach y, \
                               $(_target_map), \
                               $(subst $(space),_,$(wordlist 2,3,$(subst _,$(space),$(y)))))), \
            $(call _nth,2,_,$(x)))

BCM15_DEVICES := $(call _devices_for_toolchain, $(TARGET_NAME_BCM15))
BCM45_DEVICES := $(call _devices_for_toolchain, $(TARGET_NAME_BCM45))
ST40_DEVICES := $(call _devices_for_toolchain, $(TARGET_NAME_ST40))
ST9_DEVICES := $(call _devices_for_toolchain, $(TARGET_NAME_ST9))

_all_available_toolchains := $(AVR_TOOLCHAIN_NAME)
_all_available_toolchains += $(BCM15_TOOLCHAIN_NAME)
_all_available_toolchains += $(BCM45_TOOLCHAIN_NAME)
_all_available_toolchains += $(HOST_TOOLCHAIN_NAME)
_all_available_toolchains += $(NOARCH_TOOLCHAIN_NAME)
_all_available_toolchains += $(ST40_TOOLCHAIN_NAME)
_all_available_toolchains += $(ST9_TOOLCHAIN_NAME)
_all_available_toolchains += $(STB_NOARCH_TOOLCHAIN_NAME)

_all_available_targets := $(_all_available_toolchains)
_all_available_targets += $(BCM15_DEVICES)
_all_available_targets += $(BCM45_DEVICES)
_all_available_targets += $(ST40_DEVICES)
_all_available_targets += $(ST9_DEVICES)
_all_available_targets += $(TARGET_NAME_TEST)

_all_available_devices += $(BCM15_DEVICES)
_all_available_devices += $(BCM45_DEVICES)
_all_available_devices += $(ST40_DEVICES)
_all_available_devices += $(ST9_DEVICES)

### Sanity checks

ifneq ($(filter $(TARGET),$(_all_available_targets)),$(TARGET))
  $(error Error: Unknown TARGET "$(TARGET)")
endif

# COMPONENT_TARGETS must have a value specified in the Makefile
ifeq ($(COMPONENT_TARGETS),)
$(error Error: COMPONENT_TARGETS must have a value)
endif

# MODULE_NAME must be set when building a kernel module
ifneq ($(MODULE_SRCS),)
  ifeq ($(MODULE_NAME),)
    $(error Error: MODULE_NAME not set)
  endif
endif

### Enabled/disabled targets

ifneq ($(wildcard $(MAKESYSTEM)/platforms.mk),)
  include $(MAKESYSTEM)/platforms.mk
else
  include $(MAKESYSTEM)/platforms.mk.template
endif

# Backward compatibility: BUILD_TEST was previously named BUILD_TESTS
ifdef BUILD_TESTS
  BUILD_TEST := $(BUILD_TESTS)
endif

# Add TARGET_NAME_TEST to COMPONENT_TARGETS if there are test targets or mocks.
# Also set TESTS_ONLY when appropriate.
ifneq ($(TEST_TARGETS)$(MOCKED_HEADERS),)
  ifeq ($(filter $(TARGET_NAME_TEST),$(COMPONENT_TARGETS)),)
    COMPONENT_TARGETS += $(TARGET_NAME_TEST)
    ifeq ($(filter $(TARGET_NAME_HOST),$(COMPONENT_TARGETS)),)
      TESTS_ONLY = true
    endif
  endif
endif

ifdef TARGET
  # Set TOOLCHAIN and DEVICE explicitly here to support supplying TARGET on the
  # commandline.
  TOOLCHAIN := $(call _toolchain_for_target, $(TARGET))
  DEVICE := $(call _device_for_target, $(TARGET))
  TOOLCHAIN_DEVICES := $(call _devices_for_toolchain, $(TOOLCHAIN))
else
  # Target not set: find out which targets to build

  # Determine enabled and disabled targets
  _platform_mk_names := $(shell sed -nr 's/.*\bBUILD_([^ =]+).*/\1/p' $(MAKESYSTEM)/platforms.mk.template)
  _enabled_targets := $(TARGET_NAME_HOST) # Always enable the host target
  _disabled_targets :=
  $(foreach name, $(_platform_mk_names), \
    $(eval $(if $(filter true, $(BUILD_$(name))), \
                _enabled_targets += $(TARGET_NAME_$(name)), \
                _disabled_targets += $(TARGET_NAME_$(name)))))

  # Only build STB_NOARCH if at least one STB target is enabled
  _non_stb_targets := $(TARGET_NAME_TEST) $(TARGET_NAME_HOST)
  ifeq ($(filter-out $(_non_stb_targets), $(_enabled_targets)),)
    _enabled_targets := $(filter-out $(TARGET_NAME_STB_NOARCH), $(_enabled_targets))
    _disabled_targets += $(TARGET_NAME_STB_NOARCH)
  endif

  # Build AVR if one of the following targets is enabled
  ifneq ($(filter $(TARGET_NAME_VIP28X3) $(TARGET_NAME_VIP29X2), $(_enabled_targets)),)
    _enabled_targets += $(TARGET_NAME_AVR)
  else
    _disabled_targets += $(TARGET_NAME_AVR)
  endif

  _enabled_targets := $(sort $(_enabled_targets))
  _disabled_targets := $(sort $(_disabled_targets))

  # Find out enabled toolchains
  _enabled_toolchains := $(sort $(foreach t, $(_enabled_targets), $(call _toolchain_for_target, $(t))))

  # Remove disabled targets from component targets
  _targets_to_build := $(filter-out $(_disabled_targets), $(COMPONENT_TARGETS))

  # Convert test target to host
  _targets_to_build := $(patsubst $(TARGET_NAME_TEST), $(TARGET_NAME_HOST), $(_targets_to_build))

  # Remove duplicates
  _targets_to_build := $(sort $(_targets_to_build))

  # Remove toolchain targets for which all devices have been disabled
  $(foreach tc, ST40 ST9 BCM15 BCM45, \
    $(if $(filter-out $(_disabled_targets), $($(tc)_DEVICES)), , \
      $(eval _targets_to_build := $(filter-out $(TARGET_NAME_$(tc)), $(_targets_to_build)))))

  # Find out toolchains to build for this component
  _toolchains_to_build := $(sort $(foreach t, $(_targets_to_build), $(call _toolchain_for_target, $(t))))
endif

# Support for Emacs's flymake mode
ifdef CHK_SOURCES
  TARGET := $(if $(CHK_TARGET), \
                 $(CHK_TARGET), \
                 $(if $(filter $(HOST_TOOLCHAIN_NAME), \
                               $(_toolchains_to_build)), \
                      $(HOST_TOOLCHAIN_NAME), \
                      $(word 1,$(_toolchains_to_build))))
  TOOLCHAIN := $(call _toolchain_for_target, $(TARGET))
endif

# Support for hack targets. Hack targets are targets that are built with a
# specific HACK_FLAVOUR flavour.
ifneq ($(filter $(MAKECMDGOALS), $(HACK_TARGETS)),)
  FLAVOUR ?= $(or $(HACK_FLAVOUR), $(word 1, $(FLAVOURS)))
  TARGET ?= $(word 1, $(_targets_to_build))
  TOOLCHAIN := $(call _toolchain_for_target, $(TARGET))
  DEVICE := $(call _device_for_target, $(TARGET))
endif

# If flavour is set, unset FLAVOURS to make it look like we're
# building a component without flavours.
ifneq ($(FLAVOUR),)
FLAVOURS =
endif

###
### ccache setup
###

# Do not use the ccache links found on Red Hat systems
ifneq ($(findstring /ccache,$(PATH)),)
  PATH := $(subst :/usr/lib/ccache,,$(subst /usr/lib/ccache:,,$(PATH)))
  PATH := $(subst :/usr/lib64/ccache,,$(subst /usr/lib64/ccache:,,$(PATH)))
  ifneq ($(findstring /ccache,$(PATH)),)
    $(error Error: Could not remove ccache from $$PATH: $(PATH))
  endif
endif

ifeq ($(NO_CCACHE),)
  _ccache_bin = /usr/bin/ccache
  _minimum_ccache_version = 3.1.9
  ifneq ($(wildcard $(_ccache_bin)),)
    _ccache_version = $(shell $(_ccache_bin) -V | head -n1 | cut -f3 -d' ')
    _sorted_versions = $(shell printf "$(_minimum_ccache_version)\n$(_ccache_version)\n" | sort -V)
    ifeq ($(lastword $(_sorted_versions)),$(_ccache_version))
      CCACHE = $(_ccache_bin)$(space)
    endif
  endif

  ifeq ($(CCACHE),)
    CCACHE = /usr/bin/ccache-motorola$(space)
  endif

  ifeq ($(wildcard $(CCACHE)),)
    $(info Please install ccache version $(_minimum_ccache_version) or higher. Try running:)
    $(info )
    $(info su -c "yum install ccache")
    $(info )
    $(info or disable ccache with "NO_CCACHE=1 make ...")
    $(error Error: ccache not found)
  endif

  export CCACHE_BASEDIR = $(BSG_SRC_ABS)
  export CCACHE_DIR = /extra/ccache
  export CCACHE_UMASK = 000
  unexport CCACHE_PREFIX

  ifeq ($(shell test -r $(CCACHE_DIR) -a -w $(CCACHE_DIR) -a -x $(CCACHE_DIR) && echo ok),)
    $(info ccache directory $(CCACHE_DIR) not found or not readable/writable/executable.)
    $(info )
    $(info To create or fix it, run these commands:)
    $(info )
    $(info mkdir -p $(CCACHE_DIR))
    $(info chmod a+rwx $(CCACHE_DIR))
    $(info CCACHE_DIR=$(CCACHE_DIR) $(CCACHE)-M 50G)
    $(info )
    $(error Error: ccache directory $(CCACHE_DIR) not found or not readable/writable/executable)
  endif
else
  CCACHE =
endif


### Generic toolchain setup

KREATV_DIR = /usr/local/kreatv
TOOLCHAIN_BASE_DIR = $(KREATV_DIR)/toolchain

### Target specific configurations

### HOST TOOLCHAIN

HOST_DIST_DIR     = $(DIST_DIR)/$(HOST_TOOLCHAIN_NAME)
HOST_DIST_DIR_ABS = $(DIST_DIR_ABS)/$(HOST_TOOLCHAIN_NAME)
HOST_TARGET       = $(HOST_TOOLCHAIN_NAME)

ifneq ($(PRODUCES_STANDALONE_BINARY),)
ifeq ($(USE_SANITIZE)$(USE_EXTRA_DEBUG)$(USE_GCOV),)
  USE_SYSTEM_TOOLCHAIN_FOR_HOST = true
endif
endif

ifeq ($(USE_SYSTEM_TOOLCHAIN_FOR_HOST),)

ubuntu = $(shell uname -a | grep -i ubuntu)
ifneq ($(ubuntu),)
  host_suffix := -ubuntu
endif
ifeq ($(HOST_SUFFIX),ubuntu)
  host_suffix := -ubuntu
endif

HOST_TOOLCHAIN_VERSION  = 2.2.0
HOST_TOOLCHAIN_DIR      = host$(host_suffix)
HOST_TOOLCHAIN_PATH     = $(TOOLCHAIN_BASE_DIR)/$(HOST_TOOLCHAIN_DIR)/$(HOST_TOOLCHAIN_VERSION)
ifneq ($(filter $(HOST_TOOLCHAIN_NAME), $(_enabled_toolchains)),)
  __toolchains_to_install += $(HOST_TOOLCHAIN_PATH)
endif

HOST_AR      = $(HOST_TOOLCHAIN_PATH)/bin/$(ARCH_HOST)-ar
HOST_AS      = $(HOST_TOOLCHAIN_PATH)/bin/$(ARCH_HOST)-as
HOST_CC      = $(CCACHE)$(HOST_TOOLCHAIN_PATH)/bin/$(ARCH_HOST)-gcc
HOST_CXX     = $(CCACHE)$(HOST_TOOLCHAIN_PATH)/bin/$(ARCH_HOST)-g++
HOST_GCOV    = $(HOST_TOOLCHAIN_PATH)/bin/$(ARCH_HOST)-gcov
HOST_LD      = $(HOST_TOOLCHAIN_PATH)/bin/$(ARCH_HOST)-ld
HOST_NM      = $(HOST_TOOLCHAIN_PATH)/bin/$(ARCH_HOST)-nm
HOST_OBJCOPY = $(HOST_TOOLCHAIN_PATH)/bin/$(ARCH_HOST)-objcopy
HOST_OBJDUMP = $(HOST_TOOLCHAIN_PATH)/bin/$(ARCH_HOST)-objdump
HOST_RANLIB  = $(HOST_TOOLCHAIN_PATH)/bin/$(ARCH_HOST)-ranlib
HOST_SIZE    = $(HOST_TOOLCHAIN_PATH)/bin/$(ARCH_HOST)-size
HOST_STRIP   = $(HOST_TOOLCHAIN_PATH)/bin/$(ARCH_HOST)-strip

else

HOST_TOOLCHAIN_PATH = /usr

HOST_AR      = ar
HOST_AS      = as
HOST_CC      = $(CCACHE)gcc
HOST_CXX     = $(CCACHE)g++
HOST_GCOV    = gcov
HOST_LD      = ld
HOST_NM      = nm
HOST_OBJCOPY = objcopy
HOST_OBJDUMP = objdump
HOST_RANLIB  = ranlib
HOST_SIZE    = size
HOST_STRIP   = strip

endif

ifneq ($(USE_SYSTEM_TOOLCHAIN_FOR_HOST),)
  _host_cxxflags = -std=c++0x
else
  # Workaround for https://gcc.gnu.org/bugzilla/show_bug.cgi?id=65974.
  _host_cxxflags = -Wno-deprecated-declarations
endif

### ST40 TOOLCHAIN

ST40_TOOLCHAIN_VERSION  = 5.0.0
ST40_TOOLCHAIN_DIR      = st40
ST40_TOOLCHAIN_PATH     = $(TOOLCHAIN_BASE_DIR)/$(ST40_TOOLCHAIN_DIR)/$(ST40_TOOLCHAIN_VERSION)
ifneq ($(filter $(ST40_TOOLCHAIN_NAME), $(_enabled_toolchains)),)
  __toolchains_to_install += $(ST40_TOOLCHAIN_PATH)
endif

ST40_DIST_DIR     = $(DIST_DIR)/$(ST40_TOOLCHAIN_NAME)
ST40_DIST_DIR_ABS = $(DIST_DIR_ABS)/$(ST40_TOOLCHAIN_NAME)
ST40_TARGET       = $(ST40_TOOLCHAIN_NAME)

ST40_AR           = $(ST40_TOOLCHAIN_PATH)/bin/$(ARCH_ST40)-ar
ST40_AS           = $(ST40_TOOLCHAIN_PATH)/bin/$(ARCH_ST40)-as
ST40_CC           = $(CCACHE)$(ST40_TOOLCHAIN_PATH)/bin/$(ARCH_ST40)-gcc
ST40_CXX          = $(CCACHE)$(ST40_TOOLCHAIN_PATH)/bin/$(ARCH_ST40)-g++
ST40_LD           = $(ST40_TOOLCHAIN_PATH)/bin/$(ARCH_ST40)-ld
ST40_NM           = $(ST40_TOOLCHAIN_PATH)/bin/$(ARCH_ST40)-nm
ST40_OBJCOPY      = $(ST40_TOOLCHAIN_PATH)/bin/$(ARCH_ST40)-objcopy
ST40_OBJDUMP      = $(ST40_TOOLCHAIN_PATH)/bin/$(ARCH_ST40)-objdump
ST40_RANLIB       = $(ST40_TOOLCHAIN_PATH)/bin/$(ARCH_ST40)-ranlib
ST40_SIZE         = $(ST40_TOOLCHAIN_PATH)/bin/$(ARCH_ST40)-size
ST40_STRIP        = $(ST40_TOOLCHAIN_PATH)/bin/$(ARCH_ST40)-strip

### ST9 TOOLCHAIN

ST9_TOOLCHAIN_VERSION  = 2.0.1
ST9_TOOLCHAIN_DIR      = st9
ST9_TOOLCHAIN_PATH     = $(TOOLCHAIN_BASE_DIR)/$(ST9_TOOLCHAIN_DIR)/$(ST9_TOOLCHAIN_VERSION)
ifneq ($(filter $(ST9_TOOLCHAIN_NAME), $(_enabled_toolchains)),)
  __toolchains_to_install += $(ST9_TOOLCHAIN_PATH)
endif

ST9_DIST_DIR     = $(DIST_DIR)/$(ST9_TOOLCHAIN_NAME)
ST9_DIST_DIR_ABS = $(DIST_DIR_ABS)/$(ST9_TOOLCHAIN_NAME)
ST9_TARGET       = $(ST9_TOOLCHAIN_NAME)

ST9_AR           = $(ST9_TOOLCHAIN_PATH)/bin/$(ARCH_ST9)-ar
ST9_AS           = $(ST9_TOOLCHAIN_PATH)/bin/$(ARCH_ST9)-as
ST9_CC           = $(CCACHE)$(ST9_TOOLCHAIN_PATH)/bin/$(ARCH_ST9)-gcc
ST9_CXX          = $(CCACHE)$(ST9_TOOLCHAIN_PATH)/bin/$(ARCH_ST9)-g++
ST9_LD           = $(ST9_TOOLCHAIN_PATH)/bin/$(ARCH_ST9)-ld
ST9_NM           = $(ST9_TOOLCHAIN_PATH)/bin/$(ARCH_ST9)-nm
ST9_OBJCOPY      = $(ST9_TOOLCHAIN_PATH)/bin/$(ARCH_ST9)-objcopy
ST9_OBJDUMP      = $(ST9_TOOLCHAIN_PATH)/bin/$(ARCH_ST9)-objdump
ST9_RANLIB       = $(ST9_TOOLCHAIN_PATH)/bin/$(ARCH_ST9)-ranlib
ST9_SIZE         = $(ST9_TOOLCHAIN_PATH)/bin/$(ARCH_ST9)-size
ST9_STRIP        = $(ST9_TOOLCHAIN_PATH)/bin/$(ARCH_ST9)-strip

### BCM45 TOOLCHAIN

BCM45_TOOLCHAIN_VERSION = 5.0.0
BCM45_TOOLCHAIN_DIR     = bcm45
BCM45_TOOLCHAIN_PATH    = $(TOOLCHAIN_BASE_DIR)/$(BCM45_TOOLCHAIN_DIR)/$(BCM45_TOOLCHAIN_VERSION)
ifneq ($(filter $(BCM45_TOOLCHAIN_NAME), $(_enabled_toolchains)),)
  __toolchains_to_install += $(BCM45_TOOLCHAIN_PATH)
endif

BCM45_DIST_DIR     = $(DIST_DIR)/$(BCM45_TOOLCHAIN_NAME)
BCM45_DIST_DIR_ABS = $(DIST_DIR_ABS)/$(BCM45_TOOLCHAIN_NAME)
BCM45_TARGET       = $(BCM45_TOOLCHAIN_NAME)

BCM45_AR           = $(BCM45_TOOLCHAIN_PATH)/bin/$(ARCH_BCM45)-ar
BCM45_AS           = $(BCM45_TOOLCHAIN_PATH)/bin/$(ARCH_BCM45)-as
BCM45_CC           = $(CCACHE)$(BCM45_TOOLCHAIN_PATH)/bin/$(ARCH_BCM45)-gcc
BCM45_CXX          = $(CCACHE)$(BCM45_TOOLCHAIN_PATH)/bin/$(ARCH_BCM45)-g++
BCM45_LD           = $(BCM45_TOOLCHAIN_PATH)/bin/$(ARCH_BCM45)-ld
BCM45_NM           = $(BCM45_TOOLCHAIN_PATH)/bin/$(ARCH_BCM45)-nm
BCM45_OBJCOPY      = $(BCM45_TOOLCHAIN_PATH)/bin/$(ARCH_BCM45)-objcopy
BCM45_OBJDUMP      = $(BCM45_TOOLCHAIN_PATH)/bin/$(ARCH_BCM45)-objdump
BCM45_RANLIB       = $(BCM45_TOOLCHAIN_PATH)/bin/$(ARCH_BCM45)-ranlib
BCM45_SIZE         = $(BCM45_TOOLCHAIN_PATH)/bin/$(ARCH_BCM45)-size
BCM45_STRIP        = $(BCM45_TOOLCHAIN_PATH)/bin/$(ARCH_BCM45)-strip

### AVR TOOLCHAIN

AVR_TOOLCHAIN_VERSION = 2.0.0
AVR_TOOLCHAIN_DIR     = avr
AVR_TOOLCHAIN_PATH    = $(TOOLCHAIN_BASE_DIR)/$(AVR_TOOLCHAIN_DIR)/$(AVR_TOOLCHAIN_VERSION)
ifneq ($(filter $(AVR_TOOLCHAIN_NAME), $(_enabled_toolchains)),)
  __toolchains_to_install += $(AVR_TOOLCHAIN_PATH)
endif

AVR_DIST_DIR     = $(DIST_DIR)/$(AVR_TOOLCHAIN_NAME)
AVR_DIST_DIR_ABS = $(DIST_DIR_ABS)/$(AVR_TOOLCHAIN_NAME)
AVR_TARGET       = $(AVR_TOOLCHAIN_NAME)

AVR_AR           = $(AVR_TOOLCHAIN_PATH)/bin/$(ARCH_AVR)-ar
AVR_AS           = $(AVR_TOOLCHAIN_PATH)/bin/$(ARCH_AVR)-as
AVR_CC           = $(CCACHE)$(AVR_TOOLCHAIN_PATH)/bin/$(ARCH_AVR)-gcc
AVR_LD           = $(AVR_TOOLCHAIN_PATH)/bin/$(ARCH_AVR)-ld
AVR_NM           = $(AVR_TOOLCHAIN_PATH)/bin/$(ARCH_AVR)-nm
AVR_OBJCOPY      = $(AVR_TOOLCHAIN_PATH)/bin/$(ARCH_AVR)-objcopy
AVR_OBJDUMP      = $(AVR_TOOLCHAIN_PATH)/bin/$(ARCH_AVR)-objdump
AVR_RANLIB       = $(AVR_TOOLCHAIN_PATH)/bin/$(ARCH_AVR)-ranlib
AVR_SIZE         = $(AVR_TOOLCHAIN_PATH)/bin/$(ARCH_AVR)-size
AVR_STRIP        = $(AVR_TOOLCHAIN_PATH)/bin/$(ARCH_AVR)-strip


### BCM15 TOOLCHAIN

BCM15_TOOLCHAIN_VERSION = 2.2.2
BCM15_TOOLCHAIN_DIR     = bcm15
BCM15_TOOLCHAIN_PATH    = $(TOOLCHAIN_BASE_DIR)/$(BCM15_TOOLCHAIN_DIR)/$(BCM15_TOOLCHAIN_VERSION)
ifneq ($(filter $(BCM15_TOOLCHAIN_NAME), $(_enabled_toolchains)),)
  __toolchains_to_install += $(BCM15_TOOLCHAIN_PATH)
endif

BCM15_DIST_DIR     = $(DIST_DIR)/$(BCM15_TOOLCHAIN_NAME)
BCM15_DIST_DIR_ABS = $(DIST_DIR_ABS)/$(BCM15_TOOLCHAIN_NAME)
BCM15_TARGET       = $(BCM15_TOOLCHAIN_NAME)

BCM15_AR           = $(BCM15_TOOLCHAIN_PATH)/bin/$(ARCH_BCM15)-ar
BCM15_AS           = $(BCM15_TOOLCHAIN_PATH)/bin/$(ARCH_BCM15)-as
BCM15_CC           = $(CCACHE)$(BCM15_TOOLCHAIN_PATH)/bin/$(ARCH_BCM15)-gcc
BCM15_CXX          = $(CCACHE)$(BCM15_TOOLCHAIN_PATH)/bin/$(ARCH_BCM15)-g++
BCM15_LD           = $(BCM15_TOOLCHAIN_PATH)/bin/$(ARCH_BCM15)-ld
BCM15_NM           = $(BCM15_TOOLCHAIN_PATH)/bin/$(ARCH_BCM15)-nm
BCM15_OBJCOPY      = $(BCM15_TOOLCHAIN_PATH)/bin/$(ARCH_BCM15)-objcopy
BCM15_OBJDUMP      = $(BCM15_TOOLCHAIN_PATH)/bin/$(ARCH_BCM15)-objdump
BCM15_RANLIB       = $(BCM15_TOOLCHAIN_PATH)/bin/$(ARCH_BCM15)-ranlib
BCM15_SIZE         = $(BCM15_TOOLCHAIN_PATH)/bin/$(ARCH_BCM15)-size
BCM15_STRIP        = $(BCM15_TOOLCHAIN_PATH)/bin/$(ARCH_BCM15)-strip

### JAVA TOOLCHAIN

JAVA_TOOLCHAIN_VERSION = 2.0.0
JAVA_TOOLCHAIN_DIR     = java
JAVA_TOOLCHAIN_PATH    = $(TOOLCHAIN_BASE_DIR)/$(JAVA_TOOLCHAIN_DIR)/$(JAVA_TOOLCHAIN_VERSION)
__toolchains_to_install += $(JAVA_TOOLCHAIN_PATH)

JAVAC = $(JAVA_TOOLCHAIN_PATH)/bin/javac
JAVA  = $(JAVA_TOOLCHAIN_PATH)/bin/java
JAR   = $(JAVA_TOOLCHAIN_PATH)/bin/jar


### DOC TOOLCHAIN

DOC_TOOLCHAIN_VERSION = 2.0.0
DOC_TOOLCHAIN_DIR     = doc
DOC_TOOLCHAIN_PATH    = $(TOOLCHAIN_BASE_DIR)/$(DOC_TOOLCHAIN_DIR)/$(DOC_TOOLCHAIN_VERSION)
__toolchains_to_install += $(DOC_TOOLCHAIN_PATH)

DOXYGEN = $(DOC_TOOLCHAIN_PATH)/bin/doxygen
MSCGEN = $(DOC_TOOLCHAIN_PATH)/bin/mscgen
MULTIMARKDOWN = $(DOC_TOOLCHAIN_PATH)/bin/multimarkdown


### Python toolchain

_python_toolchain_version = 3.0.0
PYTHON_TOOLCHAIN_PATH := $(TOOLCHAIN_BASE_DIR)/python/$(_python_toolchain_version)
__toolchains_to_install += $(PYTHON_TOOLCHAIN_PATH)

# Enable usage of '$(make getvar-PYTHON2)' to run interpreter/scripts outside
# the makesystem (when run through makesystem, 'python2' is found in PATH).
PYTHON2 := $(PYTHON_TOOLCHAIN_PATH)/bin/python2


# Only build tests for host
__build_test := $(BUILD_TEST)
ifneq ($(TOOLCHAIN), $(HOST_TOOLCHAIN_NAME))
  BUILD_TEST :=
endif


### Set up variables depending on the toolchain

ifeq ($(TOOLCHAIN), $(ST40_TOOLCHAIN_NAME))
  _tc_var = ST40
else ifeq ($(TOOLCHAIN), $(ST9_TOOLCHAIN_NAME))
  _tc_var = ST9
else ifeq ($(TOOLCHAIN), $(BCM45_TOOLCHAIN_NAME))
  _tc_var = BCM45
else ifeq ($(TOOLCHAIN), $(BCM15_TOOLCHAIN_NAME))
  _tc_var = BCM15
else ifeq ($(TOOLCHAIN), $(HOST_TOOLCHAIN_NAME))
  _tc_var = HOST
else ifeq ($(TOOLCHAIN), $(AVR_TOOLCHAIN_NAME))
  _tc_var = AVR
endif

ifdef _tc_var
  TOOLCHAIN_VERSION = $($(_tc_var)_TOOLCHAIN_VERSION)
  TOOLCHAIN_PATH = $($(_tc_var)_TOOLCHAIN_PATH)
  CC      = $($(_tc_var)_CC)
  CXX     = $($(_tc_var)_CXX)
  AS      = $($(_tc_var)_AS)
  AR      = $($(_tc_var)_AR)
  LD      = $($(_tc_var)_LD)
  RANLIB  = $($(_tc_var)_RANLIB)
  SIZE    = $($(_tc_var)_SIZE)
  STRIP   = $($(_tc_var)_STRIP)
  OBJCOPY = $($(_tc_var)_OBJCOPY)
  OBJDUMP = $($(_tc_var)_OBJDUMP)
  NM      = $($(_tc_var)_NM)
endif

CROSS_PREFIX = $(CCACHE)$(TOOLCHAIN_PATH)/bin/$(TARGET_ARCH)-

ifeq ($(TOOLCHAIN), $(ST40_TOOLCHAIN_NAME))
  TARGET_ARCH = $(ARCH_ST40)
else ifeq ($(TOOLCHAIN), $(ST9_TOOLCHAIN_NAME))
  TARGET_ARCH = $(ARCH_ST9)
else ifeq ($(TOOLCHAIN), $(BCM45_TOOLCHAIN_NAME))
  TARGET_ARCH = $(ARCH_BCM45)
else ifeq ($(TOOLCHAIN), $(BCM15_TOOLCHAIN_NAME))
  TARGET_ARCH = $(ARCH_BCM15)
else ifeq ($(TOOLCHAIN), $(HOST_TOOLCHAIN_NAME))
  ifneq ($(USE_SYSTEM_TOOLCHAIN_FOR_HOST),)
    CROSS_PREFIX = $(CCACHE)
  endif
  TARGET_ARCH = $(ARCH_HOST)
else ifeq ($(TOOLCHAIN), $(AVR_TOOLCHAIN_NAME))
  TARGET_ARCH = $(ARCH_BUILD)
endif


### Build environment

DIST_DIR_ABS           = $(BSG_SRC_ABS)/dist

ifeq ($(NEEDS_ABS_PATHS),)
DIST_DIR               = $(BSG_SRC)/dist
__sandbox_dir          = .sandbox
else
DIST_DIR               = $(DIST_DIR_ABS)
__sandbox_dir          = $(CURDIR)/.sandbox
endif

TOOLCHAIN_DIST_DIR        = $(DIST_DIR)/$(TOOLCHAIN)
TOOLCHAIN_3PP_DIST_DIR    = $(TOOLCHAIN_DIST_DIR)/3pp

__target_sandbox_dir   = $(__sandbox_dir)/$(TOOLCHAIN)
__target_3pp_sandbox_dir = $(__target_sandbox_dir)/3pp

### Target directory

ifneq ($(filter $(NOARCH_TOOLCHAIN_NAME) $(STB_NOARCH_TOOLCHAIN_NAME),$(TOOLCHAIN)),)
TARGET_DIR = $(CURDIR)
else
TARGET_DIR = $(TARGET_OBJS_DIR)
endif

TARGETSETUP_MK := 1
endif
