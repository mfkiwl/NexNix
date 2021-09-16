# toolchain.mk - contains make data for toolchain variables
# SPDX-License-Identifier: ISC

# Set common architecture
ifeq ($(GLOBAL_BOARD),pc)
GLOBAL_COMMONARCH := x86
MINGW_CC := $(GLOBAL_CROSS)/bin/$(GLOBAL_MACH)-mingw32-gcc
endif

# Setup toolchain variables
CC := $(GLOBAL_CROSS)/bin/$(GLOBAL_MACH)-elf-gcc
ifeq ($(GLOBAL_COMMONARCH),x86)
AS := nasm
GLOBAL_ASFLAGS := $(GLOBAL_NASM_ASFLAGS_$(GLOBAL_MACH))
else
AS := $(GLOBAL_CROSS)/bin/$(GLOBAL_MACH)-elf-as
GLOBAL_ASFLAGS :=
endif
LD := $(GLOBAL_CROSS)/bin/$(GLOBAL_MACH)-elf-ld
AR := $(GLOBAL_CROSS)/bin/$(GLOBAL_MACH)-elf-ar
OBJCOPY := $(GLOBAL_CROSS)/bin/$(GLOBAL_MACH)-elf-objcopy
NM := $(GLOBAL_CROSS)/bin/$(GLOBAL_MACH)-elf-nm

# Set debug / release C Flags
ifeq ($(GLOBAL_DEBUG),1)
GLOBAL_CFLAGS += $(GLOBAL_DEBUG_CFLAGS)
else
GLOBAL_CFLAGS += $(GLOBAL_RELEASE_CFLAGS)
endif
