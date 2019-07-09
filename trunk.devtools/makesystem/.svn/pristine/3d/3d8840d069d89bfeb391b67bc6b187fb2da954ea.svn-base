###
### Klocwork makefile
###
### You may define the following variables in your Makefile
###
### KW_SRCS               -- The source files to analyze
### KW_TARGET             -- The target to use (will control the include paths (default mipsel))
###

KW_SRCS ?= $(SRCS)

KW_TARGET ?= $(TARGET_NAME_VIP1903)
ifeq ($(filter $(KW_TARGET),$(COMPONENT_TARGETS)),)
KW_TARGET = $(word 1,$(COMPONENT_TARGETS))
endif
KW_FLAVOUR ?= $(word 1,$(FLAVOURS))

kw_path = $(MAKESYSTEM)/klocwork
kw_conf_path = $(kw_path)/config

review:
	@TARGET=$(KW_TARGET) FLAVOUR=$(KW_FLAVOUR) $(MAKE) .run_kw_inforce

.run_kw_inforce:
	@KW_SRCS="$(KW_SRCS)" INCPATH="$(INCPATH)" KW_TARGET="$(KW_TARGET)" KW_CONF_PATH="$(kw_conf_path)" $(kw_path)/run_remote
