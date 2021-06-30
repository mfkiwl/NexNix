/*
    mbr.s - contains MBR startup code
    Distributed with NexNix, licensed under the MIT license
    See LICENSE
*/

// We are 16 bit
.code16

// Constants
.set SEGBASE, 0
.set STACKTOP, 0x7C00           // Our stack is right beneath stage 2
.set MBRBASE, 0x600             // We must relocate here
.set MBRLDBASE, 0x7C00          // The BIOS loads us here
.set MBRWORDCOPY, 0x100         // The number of words to copy when relocated

// Basic definitions
.section .text
.global _start
mbrstart:
xchg %bx, %bx
// Skip over fake BPB with near jump followed by a NOP
jmp _start
nop
// Some weird BIOSes require a BPB. They may modify the bootsector if you don't have some dummy space for it
// See https://forum.osdev.org/viewtopic.php?f=1&t=44457
bpbstart:
. = bpbstart + 60;
bpbend:

_start:
    // The BIOS loads us here. We have no clue what state the machine is in.
    // This means we must set up the state first
    cli                         // Disable interrupts
    cld                         // Make sure DF points upwards
    mov $SEGBASE, %ax           // Begin setting the segments
    mov %ax, %ds
    mov %ax, %es
    mov %ax, %fs
    mov %ax, %gs
    mov %ax, %ss
    mov $STACKTOP, %sp          // Set the stack
    push %dx                    // Save the BIOS drive number

    // Now we must relocate the MBR to 0:7C00
    mov $MBRWORDCOPY, %cx       // Load everything
    mov $MBRLDBASE, %si
    mov $MBRBASE, %di           // We are copying to 0x600
    rep movsw
    jmp $0x0,$mbrmain           // Go to main MBR code, flushing CS as well in case the bios loaded us to 7C0:0

mbrmain:
    cli
    hlt
. = mbrstart + 510;             // Pad out the remainder of our boot sector
    .word 0xAA55                // Many BIOSes need this
