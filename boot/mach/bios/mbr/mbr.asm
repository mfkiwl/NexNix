; mbr.asm - contains master boot record startup code
; SPDX-License-Identifier: ISC

bits 16
cpu 386

section .text

global start

%define MBR_BIOSSIG 0xAA55
%define MBR_PADMAX 510
%define MBR_SIZE 512
%define MBR_WORDS 256
%define MBR_BASE 600h
%define MBR_BIOSBASE 7C00h
%define MBR_STACKTOP 7C00h
%define MBR_PARTBASE 0x7DBE
%define MBR_PARTSIZE 16
%define MBR_PARTTOP 0x7DFE
%define MBR_ACTIVE (1 << 7)

; Some BIOSes are quricky and expect a BPB, and if one isn't found, then they edit the MBR
; We create a dummy BPB here. The jump also is needed for some Compaq BIOSes anyway
jmp short start
nop
times 87 db 0

start:
    ; Setup state, as who knows what the BIOS handed us
    cld
    cli
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, MBR_STACKTOP
    ; Relocate MBR from 0x7C00 to 0x600
    mov si, MBR_BIOSBASE
    mov di, MBR_BASE
    mov cx, MBR_WORDS
    rep movsw
    ; Far jump to proper entry point, setting CS in the process
    jmp 0:mbrstart

; Various pieces of data
biosdrive: db 0                         ; The drive number the BIOS gave us in DL
loadmsg: db "nbmbr: found active VBR", 0Dh, 0Ah, 0
exterrmsg: db "nbmbr: BIOS does not support LBA", 0
diskerrmsg: db "nbmbr: unable to read sector", 0
nobootmsg: db "nbmbr: cound not find active partition", 0

; Prints out a string to the screen
mbrprint:
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

; Panics
mbrpanic:
    ; Print out the message in SI
    call mbrprint
    ; Read keystroke, then warm boot
    mov ah, 0
    int 16h
    int 19h

; The data address packet
dap: times 16 db 0

; Reads a sector from disk. EAX = LBA of sector, ES:DI = buffer to read to
mbrreadsector:
    mov byte [dap], 10h
    mov word [dap+2], 1
    mov word [dap+4], di
    mov word [dap+6], es
    mov dword [dap+8], eax
    ; Call BIOS
    mov dl, byte [biosdrive]
    mov ah, 42h
    mov si, dap
    int 13h
    ; Check for an error
    mov si, diskerrmsg
    jc mbrpanic
    ret

; The proper entry point
mbrstart:
    ; Reenable interrupts
    sti
    ; Save drive number
    mov byte [biosdrive], dl

    ; Make sure BIOS LBA extentions are available
    mov ah, 41h
    mov bx, 0x55AA
    int 13h
    ; Load error message
    mov si, exterrmsg
    ; Panic on error
    jc mbrpanic
    cmp bx, 0xAA55
    jne mbrpanic                    ; BIOS LBA extentsions are not available

    ; Find an active partition
    mov si, MBR_PARTBASE
    .activeloop:
        test byte [si], MBR_ACTIVE      ; Test active bit
        jne .found                      ; Was it found?
        add si, MBR_PARTSIZE            ; If not, go to next entry
        cmp si, MBR_PARTTOP             ; Check if we have gone too far
        je .notfound                    ; If so, then panic
    jmp .activeloop                     ; Else, continue
.found:                                 
    mov eax, dword [si+8]               ; Load up the LBA start of this volume
    mov di, MBR_BIOSBASE
    call mbrreadsector                  ; Read it in
    cmp word [0x7DFE], MBR_BIOSSIG      ; Check signature
    jne .notfound                       ; If not found, we have an error
    ; Print out leading message
    mov si, loadmsg
    call mbrprint
    mov dl, byte [biosdrive]            ; Restore DL
    jmp MBR_BIOSBASE                    ; Jump to VBR
.notfound:
    mov si, nobootmsg                   ; Panic, as there is no bootable volume
    call mbrpanic
; Pad it out to 510 bytes
times MBR_PADMAX - ($ - $$) db 0
dw MBR_BIOSSIG
