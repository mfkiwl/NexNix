# build.mk - contains libk build system
# SPDX-License-Identifer: ISC

PHONY += lib/libk lib/libk_clean lib/libk_config

# Object directory, where intermediate files are put
LIBK_OBJDIR := $(GLOBAL_BUILDDIR)/lib/libk

# Directory where source code is
LIBK_SRCDIR := lib/libk

# Source files for libk
LIBK_SRCFILES := $(LIBK_SRCDIR)/mem.c

# Object files
LIBK_OBJFILES := $(patsubst %.c,$(GLOBAL_BUILDDIR)/%.c.o,$(LIBK_SRCFILES))

# Output file
LIBK_OUTPUTNAME := $(LIBK_OBJDIR)/libk.a

# Header files
LIBK_HDRFILES := $(LIBK_SRCDIR)/include/assert.h

GLOBAL_HDRFILES += $(LIBK_HDRFILES)

GLOBAL_DEPFILES += $(patsubst %.o,%.d,$(LIBK_OBJFILES))

# Distribution files
GLOBAL_DISTFILES += $(LIBK_SRCDIR)/libk.cfg $(LIBK_SRCDIR)/build.mk $(LIBK_SRCFILES) $(LIBK_HDRFILES)

lib/libk: $(LIBK_OUTPUTNAME)

lib/libk_config:
	@mkdir -p $(LIBK_OBJDIR)

$(eval $(call CLEAN_TEMPLATE,lib/libk_clean,libk,$(LIBK_OBJDIR)))
$(eval $(call CC_TEMPLATE,$(LIBK_OBJDIR),$(LIBK_SRCDIR),$(LIBK_CFLAGS) $(LIBK_CFLAGS_$(GLOBAL_MACH))))
$(eval $(call AR_TEMPLATE,$(LIBK_OUTPUTNAME),$(LIBK_OBJFILES),../lib/libk.a,))
