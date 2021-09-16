/*
    nbbase.h - contains base nexboot bootloader functions
    SPDX-License-Identifier: ISC
*/

#ifndef _NBBASE_H
#define _NBBASE_H

// Allocates arbitrary amounts of memory
void* nb_malloc(uint32_t sz);

// Frees arbitrary amounts of memory
void nb_free(void* buf);

#endif
