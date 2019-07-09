# This file may be included by a custom Makefile that only want to handle .bref
# files without using the other parts of makesystem.
#
# When included, .bref files are searched for in the directories specified by
# BREF_DIRS (which defaults to the current directory), and suitable make rules
# are created for the .bref files in those directories. The Makefile should
# depend on the stamp file returned by $(call BREF_STAMP, x), where x is the
# path to the large file. Alternatively, just depend on $(ALL_BREF_STAMPS).
# $(BREF_CLEAN) expands to a command to use in a cleanup rule.
#
# Example usage:
#
#     % ls -1F
#     large_archive.tar.gz.bref
#     Makefile
#     makesystem/
#     % cat Makefile
#     all: some_file_to_build
#
#     large_archive = large_archive.tar.gz
#     large_archive_stamp = $(call BREF_STAMP, $(large_archive))
#
#     include makesystem/bref.mk
#
#     some_file_to_build: $(large_archive_stamp)
#             tar xf $(large_archive)
#             ...
#
#     clean:
#             rm -f some_file_to_build
#             $(BREF_CLEAN)

MAKESYSTEM := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))
include $(MAKESYSTEM)/bref_common.mk

BREF_DIRS ?= .
__bref_files := $(patsubst ./%,%,$(patsubst %.bref,%,$(foreach dir,$(BREF_DIRS),$(wildcard $(dir)/*.bref))))
$(foreach file,$(__bref_files),$(eval $(call __bref_fetch_template,$(file),echo Getting binary)))

ALL_BREF_STAMPS := $(foreach file,$(__bref_files),$(call __bref_stamp,$(file)))

BREF_STAMP = $(__bref_stamp)

BREF_CLEAN = $(call __bref_clean_template, $(__bref_files))
