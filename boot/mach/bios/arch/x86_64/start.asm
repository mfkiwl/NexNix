; start.asm - contains startup code for nexboot
; SPDX-License-Identifier: ISC

bits 32

global nb_entry
extern nb_biosstart

%define VGA_TEXTBASE 0xB8000
%define CPUID_EXTFEAT 0x80000001

%define CPU_DATA32 0x18
%define CPU_CPUIDLM (1 << 29)
%define CPU_PGRW 3
%define CPU_PAE (1 << 5)
%define CPU_LME (1 << 8)
%define CPU_PG (1 << 31)
%define CPU_EFER 0xC0000080
%define CPU_CODE64 0x18
%define CPU_DATA64 0x20

nb_entry:
    mov ax, CPU_DATA32              ; Set segment registers
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, stacktop               ; Set the stack

    ; We now must enter into long mode now, first checking if it is available
    mov eax, CPUID_EXTFEAT
    cpuid
    test edx, CPU_CPUIDLM           ; Test long mode bit
    jz .nolm                        ; If not set, panic

    ; Set attributes of PML4 and PDPT
    or dword [pml4base], CPU_PGRW
    or dword [pdptbase], CPU_PGRW

    ; Load up the GDT
    lgdt [gdtptr]

    ; Load up the PML4
    mov eax, pml4base
    mov cr3, eax

    ; Set PAE bit
    mov eax, cr4
    or eax, CPU_PAE
    mov cr4, eax

    ; Set LME bit in EFER
    mov ecx, CPU_EFER
    rdmsr
    or eax, (1 << 8)
    wrmsr

    ; Enable paging
    mov eax, cr0
    or eax, CPU_PG
    mov cr0, eax

    ; Jump to long mode
    jmp CPU_CODE64:lmstart

.nolm:
    mov si, longmodemsg
    call nb_printearly              ; Panic if long mode isn't available
    cli
    hlt

; Prints a message on screen. Message is in SI
nb_printearly:
    push eax                    ; Save clobbered registers
    push ebx
    mov ebx, VGA_TEXTBASE       ; Store marker
.start:
    lodsb                       ; Grab current character
    mov byte [ebx], al          ; Write character
    mov byte [ebx + 1], 7       ; Write attributes
    add ebx, 2                  ; Move to next cell
    cmp al, 0                   ; Is this the end?
    je .end                     ; Go to end if so
    jmp .start
.end:
    pop ebx
    pop eax
    ret

section .data

gdtbase:
    ; Null descriptor
    dq 0

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
    db 0xCF                     ; Segment limit high, 32 bit, 4K granularity
    db 0                        ; Base high

    ; 64 bit code
    dw 0xFFFF
    dw 0
    db 0
    db 0x9A                     ; Code segment, execute / read, present
    db 0xAF                     ; Segment limit high, 64 bit, 4K granularity
    db 0                        ; Base high

    ; 64 bit data
    dw 0xFFFF
    dw 0
    db 0
    db 0x92                     ; Code segment, execute / read, present
    db 0xAF                     ; Segment limit high, 64 bit, 4K granularity
    db 0                        ; Base high

gdtptr:
    dw gdtptr - gdtbase - 1
    dq gdtbase

align 4096
; The PML4
pml4base:
    dq pdptbase
times 511 dq 0

; The PDPT
pdptbase:
    dq pdbase
times 511 dq 0

; Page directory
pdbase:
    dq 0x83
    dq 0x83 | 0x200000
    dq 0x83 | 0x400000
    dq 0x83 | 0x600000
times 508 dq 0

; Printed if long mode isn't available
longmodemsg: db "nexboot: please run the i386 image", 0

stack:
    times 8192 db 0
stacktop:

section .text

bits 64

lmstart:
    ; Set data segments
    mov ax, CPU_DATA64
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov rsp, stacktop               ; Extend stack to 64 bits

    call nb_biosstart               ; Go to C entry point

    cli                             ; Something went wrong if we get here
    hlt
