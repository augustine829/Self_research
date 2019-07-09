# $(1): Path (relative to ".") of file referenced by $(1).bref.
# $(2): Progress printing command.
define __bref_fetch_template
# Create binary file from .bref file containing a SHA1 hash.
$(1): $(1).bref
	@if [ ! -f "$(1)" ]; then \
	  $(2) "$(1)"; \
	  $(MAKESYSTEM)/binary_file get "$(1)" || exit 1; \
	  . "./$$<" && \
	  echo $$$$sha1 >".bref_$(subst /,_,$(1)).stamp"; \
	fi

# Make it possible for a target to depend on the binary file with an absolute
# path.
$(CURDIR)/$(1): $(1)
	@: We are done when the prerequisite is done, so no build command needed.

# .bref_$(1).stamp tracks the modification time of $(1) so that we can find out
# when the file has been modified without having to hash the file each time we
# build.
.bref_$$(subst /,_,$(1)).stamp: $(1)
	@if [ -z "$$(ALLOW_MODIFIED_BINARY_FILE)" ]; then \
	  . "./$$<.bref" && \
	  real_sha1=$$$$(sha1sum "$$<" | awk '{print $$$$1}') && \
	  if [ "$$$$sha1" != "$$$$real_sha1" ]; then \
	    printf '\nError: Binary file $$< has been modified.\n\n'; \
	    printf 'To keep the change:   $$(MAKESYSTEM)/binary_file upload $$<\n'; \
	    printf 'To revert the change: rm $$<\n'; \
	    printf 'To build anyway:      $(MAKE) $(MAKECMDGOALS) ALLOW_MODIFIED_BINARY_FILE=true\n\n'; \
	    exit 1; \
	  fi; \
	  touch $$@; \
	fi
endef

# Get the bref stamp filename for a path
#
# $(1): Path to .bref file without the .bref suffix
__bref_stamp = .bref_$(subst /,_,$(strip $(1))).stamp

# Generate a cleanup rule
#
# $(1): List of .bref files without the .bref suffix
define __bref_clean_template
	$(foreach file, $(1), \
	  if [ -f "$(file)" ]; then \
	    stamp=".bref_$(subst /,_,$(file)).stamp"; \
	    if [ ! "$(file)" -nt "$$stamp" ]; then \
	      rm -f "$(file)"; \
	    else \
	      orig_sha1=$$(cat "$$stamp" 2>/dev/null) && \
	      current_sha1="$$(sha1sum $(file) | awk '{print $$1}')" && \
	      if [ "$$orig_sha1" = "$$current_sha1" ]; then \
	        rm -f "$(file)"; \
	      fi; \
	    fi; \
	  fi;) \
	rm -f .bref_*
endef
