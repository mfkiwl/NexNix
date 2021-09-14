/*
    main.c - contains C entry point for nexboot
    SPDX-License-Identifier: ISC
*/

#include <boot/nexboot.h>

void nb_biosstart()
{
    for(;;) asm("hlt");
}
