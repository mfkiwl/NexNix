; vbr.asm - contains NexNix volume boot record
; SPDX-License-Identifier: ISC

bits 16
cpu 386

section .text

global start

%define VBR_BIOSSIG 0xAA55
%define VBR_SIZE 1024
%define VBR_PADMAX 510
%define VBR_OLDBASE 0x7C00
%define VBR_BASE 0x600
%define VBR2_BASE 0x800
%define VBR_WORDS 256
%define VBR_STACKTOP 0x1A00
%define BDA_USABLEMEM 0x413
%define VBR_MINADDR 0x1A00
%define NB_BASE 0x3C00

; BPB definition
jmp short start                     ; Required by some utilities and BIOSes to be 3 bytes
nop

bsoem: db "UNUSED  "                ; Filled by formatting utility
bpbsectsz: dw 0                     ; Everything here is filled by formatting utility
bpbsecperclus: db 0
bpbresvdsect: dw 0
bpbnumfats: db 0
bpbrootentcnt: dw 0
bpbtotsect16: dw 0
bpbmedia: db 0
bpbfatsz16: dw 0
bpbsecpertrk: dw 0
bpbnumheads: dw 0
bpbhiddensect: dd 0
bpbtotsect32: dd 0
bpbfatsz32: dd 0
bpbextflags: dw 0
bpbfsver: dw 0
bpbrootclus: dd 0
bpbfsinfo: dw 0
bpbbkbootsect: dw 0
bpbpartbase: dd 0                       ; Ok, I know this is really hacky, but FAT isn't going
                                        ; to change anytime soon, so I think this is fine
bpbresvd: times 8 db 0
bsdrvnum: db 0
bsresvd1: db 0
bsbootsig: db 0
bsvolid: dd 0
bsvollab: db "NO NAME    "
bsfstype: db "FAT32   "

start:
    ; Setup required state
    cld
    cli
    mov ax, 0
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, VBR_STACKTOP
    ; Relocate to 0x600
    mov si, VBR_OLDBASE
    mov di, VBR_BASE
    mov cx, VBR_WORDS
    rep movsw
    jmp 0:vbrstart                  ; Far jump to VBR main entry point

; Strings and variables and stuff
loadmsg: db "nbvbr: loading nexboot", 0
exterrmsg: db 0xd, 0xa, "nbvbr: BIOS does not support LBA", 0
memerrmsg: db 0xd, 0xa, "nbvbr: out of memory", 0
diskerrmsg: db 0xd, 0xa, "nbvbr: unable to read file", 0
notfoundmsg: db 0xd, 0xa, "nbvbr: nexboot not found", 0
progmark: db '.', 0
filename: db "NEXBOOT    "

memmax: dd 0
memcur: dd VBR_MINADDR

; Prints out a string to the screen
vbrprint:
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
vbrpanic:
    ; Print out the message in SI
    call vbrprint
    ; Read keystroke, then warm boot
    mov ah, 0
    int 16h
    int 19h

; Allocate the amount of bytes of memory in EAX. Returns a buffer in ES:DI
vbralloc:
    push ecx
    push ebx
    mov ecx, dword [memcur]                     ; Save the current buffer
    ; Put high 16 bits of ECX elsewhere
    mov ebx, ecx
    xor bx, bx                                  ; Clear the low bits
    shr ebx, 4                                  ; Pack 'em in BX
    mov es, bx                                  ; Set ES
    mov di, cx                                  ; Set DI
    add ecx, eax                                ; For next allocation
    cmp ecx, dword [memmax]                     ; Check if we are out of memory
    jae .nomem
    mov dword [memcur], ecx
    pop ebx
    pop ecx
    ret
.nomem:
    ; Panic
    mov si, memerrmsg
    call vbrpanic

; The data address packet
dap: times 16 db 0

; Reads a sector from disk. EAX = LBA of sector, CX = number of sectors to read,
; ES:DI = buffer to read to
vbrreadsector:
    mov byte [dap], 10h
    mov word [dap+2], cx
    mov word [dap+4], di
    mov word [dap+6], es
    mov dword [dap+8], eax
    ; Call BIOS
    mov dl, byte [bsdrvnum]
    mov ah, 42h
    mov si, dap
    int 13h
    ; Check for an error
    mov si, diskerrmsg
    jc vbrpanic
    ret

; Main VBR function
vbrstart:
    sti
    ; Save drive number
    mov byte [bsdrvnum], dl

    ; First, print out welcome message
    mov si, loadmsg
    call vbrprint

    ; Check if an LBA BIOS is installed. If so, we are definitley on a 386 or better
    mov ah, 41h
    mov bx, 0x55AA
    int 13h
    mov si, exterrmsg
    jc vbrpanic
    cmp bx, 0xAA55
    jne vbrpanic 
    
    ; Read in the second sector of the VBR
    mov eax, dword [bpbpartbase]
    add eax, 1
    mov cx, 1
    mov di, VBR2_BASE
    call vbrreadsector
    ; Jump to it
    jmp vbr2start

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

