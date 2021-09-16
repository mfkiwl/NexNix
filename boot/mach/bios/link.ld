/*
    link.ld - contains linker script for nexboot i386
    SPDX-License-Identifier: ISC
*/

OUTPUT_FORMAT(binary)
ENTRY(nb_entry)

NB_BASE = 0x3C00;

SECTIONS 
{
    /* We are loaded to 0x3C00 by the VBR */
    . = NB_BASE;

    .text :
    {
        *(.text)
    }
    .data :
    {
        *(.data)
    }
    .rodata :
    {
        *(.rodata*)
    }
    .bss :
    {
        *(COMMON)
        *(.bss)
    }

    end = .;
}
