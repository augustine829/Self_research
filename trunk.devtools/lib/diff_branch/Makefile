COMPONENT_TARGETS = $(TARGET_NAME_NOARCH)

TEST_TARGETS = unittests/diff_branch_tests.py
CLEANUP_FILES += *.pyc

include ../../makesystem/common.mk

unittests/diff_branch_tests.py: diff_branch.py
	touch $@