clussz: dd 0
fatsz: dd 0
fataddr: dw 0

times VBR_PADMAX -  ($ - $$) db 0
dw VBR_BIOSSIG

; Reads in one cluster from disk. EAX = cluster address, ES:DI = buffer to read to
vbrreadcluster:
    ; Convert to an absolute sector, then read it in
    push ecx
    push ebx
    push eax
    sub eax, 2
    movzx ecx, byte [bpbsecperclus]
    mul ecx
    movzx ecx, word [bpbresvdsect]
    add eax, ecx
    mov ecx, dword [bpbpartbase]
    add eax, ecx
    mov ebx, eax
    mov eax, dword [bpbfatsz32]
    movzx ecx, byte [bpbnumfats]
    mul ecx
    add ebx, eax
    mov eax, ebx
    movzx cx, byte [bpbsecperclus]
    call vbrreadsector
    pop eax
    pop ebx
    pop ecx
    ret

vbr2start:
    ; Get highest usable address
    mov ax, word [BDA_USABLEMEM]
    mov cx, 1024                    ; Convert to bytes. 1024 bytes = 1KiB
    mul cx
    shl edx, 16                     ; Get DX:AX to one register
    or eax, edx
    mov dword [memmax], eax         ; Setup memory info

    ; Allocate FAT data
    movzx eax, word [bpbsectsz]
    call vbralloc
    mov word [fataddr], di

    ; Store cluster size in bytes
    movzx eax, word [bpbsectsz]
    movzx cx, byte [bpbsecperclus]
    mul cx

    shl edx, 16                     ; Get everything in EAX
    or eax, edx
    mov dword [clussz], eax

    ; Allocate memory for one cluster of root directory entries
    call vbralloc

    ; Now, we must read in the root directory start cluster
    mov eax, dword [bpbrootclus]
    call vbrreadcluster

    ; Find the number of directory entries in one cluster
    xor edx, edx
    mov eax, dword [clussz]
    mov ecx, 32
    div cx

    ; Find the file's directory entry
    mov cx, ax
    .nameloop:
        push cx
        push di
        mov cx, 11
        mov si, filename
        rep cmpsb
        pop di
        pop cx
        je .filefound
        add di, 32
    loop .nameloop
    ; File doesn't exists, panic
    mov si, notfoundmsg
    call vbrpanic
.filefound:
    ; We found it, obtain the first cluster
    movzx eax, word [di + 26]
    mov dx, word [di + 20]
    shl edx, 16
    or eax, edx

    ; Make sure we are at the required base allocation address
    mov dword [memcur], NB_BASE

    ; Now, here is the hard part. We must go through the cluster chain, 
    ; and load every cluster there. This code performs poorly. It would be better if the current
    ; FAT sector was cached instead of re-reading it every time.
    ; TODO - optimize to cache current FAT sector

.fatloop:
    ; Allocate memory for current cluster
    mov ebx, eax
    mov eax, dword [clussz]
    call vbralloc
    mov eax, ebx

    ; Read it in
    call vbrreadcluster

    ; Print out progress
    push eax
    mov si, progmark
    call vbrprint
    pop eax

    ; Now we need to figure out the next cluster. First, compute the offset of this FAT entry
    mov cx, 4
    mul cx

    ; EAX = FAT offset now. Convert to an absolute sector now
    xor edx, edx
    movzx ecx, word [bpbsectsz]
    div ecx
    push edx
    movzx ebx, word [bpbresvdsect]
    add eax, ebx
    mov ebx, dword [bpbpartbase]
    add eax, ebx
    
    ; Read it in
    mov cx, 1
    mov di, word [fataddr]
    call vbrreadsector

    ; Get next cluster, masking off the top 4 bits
    pop edx
    add edi, edx
    mov eax, dword [es:di]
    and eax, 0x0FFFFFFF

    ; Check for end of file
    cmp eax, 0x0FFFFFF8
    jae .launch                     ; We are done!
    ; Else, read next cluster
    jmp .fatloop

.launch:
    cli

    ; Before launching, let's enable the A20 gate
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

    mov eax, cr0
    or eax, 1
    mov cr0, eax

    ; Far jump to nexboot main part
    jmp 0x10:NB_BASE

a20errmsg: db 0x0D, 0x0A, "nbvbr: couldn't enable A20", 0

noa20:
    mov si, a20errmsg
    jmp vbrpanic

times VBR_SIZE - ($ - $$) db 0
