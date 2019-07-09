# This file contains setup code for automatically generated mocks.

ifeq ($(__build_test),true)

# IFoo.h     -> .mocks/mocks/TMockFoo.h
# TFoo.h     -> .mocks/mocks/TMockFoo.h
# bar/IFoo.h -> .mocks/bar/mocks/TMockFoo.h
__header_to_auto_mock = \
  $(foreach x, $(1), \
    .mocks/$(patsubst ./%,%,$(dir $(x)))mocks/TMock$(patsubst X%,%,$(patsubst T%,X%,$(patsubst I%,X%,$(notdir $(x))))))

# $(1): mock header file
define __auto_mock_setup
__auto_mock_h += $(1)
__auto_mock_cpp += $(1:.h=.cpp)
endef

$(foreach x, $(MOCKED_HEADERS) $(MOCKED_INTERFACE_HEADERS), \
  $(eval $(call __auto_mock_setup,$(call __header_to_auto_mock,$(x)))))

ifneq ($(MOCKED_INTERFACE_HEADERS),)
  __interface_mock_h := $(call __header_to_auto_mock, $(MOCKED_INTERFACE_HEADERS))
  __interface_mock_cpp := $(patsubst %.h,%.cpp,$(__interface_mock_h))

  __interface_mock_h_dist += $(__interface_mock_h)
  __interface_mock_obj += $(addprefix $(TARGET_OBJS_DIR)/,$(__interface_mock_cpp:.cpp=.o))
endif
ifneq ($(__interface_mock_obj),)
  __interface_mock_lib = $(TARGET_OBJS_DIR)/libmocks_$(__slashless_component).a
endif

__setup_targets += $(__auto_mock_h)

INCPATH += -I.mocks

endif # ifeq ($(__build_test),true)

CLEANUP_FILES += .mocks
