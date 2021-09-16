/*
    efilib.c - wraps over various EFI services
    SPDX-License-Identifier: ISC
*/

#include <boot/nexboot.h>

EFI_SYSTEM_TABLE* st = NULL;
EFI_BOOT_SERVICES* bs = NULL;
EFI_RUNTIME_SERVICES* rt = NULL;
EFI_HANDLE imghandle = NULL;

// Initializes UEFI wrapper
void nb_efiinit(EFI_HANDLE img, EFI_SYSTEM_TABLE* systab)
{
    imghandle = img;
    st = systab;
    bs = systab->BootServices;
    rt = systab->RuntimeServices;
}

// Allocates arbitrary amounts of memory
void* nb_malloc(uint32_t sz)
{
    void* buf = NULL;
    if(EFI_ERROR(bs->AllocatePool(EfiLoaderData, sz, &buf)))
        return NULL;
    return buf;
}

// Frees arbitrary amounts of memory
void nb_free(void* buf)
{
    bs->FreePool(buf);
}
