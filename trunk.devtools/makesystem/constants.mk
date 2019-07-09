# Make sure that this file is only included once
ifndef CONSTANTS_MK

### Convenience variables.
comma := ,
empty :=
space := $(empty) $(empty)

# Architectures
HOST_MACHINE := $(shell uname --machine)

ARCH_AVR := avr-kreatv-none
ARCH_BCM15 := arm-kreatv-linux-gnueabihf
ARCH_BCM45 := mipsel-kreatv-linux-uclibc
ARCH_BUILD := $(HOST_MACHINE)-kreatv-linux-gnu
ARCH_HOST := $(ARCH_BUILD)
ARCH_ST40 := sh4-kreatv-linux-uclibc
ARCH_ST9 := arm-kreatv-linux-gnueabi

# Toolchain names
AVR_TOOLCHAIN_NAME        := avr
BCM15_TOOLCHAIN_NAME      := bcm15
BCM45_TOOLCHAIN_NAME      := bcm45
HOST_TOOLCHAIN_NAME       := host
NOARCH_TOOLCHAIN_NAME     := noarch
ST40_TOOLCHAIN_NAME       := st40
ST9_TOOLCHAIN_NAME        := st9
STB_NOARCH_TOOLCHAIN_NAME := stb-noarch

# Toolchain targets
TARGET_NAME_AVR        := $(AVR_TOOLCHAIN_NAME)
TARGET_NAME_BCM15      := $(BCM15_TOOLCHAIN_NAME)
TARGET_NAME_BCM45      := $(BCM45_TOOLCHAIN_NAME)
TARGET_NAME_HOST       := $(HOST_TOOLCHAIN_NAME)
TARGET_NAME_NOARCH     := $(NOARCH_TOOLCHAIN_NAME)
TARGET_NAME_ST40       := $(ST40_TOOLCHAIN_NAME)
TARGET_NAME_ST9        := $(ST9_TOOLCHAIN_NAME)
TARGET_NAME_STB_NOARCH := $(STB_NOARCH_TOOLCHAIN_NAME)

# Device targets
TARGET_NAME_VIP28X3    := vip28x3

TARGET_NAME_VIP43X3    := vip43x3

TARGET_NAME_VIP29X2    := vip29x2

TARGET_NAME_VIP35X0    := vip35x0
TARGET_NAME_VIP55X2    := vip55x2
TARGET_NAME_VIP43X2    := vip43x2

# Special-cased host targets
TARGET_NAME_TEST       := test

KLIBC_SUFFIX = _klibc

# Umbrella targets
#
# NOTE: The section below is interpreted specially by build_requires; be
# careful when adding new umbrella targets.
#
# START OF UMBRELLA TARGETS
TARGET_NAME_STB := $(TARGET_NAME_BCM15)
TARGET_NAME_STB += $(TARGET_NAME_BCM45)
TARGET_NAME_STB += $(TARGET_NAME_ST40)
TARGET_NAME_STB += $(TARGET_NAME_ST9)
# END OF UMBRELLA TARGETS

CONSTANTS_MK := 1
endif
