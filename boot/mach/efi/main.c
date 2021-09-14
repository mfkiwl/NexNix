/*
    main.c - contains EFI loader entry point
    SPDX-License-Identifier: ISC
*/

#include <boot/nexboot.h>

EFI_STATUS EFIAPI nb_efistart(EFI_HANDLE img, EFI_SYSTEM_TABLE* systab)
{
    (void)img;
    (void)systab;
    systab->ConOut->OutputString(systab->ConOut, L"got here\r\n");
    return EFI_SUCCESS;
}
