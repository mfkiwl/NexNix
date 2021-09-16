# start.asm - contains startup code for RISC-V 64
# SPDX-License-Identifier: ISC

.global _start

.section .text

_start:
    addi x1, x0, 1
    loop: j loop
