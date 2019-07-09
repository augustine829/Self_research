# Makefile for internal directory nodes

# The intended usage is to let the Makefile in an internal directory be a
# symlink to this file.

REQUIRES += ALL_DIRS
COMPONENT_TARGETS += $(TARGET_NAME_NOARCH)

include $(dir $(shell readlink $(CURDIR)/$(lastword $(MAKEFILE_LIST))))common.mk
