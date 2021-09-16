/*
    nbefi.h - contains UEFI stuff
    SPDX-License-Identifier: ISC
*/

#ifndef _NBEFI_H
#define _NBEFI_H

#include <efi.h>

// Initializes UEFI wrapper;
void nb_efiinit(EFI_HANDLE img, EFI_SYSTEM_TABLE* systab);

// EFI table pointers
extern EFI_SYSTEM_TABLE* st;
extern EFI_BOOT_SERVICES* bs;
extern EFI_RUNTIME_SERVICES* rt;
extern EFI_HANDLE imghandle;

#endif
