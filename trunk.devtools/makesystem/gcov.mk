# This file contains settings for code coverage analysis with gcov.

GCOV_COMMON_FLAGS = --coverage
GCOV_LDFLAGS = --coverage
GCOV = $(HOST_GCOV)

NO_SCU = 1  # Compile individual files for coverage measurements

ifndef COMPONENT_IS_3PP
  ifdef NOT_SUITABLE_FOR_UNIT_TESTS
    define _gcov_parse
	$(PRINT_PROGRESS) COVERAGE "$(COMPONENT) N/A"
    endef
  else
    ifeq ($(TOOLCHAIN),$(HOST_TOOLCHAIN_NAME))
      # Set up compiler and linker flags.
      COMMON_FLAGS += $(GCOV_COMMON_FLAGS)
      ifeq ($(NOT_SUITABLE_FOR_UNIT_TESTS),true)
        _gcov_store =
      else
        _gcov_store = $(if $(_enable_gcov), \
          @echo "$(GCOV) -o $@ $<" >> .gcov_runs)
      endif
    endif

    define _gcov_parse
	@if [ -f .gcov_runs ]; then \
	  sort -u .gcov_runs >.gcov_runs.tmp && \
	  mv .gcov_runs.tmp .gcov_runs ; \
	fi; \
	$(PYTHON2) $(MAKESYSTEM)/gcovparse
    endef
  endif
endif

# Link with coverage flags. (This is needed even for 3pps because unit tests
# may refer to non-3pp object files which may need -lgcov.)
ifeq ($(TOOLCHAIN),$(HOST_TOOLCHAIN_NAME))
  LDFLAGS += $(GCOV_LDFLAGS)
endif
