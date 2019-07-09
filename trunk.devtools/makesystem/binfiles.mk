include $(MAKESYSTEM)/bref_common.mk

# We only need to find .bref files if leaf_component AND (running_local_clean
# OR (running_local_all AND NOT running_componentcache)).
ifneq ($(REQUIRES),ALL_DIRS)
  ifeq ($(filter local_clean,$(MAKECMDGOALS)),local_clean)
    __do_find_binref_files = true
  else ifeq ($(USE_COMPONENTCACHE),)
    ifneq ($(filter local_all,$(MAKECMDGOALS)),)
      __do_find_binref_files = true
    endif
  endif
  ifeq ($(__do_find_binref_files), true)
    __binref_files := \
      $(shell find -L \( -false $(addprefix -o$(space)-path$(space)./, \
                                            .\* \
                                            $(subst $(CURDIR)/,,$(SRC_DIR)) \
                                            $(subst $(CURDIR)/,,$(SRC_DIR).bak.\*) \
                                            $(_all_available_toolchains)) \) \
                      -prune -false -o -type f -name '*.bref' \
              | sed -r 's!^\./(.*)\.bref$$!\1!')
  endif
endif

# $(1): Path (relative to ".") of file referenced by $(1).bref.
# $(2): Progress printing command.
define __binref_template
$(call __bref_fetch_template,$(1),$(2))

  ifndef NO_AUTO_FETCH_BREFS
    # Fetch binary file before building setup targets.
    .setup $(__setup_targets): $(call __bref_stamp,$(1))
  endif
endef

$(foreach file,$(__binref_files),$(eval $(call __binref_template,$(file),$(PRINT_PROGRESS) GET_BINARY)))

# Only remove unmodified binary files when cleaning.
ifneq ($(__binref_files),)
local_clean: .clean_binref_files
.PHONY: .clean_binref_files
.clean_binref_files:
	@$(call __bref_clean_template, $(__binref_files))
endif
