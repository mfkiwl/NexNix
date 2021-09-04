; start.asm - contains startup code for nexboot. 
; Paging is enabled here, and if wanted, 64 bit long mode is entered into
; SPDX-License-Identifier: ISC

bits 32
cpu 386

global nb_entry
extern nb_biosstart

section .text

nb_entry:
    mov ax, 0x18                    ; Set segment registers
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, stacktop               ; Set the stack

    call nb_biosstart               ; Go to C entry point

    cli                             ; Something went wrong if we get here
    hlt

section .data
stack:
    times 8192 db 0
stacktop:
