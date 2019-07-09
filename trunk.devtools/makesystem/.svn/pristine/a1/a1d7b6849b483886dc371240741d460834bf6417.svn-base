#
# Build rules for toiweb plugin support.
# see makesystem/doc/README.mmd for documentation
#

ifndef TOIWEB_PLUGIN_IDLS
$(error TOIWEB_PLUGIN_IDLS must be set before using toiweb.mk)
endif

ifndef TOIWEB_PLUGIN
$(error TOIWEB_PLUGIN must be set before using toiweb.mk)
endif

ifndef TOI_COMPONENT
$(error TOI_COMPONENT must be set before using toiweb.mk)
endif

ifndef TOI_IDL_DIR
$(error TOI_IDL_DIR must be set before using toiweb.mk)
endif

NOT_SUITABLE_FOR_UNIT_TESTS = true

INTERFACE_LIBS += toiweb_$(TOIWEB_PLUGIN)_plugin

TOI_IDLS = $(TOIWEB_PLUGIN_IDLS:I%.idl=%.idl)

toi_plugin_target += $(TARGET_OBJS_DIR)/libtoiweb_$(TOIWEB_PLUGIN)_plugin.so

LIB_TARGETS += $(toi_plugin_target)

# JavaScript files
js_files = .idltoiweb/*.js
js_doc_files = .idltoiweb/*.jsdoc
js_files_num = $(shell ls .idltoiweb|grep -c ".js$$")
jsdoc_files_num = $(shell ls .idltoiweb|grep -c ".jsdoc$$")

install_js_files = .install_js_files
NOARCH_TARGETS += $(install_js_files)
CLEANUP_FILES += $(install_js_files)

# Back up JavaScript files before obfuscated
original_js_files = .original_js_files
NOARCH_TARGETS += $(original_js_files)
CLEANUP_FILES += $(original_js_files)

# JavaScript definition files
js_def_file  = .idltoiweb/toidef.toijs
install_js_def_file  = .install_js_def_file
NOARCH_TARGETS += $(install_js_def_file)
CLEANUP_FILES += $(install_js_def_file)

# Directory to keep compressed JavaScript files
compressed_dir = .compressedJs
CLEANUP_FILES += $(compressed_dir)

### Common.mk

include $(subst toiweb,common,$(lastword $(MAKEFILE_LIST)))

### Build rules

# Allow generated plugin code to call deprecated TOI methods
CXXFLAGS += -Wno-deprecated-declarations

$(toi_plugin_target): $(IDL_OBJS)
	$(LINK_SO) -Wl,--version-script=$(DIST_DIR)/config/plugin.ver


$(original_js_files): $(IDL_SRCS)
	@$(PRINT_PROGRESS) INSTALL "Back up non-obfuscated JaveScript files"
	@if [ $(js_files_num) -gt 0 ]; then \
	$(MAKESYSTEM)/dist_targets $(js_files) \
	  $(DIST_DIR)/$(NOARCH_TOOLCHAIN_NAME)/originals/$(TOIWEB_PLUGIN); \
	fi
	@touch $@

$(install_js_files): $(IDL_SRCS)
	@$(PRINT_PROGRESS) INSTALL "Obfuscated JavaScript files"
	mkdir -p $(compressed_dir)
	@if [ $(js_files_num) -gt 0 ]; then \
	$(JAVA) -jar $(DIST_DIR)/3pp/java/yuicompressor.jar \
	  -o '.*/(.*):$(compressed_dir)/$$1' $(js_files); $(MAKESYSTEM)/dist_targets $(compressed_dir)/*.js \
	  $(DIST_DIR)/$(NOARCH_TOOLCHAIN_NAME)/toiweb/$(TOIWEB_PLUGIN); \
	fi
	@$(PRINT_PROGRESS) INSTALL "Obfuscated JavaScript documentation files"
	@if [ $(jsdoc_files_num) -gt 0 ]; then \
	 $(MAKESYSTEM)/dist_targets $(js_doc_files) \
	  $(DIST_DIR)/doc/toiweb/$(TOIWEB_PLUGIN); \
	fi
	@touch $@

$(install_js_def_file): $(IDL_SRCS)
	@$(PRINT_PROGRESS) INSTALL "TOI3/JS helper files for automatic code completion"
	@cat .idltoiweb/*.jsdef > $(js_def_file)
	@cat .idltoiweb/ToidefFinal >> $(js_def_file)
	$(MAKESYSTEM)/dist_targets --rename $(js_def_file) \
	  $(DIST_DIR)/$(NOARCH_TOOLCHAIN_NAME)/autocomplete/toi3_$(TOIWEB_PLUGIN).autocomplete.js
	@rm $(js_def_file)
	@for file in $(js_doc_files); do \
	  filename=$$(basename $$file|cut -d. -f1); \
	  $(MAKESYSTEM)/dist_targets --rename $$file $(DIST_DIR)/$(NOARCH_TOOLCHAIN_NAME)/autocomplete/$$filename.js; \
	done;
	@touch $@
