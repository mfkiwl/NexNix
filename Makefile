# Makefile - contains master build system for all of NexNix
# SPDX-License-Identifier: ISC

# Phony targets in this file
PHONY := all clean config clean dist allconfig

# Default files for use when generating a source distribution
DISTFILES := README.md Makefile LICENSE build.sh $(patsubst scripts/scripts.cfg,,$(wildcard scripts/*))\
		   	 $(wildcard configs/*) $(wildcard dep/*) $(HDRFILES)\
			$(wildcard utils/*)

# Where include files live
GLOBAL_INCDIR := $(GLOBAL_PREFIX)/usr/include

# Header files of the whole project
GLOBAL_HDRFILES := include/config.h \
					include/$(GLOBAL_ARCH).h \
					include/ver.h

# Dependency files go here
GLOBAL_DEPFILES :=

# Where everything gets put
GLOBAL_OUTPUTDIR := $(GLOBAL_PREFIX)/output

# At the moment, a target in some submake will get invoked. To prevent this,
# we reset the default goal
.DEFAULT_GOAL := all

# Include toolchain configuration
include scripts/toolchain.mk

# Template for converting a .c to .o
define CC_TEMPLATE =
$(1)/%.c.o: $(2)/%.c $(4)
	@echo "[CC] Building $$<"
	@mkdir -p $$(dir $$@)
	@$(CC) -DCONFFILE=\"$(GLOBAL_ARCH).h\" -MD $(GLOBAL_CFLAGS) $(3) -c $$< -o $$@
endef

# Template for archiving a static library
define AR_TEMPLATE =
$(1): $(GLOBAL_INCDIR)/hdrstate $(4) $(2)
	@echo "[AR] Archiving $(notdir $(1))"
	@$(AR) rcs $$@ $(2)
	@echo "[INSTALL] Installing $(notdir $(1))"
	@install $(1) $(GLOBAL_OUTPUTDIR)/$(3)
endef

# Template for cleaning a project
define CLEAN_TEMPLATE =
$(1):
	@echo "[CLEAN] Cleaning $(2)"
	@rm -rf $(3)
	@mkdir -p $(3)
endef

# Template for assembler sources
define AS_TEMPLATE =
$(1)/%.asm.o: $(2)/%.asm
	@echo "[AS] Building $$<"
	@mkdir -p $$(dir $$@)
	@$(AS) $(GLOBAL_ASFLAGS) $$< -o $$@
endef

# Template for linking an app
define LD_TEMPLATE =
$(1): $(GLOBAL_INCDIR)/hdrstate $(7) $(2) $(3)
	@echo "[LD] Linking $(notdir $(1))"
	@$(CC) $(GLOBAL_LDFLAGS) $(6) $(2) $(5) -o $(1)
	@echo "[INSTALL] Installing $(notdir $(1))"
	@install $(1) $(GLOBAL_OUTPUTDIR)/$(4)
endef

# Include all sub makefiles
include $(patsubst %,%/build.mk,$(GLOBAL_PROJECTS))

# GLOBAL_PROJECTS contains the names of the targets invoked by all
# They must be identical to the paths of their makefiles
all: $(GLOBAL_PROJECTS)

# Configuration target. We simply invoke the sub-configs
config: allconfig $(patsubst %,%_config,$(GLOBAL_PROJECTS))

# Cleans out all build files
clean: $(patsubst %,%_clean,$(GLOBAL_PROJECTS))

# Generates a distribution set
dist:
	@tar -czf nexnix-$(majorver).$(minorver).$(patchlevel).tar.gz $(GLOBAL_DISTFILES)

# Runs before sub-configs
allconfig:
	@mkdir -p $(GLOBAL_BUILDDIR)
	@mkdir -p $(GLOBAL_PREFIX)/lib $(GLOBAL_PREFIX)/bin $(GLOBAL_OUTPUTDIR)

# Re-installs out of date headers
$(GLOBAL_INCDIR)/hdrstate: $(GLOBAL_HDRFILES)
	@mkdir -p $(GLOBAL_INCDIR)
	@cp --preserve=timestamps $? $(GLOBAL_INCDIR)/.
	@touch $(GLOBAL_INCDIR)/hdrstate

-include $(GLOBAL_DEPFILES)

.PHONY: $(PHONY)
