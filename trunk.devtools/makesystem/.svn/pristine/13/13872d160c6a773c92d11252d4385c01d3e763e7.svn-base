# This file contains rules for automatically generated mocks.

# INTERFACE_PATH = iii
#
# Source header:              sss/IFoo.h
#   Disted to:                dist/.../include/iii/IFoo.h
# Local mock:                 .mocks/sss/mocks/TMockFoo.h
#   Source header include:    #include "sss/IFoo.h"
# Interface mock:             .mocks/sss/mocks/TMockFoo.h
#   Disted to:                dist/.../include/iii/mocks/TMockFoo.h
#   Source header include:    #include "iii/IFoo.h"
#
# Local mock user:            #include "sss/mocks/TMockFoo.h"
#   Or (if interface header): #include "iii/mocks/TMockFoo.h"
# Non-local mock user:        #include "iii/mocks/TMockFoo.h"

ifeq ($(__build_test),true)

_mockflatfile = $(subst /,_,$(subst .mocks/,mocks/,$(subst ./,,$(1))))
_mockdepsfile = $(patsubst %.h,%_h.d, .mocks/$(call _mockflatfile,$@))
# The mock generator needs to be able to read disted interface headers.
$(__auto_mock_h): | $(_installed_headers_marker)

$(__interface_mock_lib): $(__interface_mock_obj)
	$(LINK_A)

$(__interface_mock_obj): $(TARGET_OBJS_DIR)/%.o: %.cpp

# Avoid insanely large mock objects by reducing amount of debug info:
$(__interface_mock_obj): DEBUG_FLAGS = -g1

# Disable optimization of mocks to get a shorter turn-around time when
# developing tests.
$(__interface_mock_obj): OPTIMIZATION_FLAGS =

# $(1): type (local or disted)
# $(2): source header file
# $(3): mock header file
define __auto_mock_rule_setup
$(3): $(2)
	@$$(PRINT_PROGRESS) MOCK "$$@"
	@mkdir -p $$(dir $$@)
# Create mock .h and .cpp files and dependency rules:
	$$(MAKESYSTEM)/createmock $(1) "$$(INTERFACE_PATH)" $$< $$@ $$(HOST_DIST_DIR)/include \
	    $$(_mockdepsfile)

# The mock .cpp file is generated as a side effect by createmock:
$(2:.h=.cpp): $(2)
endef

$(foreach x, $(sort $(MOCKED_HEADERS)), \
  $(eval $(call __auto_mock_rule_setup,local,$(x),$(call __header_to_auto_mock,$(x)))))

$(foreach x, $(sort $(MOCKED_INTERFACE_HEADERS)), \
  $(eval $(call __auto_mock_rule_setup,disted,$(x),$(call __header_to_auto_mock,$(x)))))

# MOCK_OBJS contains the local mock objects whose header files are listed in
# MOCKED_HEADERS and MOCKED_INTERFACE_HEADERS.
MOCK_OBJS = $(addprefix $(TARGET_OBJS_DIR)/,$(__auto_mock_h:.h=.o))

-include .mocks/*.d

endif # ifeq ($(__build_test),true)
