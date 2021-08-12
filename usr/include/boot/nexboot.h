/*
    nexboot.h - contains bootloader definitions
    Distributed with NexNix, licensed under the MIT license
    See LICENSE
*/

#ifndef _NEXBOOT_H
#define _NEXBOOT_H

#include <version.h>

#include <Uefi.h>
#include <Library/UefiLib.h>
#include <Library/UefiBootServicesTableLib.h>

// UEFI wrapper functionss

// Initializes the EFI data structures
void efi_init(EFI_HANDLE img, EFI_SYSTEM_TABLE* systab);

// Allocates memory from the UEFI pool with type EfiLoaderData
void* efi_alloc(UINTN sz);

// Frees memory back into the UEFI pool
void efi_free(void* buf);

// Allocates memory in pages
UINTN efi_allocpages(UINTN count);

// Frees pages of memory
void efi_freepages(UINTN buf, UINTN count);

// Reads a keystroke from the keyboard
void efi_readkey(UINT16* scan, CHAR16* keychar);

// Stalls for some time in milliseconds
void efi_stall(UINTN time);

#define NB_PANICDELAY 3000

// Panics (pre framebuffer)
void efi_panicearly(CHAR16* msg);

// Exits out of the OSL
void efi_exit();

#endif
