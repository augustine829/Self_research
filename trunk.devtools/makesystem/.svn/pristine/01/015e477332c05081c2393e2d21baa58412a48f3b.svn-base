ifneq ($(TOI_IDL_DIR),)

cppdir = .idlcpp
jsdir = .idljs
pydir = .idlpy
toiweb_jsdir = .idltoiweb

ifneq ($(TOI_PLUGIN_MIME)$(TOIWEB_PLUGIN),)
toideps = $(CURDIR)/$(INSTALL_DIR)/config/$(TOI_COMPONENT)deps
toievents = $(CURDIR)/$(INSTALL_DIR)/config/$(TOI_COMPONENT)events
toiinherits = $(CURDIR)/$(INSTALL_DIR)/config/$(TOI_COMPONENT)inherits
else
toideps = $(cppdir)/$(TOI_COMPONENT)deps
toiinherits = $(CURDIR)/$(cppdir)/$(TOI_COMPONENT)inherits
toievents = $(CURDIR)/$(cppdir)/$(TOI_COMPONENT)events
toijsfiles = $(CURDIR)/$(cppdir)/$(TOI_COMPONENT)jsfiles
SETUP_TARGETS += $(toievents) $(toijsfiles) $(toiinherits)
CONFIG_TARGETS = $(toideps) $(toievents) $(toiinherits)
endif

CLEANUP_FILES += $(cppdir) $(jsdir) $(pydir) $(toiweb_jsdir)

INCPATH += -I$(JS_COMMON_PATH)
INCPATH += -I$(TOOLCHAIN_DIST_DIR)/include/interface

### Common

toi_idls = $(addprefix $(TOI_IDL_DIR)/,$(TOI_IDLS))

### CPP

ifeq ($(TOI_PLUGIN_MIME)$(TOIWEB_PLUGIN),)

_toi_caller_factory_name = $(TOI_COMPONENT)Callers
toi_observer_idls = $(filter I%Observer.idl,$(TOI_IDLS))
gen_cpp_idls = $(addprefix $(cppdir)/,$(TOI_IDLS))
gen_cpp_base_headers += $(addprefix $(cppdir)/,$(TOI_IDLS:%.idl=%.h))
_gen_cpp_headers += $(addprefix $(cppdir)/,$(TOI_IDLS:I%.idl=T%Caller.h))
_gen_cpp_headers += $(addprefix $(cppdir)/,$(TOI_IDLS:I%.idl=T%Dispatcher.h))
_gen_cpp_headers += $(addprefix $(cppdir)/,$(toi_observer_idls:I%.idl=T%Adapter.h))
_gen_cpp_headers += $(cppdir)/I$(_toi_caller_factory_name).h
_gen_cpp_headers += $(cppdir)/T$(_toi_caller_factory_name).h
gen_cpp_headers = $(filter-out %.idl, $(_gen_cpp_headers))
ifeq ($(TOI_COMPONENT),Toi)
gen_cpp_headers += $(cppdir)/IIDLExceptionCodes.h
gen_cpp_headers += $(cppdir)/IToiTypes.h
endif
_gen_cpp_srcs += $(addprefix $(cppdir)/,$(TOI_IDLS:I%.idl=T%Caller.cpp))
_gen_cpp_srcs += $(addprefix $(cppdir)/,$(TOI_IDLS:I%.idl=T%Dispatcher.cpp))
_gen_cpp_srcs += $(cppdir)/T$(_toi_caller_factory_name).cpp
gen_cpp_srcs = $(filter-out %.idl, $(_gen_cpp_srcs))
ifeq ($(TOI_COMPONENT),Toi)
gen_cpp_srcs += $(cppdir)/IpcCaller.cpp
SETUP_TARGETS += $(cppdir)/IpcCaller.cpp
endif
gen_cpp_objs += $(addprefix $(TARGET_OBJS_DIR)/,$(gen_cpp_srcs:%.cpp=%.o))

IDL_OBJS = $(gen_cpp_objs)
IDL_SRCS = $(gen_cpp_srcs)

SRCS += $(gen_cpp_srcs)

_toi_mock_caller_factory_name = $(TOI_COMPONENT)MockCallers
_idlmock_headers = $(addprefix $(cppdir)/mocks/,$(TOI_IDLS:I%.idl=TMock%.h))
_idlmock_headers += $(addprefix $(cppdir)/mocks/,T$(_toi_mock_caller_factory_name).h)
_idlmock_headers := $(filter-out %.idl, $(_idlmock_headers))
_idlmock_srcs = $(addprefix $(cppdir)/mocks/,$(TOI_IDLS:I%.idl=TMock%.cpp))
_idlmock_srcs += $(addprefix $(cppdir)/mocks/,T$(_toi_mock_caller_factory_name).cpp)
_idlmock_srcs := $(filter-out %.idl, $(_idlmock_srcs))
_idlmock_objs = $(addprefix $(TARGET_OBJS_DIR)/,$(_idlmock_srcs:%.cpp=%.o))

SRCS += $(_idlmock_srcs)
ifeq ($(__build_test),true)
  __interface_mock_h_dist += $(_idlmock_headers)
  __interface_mock_obj += $(_idlmock_objs)
endif

gen_suppressible_observer_headers = $(wildcard $(cppdir)/TSuppressible*Observer.h)
gen_cpp_helper_headers = $(wildcard $(cppdir)/T*Base.h)

