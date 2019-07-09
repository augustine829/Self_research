REQUIRES += 3pp/rbtools

COMPONENT_TARGETS = $(TARGET_NAME_NOARCH)

TEST_TARGETS += unittests/test_configuration.py
TEST_TARGETS += unittests/test_manipulate_diff.py
CLEANUP_FILES += *.pyc

include ../../makesystem/common.mk

unittests/test_configuration.py: configuration.py
