; isombr.asm - contains ISO CDROM master boot record
; SPDX-License-Identifier: ISC

bits 16
cpu 386

org 0x600

section .text
global start

%define ISOMBR_OLDBASE 0x7C00
%define ISOMBR_BASE 0x600
%define ISOMBR_SIZE 2048
%define ISOMBR_WORDS 1024
%define ISOMBR_STACK 0x1A00

%define ISOMBR_NBBASE 0x3C00
%define ISOMBR_NBOLDBASE 0x8400
%define ISOMBR_NBWORDS 0x18000

start:
    ; Set base state
    cld
    cli
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, ISOMBR_STACK
    ; Relocate to 0x600
    mov si, ISOMBR_OLDBASE
    mov di, ISOMBR_BASE
    mov cx, ISOMBR_WORDS
    rep movsw
    ; Far jump to set CS
    jmp 0:isostart

; Prints out a string to the screen
isoprint:
    ; Save AX
    push ax
.printloop:
    ; Grab the next character
    lodsb
    ; Test if this marks the end of the string
    cmp al, 0
    je .printexit
    ; Print it out
    mov ah, 0Eh
    int 10h
    ; Else, go to next character
    jmp .printloop
.printexit:
    ; Restore AX
    pop ax
    ret

; Prints out a message and then halts
isopanic:
    call isoprint
    mov ah, 0
    int 16h                         ; Read keystroke
    jmp 0xFFFF:0                    ; Cold boot computer

    cli
    hlt

; Messages
loadmsg: db "nbisombr: preparing system", 0x0D, 0x0A, 0
exterrmsg: db "nbisombr: LBA BIOS not found", 0x0D, 0x0A, 0
a20errmsg: db "nbisombr: unable to enable A20", 0x0D, 0x0A, 0

; Data
biosdrive: db 0

; Global Descriptor Table
gdtbase:
    dq 0                        ; A null descriptor

    ; 16 bit code
    dw 0xFFFF                   ; Limit
    dw 0                        ; Base low
    db 0                        ; Base high
    db 0x9A                     ; Code segment, execute / read, present
    dw 0                        ; 286 reserved

    ; 32 bit code
    dw 0xFFFF                   ; Limit low
    dw 0                        ; Base low
    db 0                        ; Base middle
    db 0x9A                     ; Code segment, execute / read, present
    db 0xCF                     ; Segment high, 32 bit, 4K granularity
    db 0                        ; Base high

    ; 32 bit data
    dw 0xFFFF                   ; Limit low
    dw 0                        ; Base low
    db 0                        ; Base middle
    db 0x92                     ; Data segment, read / write, present
    db 0xCF                     ; Segment high, 32 bit, 4K granularity
    db 0                        ; Base high

gdtptr:
    dw gdtptr - gdtbase - 1
    dd gdtbase

isostart:
    ; Print prep message
    mov si, loadmsg
    call isoprint

    ; Ensure the BIOS LBA extenstions are present.
    ; In no emulation mode, they should be present, but it doesn't hurt to check
    mov ah, 0x41
    mov bx, 0x55AA
    int 13h
    mov si, exterrmsg
    jc isopanic
    cmp bx, 0xAA55                  ; Are they present?
    jne isopanic

    mov byte [biosdrive], dl        ; Save BIOS drive number

    ; Enable the A20 gate
    cli
    .wait1:
    mov dx, 0x64
    in al, dx
    test al, (1 << 1)
    jnz .wait1

    mov al, 0xAD
    out dx, al
    .wait2:
    in al, dx
    test al, (1 << 1)
    jnz .wait2

    mov al, 0xD0
    out dx, al

    .wait3:
    in al, dx
    test al, (1 << 0)
    jz .wait3

    mov dx, 0x60
    in al, dx
    or al, (1 << 1)             ; Set A20 bit
    mov bl, al

    .wait4:
    mov dx, 0x64
    in al, dx
    test al, (1 << 1)
    jnz .wait4

    mov al, 0xD1
    out dx, al

    .wait5:
    in al, dx
    test al, (1 << 1)
    jnz .wait5

    mov dx, 0x60
    mov al, bl
    out dx, al

    .wait6:
    mov dx, 0x64
    in al, dx
    test al, (1 << 1)
    jnz .wait6

    mov al, 0xAE
    out dx, al

    .wait7:
    in al, dx
    test al, (1 << 1)
    jnz .wait7

    ; Test if A20 gate was enabled
    mov ax, 0xFFFF
    mov es, ax
    mov byte [es:0x610], 0xB0
    cmp byte [0x600], 0xB0
    je noa20

    ; Enter into protected mode
    lgdt [gdtptr]

    ; Set PE bit
    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump to protected mode
    jmp 0x10:isopm

noa20:
    mov si, a20errmsg
    jmp isopanic

bits 32

isopm:
    ; Set stack and segments
    mov ax, 0x18
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, ISOMBR_STACK
    
    ; Relocate rest of bootloader to 0x3C00
    mov esi, ISOMBR_NBOLDBASE
    mov edi, ISOMBR_NBBASE
    mov ecx, ISOMBR_NBWORDS
    rep movsw

    movzx edx, byte [biosdrive]             ; Restore drive number

    jmp 0x10:ISOMBR_NBBASE                  ; To the bootloader we go

times ISOMBR_SIZE - ($ - $$) db 0
