/*
    entry.c - contains entry point for nexboot
    Distributed with NexNix, licensed under the MIT license
    See LICENSE
*/

#include <Uefi.h>
#include <Library/UefiLib.h>

// Main entry point for nexboot (and NexNix for that matter)
EFI_STATUS EFIAPI nb_main(EFI_HANDLE handle, EFI_SYSTEM_TABLE* systab)
{
    Print(L"Hello, world\n");
    return EFI_SUCCESS;
}
