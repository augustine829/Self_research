ifneq ($(TOI_IDL_DIR),)

ifeq ($(TOI_PLUGIN_MIME)$(TOIWEB_PLUGIN),)
-include $(toijsfiles)
-include $(toideps)

$(toijsfiles): $(toi_idls) | .makefile .sources
ifneq ($(if $(MAKECMDGOALS),$(filter-out $(__quick_targets),$(MAKECMDGOALS)),true),)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	$(Q)temp=$$(mktemp) && \
	  $(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -bjsfiles -I$(TOI_IDL_PATH) $(toi_idls) > $$temp && \
	  mkdir -p $(@D) && \
	  mv $$temp $@
endif

$(toideps): $(toi_idls) | .makefile .sources
ifneq ($(if $(MAKECMDGOALS),$(filter-out $(__quick_targets),$(MAKECMDGOALS)),true),)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	$(Q)temp=$$(mktemp) && \
	  $(DIST_DIR)/bin/idldeps $(TOI_IDL_DIR) $(TOI_IDL_PATH) $(TOI_CPP_IDL_PATH) $(TOI_JS_IDL_PATH) $(toi_idls) > $$temp && \
	  $(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -bjsfiles -Wbdep -I$(TOI_IDL_PATH) $(toi_idls) >> $$temp && \
	  mkdir -p $(@D) && \
	  mv $$temp $@
endif

$(toievents): $(toi_idls)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(DIST_DIR)/bin/geneventids $(toi_idls) > $@

$(toiinherits): $(toi_idls)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	$(Q)temp=$$(mktemp) && { \
          $(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -binheritance -I$(TOI_IDL_PATH) $(toi_idls) > $$temp; \
          mkdir -p $(@D); \
          mv $$temp $@; \
        }

$(_install_headers): install_cpp_helper_headers

install_cpp_helper_headers: $(gen_cpp_srcs)
ifneq ($(gen_cpp_helper_headers),)
	$(MAKESYSTEM)/dist_targets $(gen_cpp_helper_headers) $(TARGET_INSTALL_DIR)/include/$(_platform_helpers_interface_path)
endif
ifneq ($(gen_suppressible_observer_headers),)
	$(MAKESYSTEM)/dist_targets $(gen_suppressible_observer_headers) $(TARGET_INSTALL_DIR)/include/$(_platform_helpers_interface_path)
endif


.PHONY: install_cpp_helper_headers
else
-include $(toideps)
endif # ifeq ($(TOI_PLUGIN_MIME)$(TOIWEB_PLUGIN),)

$(cppdir)/IIDLExceptionCodes.idl: $(toi_idls)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(DIST_DIR)/bin/genexceptioncodes idl interface $(toi_idls) > $@

$(cppdir)/IpcCaller.cpp: $(toi_idls)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(DIST_DIR)/bin/genexceptioncodes caller interface $(toi_idls) > $@

$(cppdir)/IToiTypes.h: $(toi_idls)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(DIST_DIR)/bin/genexceptioncodes types interface $(toi_idls) > $@

$(cppdir)/%.idl: $(TOI_IDL_DIR)/%.idl $(_idl_compiler_marker) | $(toievents)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -bgenericidl -WbC++ -Wb$(TOI_COMPONENT) -Wb$(toievents) -I$(TOI_IDL_PATH) -C $(@D) $<

$(cppdir)/%Exception.h: $(cppdir)/IIDLExceptionCodes.h

$(cppdir)/%.h: $(cppdir)/%.idl $(_idl_compiler_marker)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	$(Q)$(IDL_COMPILER) -p$(IDL_BACKEND_PATH) -K -I$(TOI_CPP_IDL_PATH) $(IDL_INCLUDE_STRING) -btoaidl -Wb$(_idl_backend_include_path) -Wb$(TOI_COMPONENT) -Wb$(toievents) -C $(@D) $<

$(cppdir)/T%Adapter.h: $(cppdir)/I%.h ;
$(cppdir)/T%Suppressible.h: $(cppdir)/I%.h ;

$(cppdir)/T%Caller.h: $(cppdir)/I%.h ;
$(cppdir)/T%Caller.cpp: $(cppdir)/T%Caller.h ;

$(cppdir)/T%Dispatcher.h: $(cppdir)/I%.h ;
$(cppdir)/T%Dispatcher.cpp: $(cppdir)/T%Dispatcher.h ;

$(cppdir)/T%Base.h: $(cppdir)/I%.h ;

# This rule creates four files:
# * I$(TOI_COMPONENT)Callers.h
# * T$(TOI_COMPONENT)Callers.h
# * mocks/T$(TOI_COMPONENT)MockCallers.h
# * mocks/T$(TOI_COMPONENT)MockCallers.cpp
$(cppdir)/I$(_toi_caller_factory_name).h: $(gen_cpp_idls)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)/mocks
	$(Q)python2 $(DIST_DIR)/bin/callerfactory.py -I$(TOI_CPP_IDL_PATH) $(@D) $(TOI_COMPONENT) $(_idl_backend_include_path) $(gen_cpp_idls)

$(cppdir)/T$(_toi_caller_factory_name).h: $(cppdir)/I$(_toi_caller_factory_name).h
$(cppdir)/T$(_toi_caller_factory_name).cpp: $(cppdir)/I$(_toi_caller_factory_name).h
$(cppdir)/mocks/T$(_toi_mock_caller_factory_name).h: $(cppdir)/I$(_toi_caller_factory_name).h
$(cppdir)/mocks/T$(_toi_mock_caller_factory_name).cpp: $(cppdir)/I$(_toi_caller_factory_name).h

$(jsdir)/%.idl: $(TOI_IDL_DIR)/I%.idl $(_idl_compiler_marker) | $(toievents) $(toiinherits)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -bgenericidl -WbJavaScript -WbToi2 -Wb$(TOI_COMPONENT) -Wb$(toievents) -Wb$(toiinherits) -I$(TOI_IDL_PATH) -C $(@D) $<

$(jsdir)/%.idl: $(TOI_IDL_DIR)/%.idl $(_idl_compiler_marker) | $(toievents) $(toiinherits)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -bgenericidl -WbJavaScript -WbToi2 -Wb$(TOI_COMPONENT) -Wb$(toievents) -Wb$(toiinherits) -I$(TOI_IDL_PATH) -C $(@D) $<

$(toiweb_jsdir)/%.idl: $(TOI_IDL_DIR)/I%.idl $(_idl_compiler_marker) | $(toievents) $(toiinherits)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -bgenericidl -WbJavaScript -WbToi3 -Wb$(TOI_COMPONENT) -Wb$(toievents) -Wb$(toiinherits) -I$(TOI_IDL_PATH) -C $(@D) $<

$(toiweb_jsdir)/%.idl: $(TOI_IDL_DIR)/%.idl $(_idl_compiler_marker) | $(toievents) $(toiinherits)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -bgenericidl -WbJavaScript -WbToi3 -Wb$(TOI_COMPONENT) -Wb$(toievents) -Wb$(toiinherits) -I$(TOI_IDL_PATH) -C $(@D) $<

$(gen_js_srcs): $(gen_js_headers)

$(jsdir)/TPlugin.h: $(toi_idls)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)python2 $(DIST_DIR)/bin/cplugin.py $(@D) $(toi_idls)

$(toiweb_jsdir)/TPlugin.h: $(toi_idls) $(gen_toiweb_headers)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(if $(_toi_exception), $(Q)$(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -I$(TOI_JS_IDL_PATH) $(IDL_INCLUDE_STRING) -I$(toiweb_jsdir) -btoiwebjsidl -Wb$(_idl_backend_include_path) -Wb$(toievents) $(IDL_INCPATH) -C $(@D) $(_toi_exception))
	$(Q)python2 $(DIST_DIR)/bin/toiwebcplugin.py $(@D)
	$(Q)python2 $(DIST_DIR)/bin/toiwebjs_final.py $(@D) $(toi_idls)

$(TARGET_OBJS_DIR)/%/TPlugin.o: $(gen_js_headers)

$(TARGET_OBJS_DIR)/%/npglue.o: $(gen_js_headers)

$(jsdir)/npglue.cpp: $(JS_COMMON_PATH)/npglue.cpp
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)cp $< $@

$(jsdir)/%.h: $(TOI_IDL_DIR)/%.idl $(_idl_compiler_marker) | $(toievents)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -I$(TOI_JS_IDL_PATH) $(IDL_INCLUDE_STRING) -I$(jsdir) -btoajsidl -Wb$(_idl_backend_include_path) -Wb$(toievents) $(IDL_INCPATH) -C $(@D) $<

$(toiweb_jsdir)/T%Callable.h: $(TOI_IDL_DIR)/%.idl $(_idl_compiler_marker) | $(toievents)
	@rm -rf $(addprefix $(js_doc)/, $(patsubst %.idl, %.jsdoc, $(notdir $<)))
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -I$(TOI_JS_IDL_PATH) $(IDL_INCLUDE_STRING) -I$(toiweb_jsdir) -btoiwebjsidl -Wb$(_idl_backend_include_path) -Wb$(toievents) -Wb$(basename $(notdir $<)) $(IDL_INCPATH) -C $(@D) $(wildcard $(<D)/$**.idl)

$(toiweb_jsdir)/T%Observer.h: $(TOI_IDL_DIR)/%Observer.idl $(_idl_compiler_marker) | $(toievents)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -I$(TOI_JS_IDL_PATH) $(IDL_INCLUDE_STRING) -I$(toiweb_jsdir) -btoiwebjsidl -Wb$(_idl_backend_include_path) -Wb$(toievents) $(IDL_INCPATH) -C $(@D) $<
	# The following code will process Event.
	$(Q)$(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -I$(TOI_JS_IDL_PATH) $(IDL_INCLUDE_STRING) -I$(toiweb_jsdir) -btoiwebjsidl -Wb$(_idl_backend_include_path) -Wb$(toievents) $(IDL_INCPATH) -C $(@D) $(addprefix $(<D)/, $(filter $(patsubst %Observer.idl, %, $(<F))%Event.idl, $(shell ls $(<D))))

$(cppdir)/mocks/TMock%.h: $(cppdir)/I%.idl $(_idl_compiler_marker)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -p$(IDL_BACKEND_PATH) -K -I$(TOI_CPP_IDL_PATH) $(IDL_INCLUDE_STRING) -bcppmock -Wbh -C $(@D) $<

$(cppdir)/mocks/TMock%.cpp: $(cppdir)/I%.idl $(cppdir)/mocks/TMock%.h $(_idl_compiler_marker)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -p$(IDL_BACKEND_PATH) -K -I$(TOI_CPP_IDL_PATH) $(IDL_INCLUDE_STRING) -bcppmock -Wbcpp -C $(@D) $<

$(pydir)/ToiExceptions.py: $(cppdir)/IIDLExceptionCodes.idl $(_idl_compiler_marker)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -bpyexceptions -WbC++ \
        -Wb$(TOI_COMPONENT) -I$(TOI_IDL_PATH) -C $(@D) $<

# Generate __init__.py after all other generated python sources, since the IDL
# compiler adds shortcuts like 'from Foo import Foo' to __init__.py for all Foo
# modules that have been generated before __init__.py. Without this line, there
# will be a race and __init__.py may look different from build to build.
$(pydir)/__init__.py: $(filter-out %__init__.py, $(KATTENV_TARGETS))

$(pydir)/__init__.py: $(cppdir)/IIDLExceptionCodes.idl $(_idl_compiler_marker)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -nf -p$(IDL_BACKEND_PATH) -K -bpyinit -WbC++ \
        -Wb$(TOI_COMPONENT) -I$(TOI_IDL_PATH) -C $(@D) $<

$(pydir)/%.py: $(cppdir)/I%.idl $(_idl_compiler_marker)
	@$(PRINT_PROGRESS) IDL_GEN "$@"
	@mkdir -p $(@D)
	$(Q)$(IDL_COMPILER) -p$(IDL_BACKEND_PATH) -K -I$(TOI_CPP_IDL_PATH) \
	$(IDL_INCLUDE_STRING) -btoapyidl -Wb$(_idl_backend_include_path) \
	-Wb$(TOI_COMPONENT) -C $(@D) $<

dist_generic_idl: $(toi_idls)
	@$(MAKESYSTEM)/dist_targets $(toi_idls) $(GENERIC_IDL_PATH)/$(TOI_EXPORT_PATH)

dist_cpp_idl: $(gen_cpp_idls)
ifneq ($(gen_cpp_idls),)
	@$(MAKESYSTEM)/dist_targets $(gen_cpp_idls) $(CPP_IDL_PATH)/$(TOI_EXPORT_PATH)
endif

dist_js_idl: $(gen_js_idls)
ifneq ($(gen_js_idls),)
	@$(MAKESYSTEM)/dist_targets $(gen_js_idls) $(JS_IDL_PATH)/$(TOI_EXPORT_PATH)
endif

dist_toiweb_idl: $(gen_toiweb_idls)
ifneq ($(gen_toiweb_idls),)
	@$(MAKESYSTEM)/dist_targets $(gen_toiweb_idls) $(TOIWEB_JS_IDL_PATH)/$(TOI_EXPORT_PATH)
endif

.PHONY: dist_generic_idl dist_cpp_idl dist_js_idl dist_toiweb_idl

.SECONDARY: $(gen_cpp_base_headers) $(gen_cpp_headers) $(gen_cpp_srcs)
.SECONDARY: $(gen_cpp_helper_headers)

.SECONDARY: $(gen_js_headers) $(gen_js_srcs) $(gen_js_srcs_common)

endif
