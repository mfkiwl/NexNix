/*
    link.ld - contains linker script for RISC-V QEMU virt
    SPDX-License-Identifier: ISC
*/

OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
    . = 0x80000000;

    .text : ALIGN(0x1000)
    {
        *(.text)
    }
    .data : ALIGN(0x1000)
    {
        *(.data)
    }
    .rodata : ALIGN(0x1000)
    {
        *(.rodata*)
    }
    .bss : ALIGN(0x1000)
    {
        *(.bss)
    }

    end = .;
}
