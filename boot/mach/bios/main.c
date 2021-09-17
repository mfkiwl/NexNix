/*
    main.c - contains C entry point for nexboot
    SPDX-License-Identifier: ISC
*/

#include <boot/nexboot.h>

void nb_biosstart()
{
    uint8_t* addr = (uint8_t*)0xB8000;
    addr[0] = 'N';
    addr[1] = 7;
    for(;;) asm("hlt");
}
