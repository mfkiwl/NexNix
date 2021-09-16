# build.mk - contains nexboot build system
# SPDX-License-Identifer: ISC

PHONY += boot_config boot boot_clean

# Where are intermediate files are put
BOOT_OBJDIR := $(GLOBAL_BUILDDIR)/boot

# Source directory
BOOT_SRCDIR := boot

# Header files
BOOT_HDRFILES := $(BOOT_SRCDIR)/include/nexboot.h \
				$(BOOT_SRCDIR)/include/nbefi.h \
				$(BOOT_SRCDIR)/include/nbbase.h

# Generates object directory
boot_config:
	@mkdir -p $(BOOT_OBJDIR)
ifeq ($(GLOBAL_BOARD),pc)
	@mkdir -p $(BOOTEFI_OBJDIR)
endif
	@mkdir -p $(GLOBAL_INCDIR)/boot

# Installs boot headers
$(GLOBAL_INCDIR)/boot/hdrstate: $(BOOT_HDRFILES)
	@cp --preserve=timestamps $? $(GLOBAL_INCDIR)/boot/.
	@touch $@

ifeq ($(GLOBAL_BOARD),pc)

# Source file list
BOOT_SRCFILES := $(BOOT_SRCDIR)/mach/bios/main.c

# Object files
BOOT_OBJFILES := $(patsubst %.c,$(GLOBAL_BUILDDIR)/%.c.o,$(BOOT_SRCFILES))

# Assembler sources
BOOT_ASFILES := $(BOOT_SRCDIR)/mach/bios/arch/$(GLOBAL_MACH)/start.asm
BOOT_ASOBJS := $(patsubst %.asm,$(GLOBAL_BUILDDIR)/%.asm.o,$(BOOT_ASFILES))

# Linker script (for BIOS)
BOOT_BIOS_LDSCRIPT := $(BOOT_SRCDIR)/mach/bios/link.ld
BOOT_BIOS_LDFLAGS += -T$(BOOT_BIOS_LDSCRIPT)

# Boot output names
BOOT_OUTPUTNAME := $(BOOT_OBJDIR)/nexboot
BOOT_MBRNAME := $(BOOT_OBJDIR)/nbmbr
BOOT_VBRNAME := $(BOOT_OBJDIR)/nbvbr
BOOT_ISOMBRNAME := $(BOOT_OBJDIR)/nbisombr

BOOT_OUTPUTNAMES := $(BOOT_OUTPUTNAME) $(BOOT_MBRNAME) $(BOOT_VBRNAME) $(BOOT_ISOMBRNAME)

# MBR main rule
$(BOOT_MBRNAME): $(BOOT_SRCDIR)/mach/bios/bootstrap/mbr.asm Makefile
	@echo "[AS] Building $<"
	@$(AS) -fbin $< -o $@
	@echo "[INSTALL] Installing $(notdir $@)"
	@install $@ $(GLOBAL_OUTPUTDIR)/$(notdir $@)

# VBR main rule
$(BOOT_VBRNAME): $(BOOT_SRCDIR)/mach/bios/bootstrap/vbr.asm Makefile
	@echo "[AS] Building $<"
	@$(AS) -fbin $< -o $@
	@echo "[INSTALL] Installing $(notdir $@)"
	@install $@ $(GLOBAL_OUTPUTDIR)/$(notdir $@)
	
# ISOMBR main rule
$(BOOT_ISOMBRNAME): $(BOOT_SRCDIR)/mach/bios/bootstrap/isombr.asm Makefile
	@echo "[AS] Building $<"
	@$(AS) -fbin $< -o $@
	@echo "[INSTALL] Installing $(notdir $@)"
	@install $@ $(GLOBAL_OUTPUTDIR)/$(notdir $@)

$(eval $(call CLEAN_TEMPLATE,boot_clean,boot,$(BOOT_OBJDIR)))
$(eval $(call LD_TEMPLATE,$(BOOT_OUTPUTNAME),$(BOOT_OBJFILES) $(BOOT_ASOBJS),\
		$(LIBK_OUTPUTNAME) $(BOOT_BIOS_LDSCRIPT),nexboot,$(BOOT_LINKLIBS),\
		$(BOOT_BIOS_LDFLAGS) $(BOOT_BIOS_LDFLAGS_$(GLOBAL_MACH)),$(GLOBAL_INCDIR)/boot/hdrstate))
$(eval $(call CC_TEMPLATE,$(BOOT_OBJDIR),$(BOOT_SRCDIR),$(BOOT_BIOS_CFLAGS) $(BOOT_BIOS_CFLAGS_$(GLOBAL_MACH))))
$(eval $(call AS_TEMPLATE,$(BOOT_OBJDIR),$(BOOT_SRCDIR)))

