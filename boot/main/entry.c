/*
    entry.c - contains entry point for nexboot
    Distributed with NexNix, licensed under the MIT license
    See LICENSE
*/

#include <boot/nexboot.h>

// Main entry point for nexboot (and NexNix for that matter)
EFI_STATUS EFIAPI nb_main(EFI_HANDLE img, EFI_SYSTEM_TABLE* systab)
{
    // Set up UEFI wrapper and EDK2
    efi_init(img, systab);
    CHAR16 key = 0;
    efi_readkey(NULL, &key);
    if(key == L'l')
        gST->ConOut->OutputString(gST->ConOut, L"got here\r\n");
    efi_stall(2000);
    efi_exit();
    for(;;);
    return EFI_NOT_READY;
}