__setup_targets += $(_idlmock_headers)  $(_idlmock_srcs)

endif # ifeq ($(TOI_PLUGIN_MIME)$(TOIWEB_PLUGIN),)

### JS

ifneq ($(TOI_PLUGIN_MIME),)

TOI_IDLS := $(filter-out ToiEvent%, $(TOI_IDLS))
TOI_IDLS := $(filter-out ToiMultiple%, $(TOI_IDLS))

gen_js_headers += $(addprefix $(jsdir)/,$(TOI_IDLS:%.idl=%.h))
gen_js_headers += $(jsdir)/TPlugin.h
_gen_js_srcs += $(addprefix $(jsdir)/,$(TOI_IDLS:%.idl=%.cpp))
gen_js_srcs = $(filter-out %Exception.cpp, $(_gen_js_srcs))
gen_js_srcs += $(jsdir)/TPlugin.cpp
gen_js_objs += $(addprefix $(TARGET_OBJS_DIR)/,$(gen_js_srcs:%.cpp=%.o))
gen_js_srcs_common += $(jsdir)/npglue.cpp
gen_js_objs_common += $(addprefix $(TARGET_OBJS_DIR)/,$(gen_js_srcs_common:%.cpp=%.o))

IDL_OBJS = $(gen_js_objs) $(gen_js_objs_common)
IDL_SRCS = $(gen_js_srcs) $(gen_js_srcs_common)

LDFLAGS += -ljscommon

SRCS += $(gen_js_srcs) $(gen_js_srcs_common)

CPPFLAGS += -DPLUGIN_MIMETYPE=$(TOI_PLUGIN_MIME)
CPPFLAGS += -DPLUGIN_VERSION=$(TOI_PLUGIN_VER)

ifeq ($(TOOLCHAIN),$(ST40_TOOLCHAIN_NAME))
# Workaround for plugin static variable memory leak (KREATV-13688)
# May be removed once ST toolchain issue is fixed
CXXFLAGS += -fno-use-cxa-atexit
endif

endif # ifneq ($(TOI_PLUGIN_MIME),)

### TOIWEB

ifneq ($(TOIWEB_PLUGIN),)

TOI_IDLS := $(filter-out ToiEvent%, $(TOI_IDLS))
TOI_IDLS := $(filter-out ToiMultiple%, $(TOI_IDLS))

js_doc = .idltoiweb
_toi_service := $(filter-out %Observer.idl %Exception.idl, $(TOI_IDLS))
_toi_observer := $(filter %Observer.idl, $(TOI_IDLS))
_toi_exception := $(addprefix $(TOI_IDL_DIR)/, $(filter %Exception.idl, $(TOI_IDLS)))
_gen_js_headers += $(addprefix $(toiweb_jsdir)/,$(_toi_service:%.idl=T%Callable.h))
_gen_js_headers += $(addprefix $(toiweb_jsdir)/,$(_toi_observer:%Observer.idl=T%Observer.h))
gen_toiweb_headers = $(filter-out %ObserverCallable.h, $(_gen_js_headers))
gen_js_headers = $(gen_toiweb_headers)
gen_js_headers += $(toiweb_jsdir)/TPlugin.h
_gen_js_srcs += $(addprefix $(toiweb_jsdir)/,$(_toi_service:%.idl=T%Callable.cpp))
_gen_js_srcs += $(addprefix $(toiweb_jsdir)/,$(_toi_observer:%Observer.idl=T%Observer.cpp))
gen_js_srcs = $(filter-out %Exception.cpp, $(filter-out %ObserverCallable.cpp, $(_gen_js_srcs)))
gen_js_srcs += $(toiweb_jsdir)/TPlugin.cpp
gen_js_objs += $(addprefix $(TARGET_OBJS_DIR)/,$(gen_js_srcs:%.cpp=%.o))
gen_js_objs_common += $(addprefix $(TARGET_OBJS_DIR)/,$(gen_js_srcs_common:%.cpp=%.o))

IDL_OBJS = $(gen_js_objs) $(gen_js_objs_common)
IDL_SRCS = $(gen_js_srcs) $(gen_js_srcs_common)

LDFLAGS += -ljscommon

SRCS += $(gen_js_srcs) $(gen_js_srcs_common)

endif # ifneq ($(TOIWEB_PLUGIN),)

### Dist

ifeq ($(TOI_PLUGIN_MIME)$(TOIWEB_PLUGIN),)

SETUP_TARGETS += dist_generic_idl dist_cpp_idl dist_js_idl dist_toiweb_idl

# cpp

INTERFACE_HEADERS += $(gen_cpp_headers)
INTERFACE_HEADERS += $(gen_cpp_base_headers)

ifeq ($(TOOLCHAIN) $(BUILD_TEST), $(HOST_TOOLCHAIN_NAME) true)
  __interface_mock_h += $(_idlmock_headers)
endif

else # ifeq ($(TOI_PLUGIN_MIME)$(TOIWEB_PLUGIN),)

SETUP_TARGETS += $(gen_js_srcs) $(gen_js_srcs_common)

INTERFACE_PATH = interface
INTERFACE_HEADERS += $(filter-out %TPlugin.h, $(filter-out %Exception.h, $(gen_js_headers)))

endif # ifeq ($(TOI_PLUGIN_MIME)$(TOIWEB_PLUGIN),)

endif
