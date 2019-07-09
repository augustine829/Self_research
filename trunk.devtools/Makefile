REQUIRES += ALL_DIRS

COMPONENT_TARGETS += $(TARGET_NAME_NOARCH)

include makesystem/common.mk

.PHONY: precheck
precheck: $(PYTHON_TOOLCHAIN_PATH)
	+check_devtools/check_python