# EFI loader stuff
# Where EFI stuff is located
BOOTEFI_SRCDIR := boot/mach/efi

# ALl of the source for the loader
BOOTEFI_OBJDIR := $(GLOBAL_BUILDDIR)/bootefi
BOOTEFI_SRCFILES := $(BOOTEFI_SRCDIR)/main.c \
					$(BOOTEFI_SRCDIR)/efilib.c
BOOTEFI_OBJFILES := $(patsubst %.c,$(BOOTEFI_OBJDIR)/%.c.o,$(BOOTEFI_SRCFILES))

# Output file for bootloader
BOOTEFI_OUTPUTNAME := $(BOOTEFI_OBJDIR)/nexboot.efi

# EFI distribution files
GLOBAL_DISTFILES += $(BOOTEFI_SRCFILES)

GLOBAL_DEPFILES += $(patsubst %.o,%.d,$(BOOTEFI_OBJFILES))

# EFI linker target
$(BOOTEFI_OUTPUTNAME): $(GLOBAL_INCDIR)/hdrstate $(GLOBAL_INCDIR)/boot/hdrstate \
						$(BOOTEFI_OBJFILES) $(LIBK_OUTPUTNAME) Makefile
	@echo "[LD] Linking $(notdir $@)"
	@$(MINGW_CC) -L $(GLOBAL_PREFIX)/lib $(BOOTEFI_LDFLAGS) $(BOOTEFI_LDFLAGS_$(GLOBAL_MACH)) \
					 $(BOOTEFI_OBJFILES) -lk -o $(BOOTEFI_OUTPUTNAME)
	@echo "[INSTALL] Installing $(notdir $@)"
	@install $(BOOTEFI_OUTPUTNAME) $(GLOBAL_OUTPUTDIR)/nexboot.efi

# Compiler target
$(BOOTEFI_OBJDIR)/boot/mach/efi/%.c.o: $(BOOTEFI_SRCDIR)/%.c Makefile
	@echo "[CC] Building $<"
	@mkdir -p $(dir $@)
	@$(MINGW_CC) -DCONFFILE=\"$(GLOBAL_ARCH).h\" -MD $(GLOBAL_CFLAGS) $(BOOTEFI_CFLAGS) \
				$(BOOTEFI_CFLAGS_$(GLOBAL_MACH)) -c $< -o $@

# Main build rule
boot: $(BOOT_OUTPUTNAMES) $(BOOTEFI_OUTPUTNAME)
endif
ifeq ($(GLOBAL_BOARD),virt)

BOOT_SRCFILES := $(BOOT_SRCDIR)/mach/virt/main.c
BOOT_ASFILES := $(BOOT_SRCDIR)/mach/virt/arch/$(GLOBAL_MACH)/start.asm

BOOT_OBJFILES := $(patsubst %.c,$(GLOBAL_BUILDDIR)/%.c.o,$(BOOT_SRCFILES))
BOOT_ASOBJS := $(patsubst %.asm,$(GLOBAL_BUILDDIR)/%.asm.o,$(BOOT_ASFILES))

BOOT_VIRT_LDSCRIPT := $(BOOT_SRCDIR)/mach/virt/arch/$(GLOBAL_MACH)/link.ld
BOOT_VIRT_LDFLAGS += -T$(BOOT_VIRT_LDSCRIPT)

BOOT_OUTPUTNAME = $(BOOT_OBJDIR)/nexboot

$(eval $(call CLEAN_TEMPLATE,boot_clean,boot,$(BOOT_OBJDIR)))
$(eval $(call LD_TEMPLATE,$(BOOT_OUTPUTNAME),$(BOOT_ASOBJS) $(BOOT_OBJFILES),\
		$(LIBK_OUTPUTNAME) $(BOOT_VIRT_LDSCRIPT),nexboot,$(BOOT_LINKLIBS),$(BOOT_VIRT_LDFLAGS),\
		$(GLOBAL_INCDIR)/boot/hdrstate))
$(eval $(call CC_TEMPLATE,$(BOOT_OBJDIR),$(BOOT_SRCDIR),$(BOOT_VIRT_CFLAGS),$(GLOBAL_INCDIR)/boot/hdrstate))
$(eval $(call AS_TEMPLATE,$(BOOT_OBJDIR),$(BOOT_SRCDIR)))

boot: $(BOOT_OUTPUTNAME)
endif

# Dependency list
GLOBAL_DEPFILES += $(patsubst %.o,%.d,$(BOOT_OBJFILES))

# Distribution files
GLOBAL_DISTFILES += $(BOOT_SRCDIR)/boot.cfg $(BOOT_SRCDIR)/build.mk $(BOOT_HDRFILES)\
			$(BOOT_SRCFILES)
