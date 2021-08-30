; isombr.asm - contains ISO CDROM master boot record
; SPDX-License-Identifier: ISC

bits 16
cpu 386

section .text
global start

start:
    mov al, 'c'
    mov ah, 0Eh
    int 10h
    cli
    hlt
