COMPONENT_TARGETS = $(TARGET_NAME_NOARCH)

TEST_TARGETS = unittests/svn_common_tests.py
CLEANUP_FILES += *.pyc

include ../../makesystem/common.mk

unittests/svn_common_tests.py: svn_common.py
	touch $@
