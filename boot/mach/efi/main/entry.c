/*
    entry.c - contains entry point for nexboot
    SPDX-License-Identifier: ISC
*/

#include <boot/nexboot.h>

// Main entry point for nexboot (and NexNix for that matter)
EFI_STATUS EFIAPI nb_main(EFI_HANDLE img, EFI_SYSTEM_TABLE* systab)
{
    efi_stall(2000);
    // Set up UEFI wrapper and EDK2
    efi_init(img, systab);
    efi_printearly(L"placeholder text\r\n");
    for(;;);
    return EFI_NOT_READY;
}
