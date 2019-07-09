# META: ifndef OSSK || BOSSK
# NOTE: The "META:" comments are for ossk and bootloader-ossk.
# NOTE: Key related text should not be in ossk.
# META: endif

### Component specification

COMPONENT_TARGETS += $(TARGET_NAME_HOST)

# META: ifndef OSSK || BOSSK
NO_AUTO_FETCH_BREFS = true
# META: endif

### Targets

opensourcenotice_config = opensourcenotice.config

# META: ifndef OSSK || BOSSK
testrunner_bin = $(TARGET_OBJS_DIR)/testrunner
testrunner_srcs += testrunner.c
testrunner_objs = $(addprefix $(TARGET_OBJS_DIR)/,$(testrunner_srcs:.c=.o))

SRCS += $(testrunner_srcs)
BIN_TARGETS += $(testrunner_bin)

SCRIPT_TARGETS += check_env
SCRIPT_TARGETS += expand_symbol_visibility_macros
SCRIPT_TARGETS += html_find_broken_links
SCRIPT_TARGETS += html_meta_filter
SCRIPT_TARGETS += html_securityclass_filter
SCRIPT_TARGETS += html_var_subst
SCRIPT_TARGETS += install_licenses
SCRIPT_TARGETS += install_parts
SCRIPT_TARGETS += install_toolchain
SCRIPT_TARGETS += objcopy_tree
SCRIPT_TARGETS += strip_tree
# META: endif
SCRIPT_TARGETS += KreaTV.pm
SCRIPT_TARGETS += license_parser.py

CONFIG_TARGETS += $(opensourcenotice_config)

# META: ifndef OSSK || BOSSK
DOC_PATH = dev
DOC_PRESERVE_SOURCE_DIR = true
DOC_TARGETS += doc/README.mmd
DOC_TARGETS += doc/toolchain.mmd
# META: endif

### Extra cleanup

CLEANUP_FILES += $(opensourcenotice_config)
CLEANUP_FILES += unittests/createmock/.ITest.*

# META: ifndef OSSK || BOSSK
### Unit test
visibility_test_dir = unittests/expand_symbol_visibility_macros
CLEANUP_FILES += $(visibility_test_dir)/tmp_dir

export PERL5LIB=$(MAKESYSTEM)

TEST_TARGETS += unittests/createmock/run
TEST_TARGETS += unittests/build_requires/run
TEST_TARGETS += $(visibility_test_dir)/run
TEST_TARGETS += pyutil/unittests/run_test.sh
TEST_TARGETS += unittests/license_parser/test_license_parser.py

visibility_test_bin = $(TARGET_OBJS_DIR)/visibility_test
visibility_test_srcs := $(visibility_test_dir)/compile.cpp
visibility_test_objs = \
  $(addprefix $(TARGET_OBJS_DIR)/,$(visibility_test_srcs:.cpp=.o))
SRCS += $(visibility_test_srcs)
OTHER_TARGETS += $(visibility_test_bin)
# META: endif

### Common.mk

include common.mk

# META: ifndef OSSK || BOSSK

include toolchains.mk

# Special hack for unit tests in makesystem
$(TEST_TARGETS): | host/testrunner .install_bins

unittests/createmock/run: createmock
	@touch $@

$(visibility_test_dir)/run: expand_symbol_visibility_macros
$(visibility_test_dir)/run: $(visibility_test_dir)/ITest.h
$(visibility_test_dir)/run: $(visibility_test_dir)/expected.h
	@touch $@

unittests/build_requires/run: build_requires
	@touch $@

pyutil/unittests/run_test.sh: pyutil/count_effective_line.py
	@touch $@

unittests/license_parser/test_license_parser.py: license_parser.py
	@touch $@

# META: endif

### Dependencies

platforms.mk: platforms.mk.template
	cp $< $@

# META: ifndef OSSK || BOSSK
$(testrunner_bin): $(testrunner_objs)
	$(LINK_C)

$(visibility_test_bin): $(visibility_test_objs)
	$(LINK)
# META: endif

valid_notice_targets += kit
valid_notice_targets += kit:$(ST40_TOOLCHAIN_NAME)
valid_notice_targets += bi:$(ST40_TOOLCHAIN_NAME)
valid_notice_targets += $(addprefix bi:,$(ST40_DEVICES))
valid_notice_targets += kit:$(ST9_TOOLCHAIN_NAME)
valid_notice_targets += bi:$(ST9_TOOLCHAIN_NAME)
valid_notice_targets += $(addprefix bi:,$(ST9_DEVICES))
valid_notice_targets += kit:$(BCM45_TOOLCHAIN_NAME)
valid_notice_targets += bi:$(BCM45_TOOLCHAIN_NAME)
valid_notice_targets += $(addprefix bi:,$(BCM45_DEVICES))
valid_notice_targets += kit:$(BCM15_TOOLCHAIN_NAME)
valid_notice_targets += bi:$(BCM15_TOOLCHAIN_NAME)
valid_notice_targets += $(addprefix bi:,$(BCM15_DEVICES))
valid_notice_targets += bi:$(HOST_TOOLCHAIN_NAME)

$(opensourcenotice_config):
	echo "[opensourcenotice]" > $@
	echo "valid_targets = $(valid_notice_targets)" >> $@
