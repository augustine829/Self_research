# Generic rule used for directories

all $(TREEDIRS): makesystem

# Touch .requires files to make sure they are not built when including
# them in common.mk, they will be deleted anyway
makesystem $(TREEDIRS):
	@case $(TREE_RULE) in \
	  local_all) begin="Building $@"; end="Finished building $@" ;; \
	  local_clean) begin="Cleaning $@"; end="Finished cleaning $@" ;; \
	  *) begin="Building $(TREE_RULE) in $@"; end="Finished building $(TREE_RULE) in $@" ;; \
	esac; \
	echo "=== $$begin ==="; \
	if [ $(TREE_RULE) = "local_clean" ]; then \
	  touch $(BSG_SRC_ABS)/$@/.requires $(BSG_SRC_ABS)/$@/.requires_depend ; \
	fi ; \
	if [ -n "$$DAILY_LOG_DIR" ]; then \
	  part=$$(echo "$@" | sed -e 's,_,__,g' -e 's,/,_,g') ; \
	  if [ ! -f $(DAILY_LOG_DIR)/result_$$part.txt ]; then \
	    command time -f "$$(date +%s.%N) $@ %e %U %S" \
	                 -a -o $(DAILY_LOG_DIR)/buildtime.txt \
	      $(MAKE) -C $(BSG_SRC_ABS)/$@ $(TREE_RULE) \
	        >> $(DAILY_LOG_DIR)/result_$$part.txt 2>&1 ; \
	  fi; \
	else \
	  $(MAKE) -C $(BSG_SRC_ABS)/$@ $(TREE_RULE) ; \
	fi; \
	exitcode=$$?; \
	if [ $$exitcode -eq 0 ]; then \
	  echo "=== $$end ==="; \
	else \
	  echo "*** Error when building $(TREE_RULE) in $(BSG_SRC_ABS)/$@"; \
	  echo $@ >>.failed_components; \
	fi; \
	exit $$exitcode

.PHONY: all makesystem $(TREEDIRS)
