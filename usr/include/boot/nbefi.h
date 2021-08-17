/*
    nbefi.h - contains UEFI stuff
    Copyright 2021 Jedidiah Thompson

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

#ifndef _NBEFI_H
#define _NBEFI_H

#include <Uefi.h>
#include <Library/UefiLib.h>
#include <Library/UefiBootServicesTableLib.h>
#include <Protocol/EdidActive.h>

// Some library functions

// UEFI wrapper functions

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

// Panics (pre framebuffer)
void efi_panicearly(CHAR16* msg);

// Print something out to EFI default console
void efi_printearly(CHAR16* str);

// Exits out of the OSL
void efi_exit();

#endif
