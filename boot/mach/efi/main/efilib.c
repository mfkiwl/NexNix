/*
    efilib.c - contains EFI abstraction layer
    SPDX-License-Identifier: ISC
*/

#include <boot/nexboot.h>

// Keyboard protocol
EFI_SIMPLE_TEXT_INPUT_PROTOCOL* keyprot = NULL;
EFI_GUID textguid = EFI_SIMPLE_TEXT_INPUT_PROTOCOL_GUID;

// Initializes EFI data structures
void efi_init(EFI_HANDLE img, EFI_SYSTEM_TABLE* systab)
{
    // Set up the global variables
    gST = systab;
    gBS = systab->BootServices;
    gImageHandle = img;
    // Reset the watchdog timer
    gBS->SetWatchdogTimer(0, 0, 0, NULL);
}

// Allocates memory from the UEFI pool with type EfiLoaderData
void* efi_alloc(UINTN sz)
{
    void* buf = NULL;
    EFI_STATUS status = gBS->AllocatePool(EfiLoaderData, sz, &buf);
    if(EFI_ERROR(status))
        return NULL;
    return buf;
}

// Frees memory back into the UEFI pool
void efi_free(void* buf)
{
    gBS->FreePool(buf);
}

// Allocates memory in pages
UINTN efi_allocpages(UINTN count)
{
    EFI_PHYSICAL_ADDRESS buf = 0;
    EFI_STATUS status = gBS->AllocatePages(AllocateAnyPages, EfiLoaderData, count, 
                                            (EFI_PHYSICAL_ADDRESS*)&buf);
    // If this is a 32 bit system, ensure that the buffer is less then __UINTPTR_MAX__
    if(sizeof(UINTN) == 4 && buf > __UINTPTR_MAX__)
        return 0;
    if(EFI_ERROR(status))
        return 0;
    return (UINTN)buf;
}

// Frees pages of memory
void efi_freepages(UINTN buf, UINTN count)
{
    gBS->FreePages((EFI_PHYSICAL_ADDRESS)buf, count);
}

// Stalls for some time in milliseconds
void efi_stall(UINTN time)
{
    gBS->Stall(time * 1000);
}

// Panics (pre framebuffer)
void efi_panicearly(CHAR16* msg)
{
    // Print out a message prefix
    gST->ConOut->OutputString(gST->ConOut, L"nexboot panic: ");
    // Print out the message, wait for a few seconds, then exit
    gST->ConOut->OutputString(gST->ConOut, msg);
    efi_stall(NEXBOOT_PANICDELAY);
    gBS->Exit(gImageHandle, EFI_NOT_READY, 0, NULL);
}

// Reads a keystroke from the keyboard
void efi_readkey(UINT16* scan, CHAR16* keychar)
{
    // Grab the input protocol if it hasn't been obtained already
    if(!keyprot)
    {
        // Grab the simple text input protocol
        EFI_STATUS status = gBS->LocateProtocol(&textguid, NULL, (VOID**)&keyprot);
        if(EFI_ERROR(status))
            efi_panicearly(L"unable to open text protocol\r\n");
    }
    EFI_INPUT_KEY key;
    UINTN index = 0;
    // Wait for the  key event
    gBS->WaitForEvent(1, &keyprot->WaitForKey, &index);
    keyprot->ReadKeyStroke(keyprot, &key);
    // Only give to the caller what it requested
    if(scan)
        *scan = key.ScanCode;
    if(keychar)
        *keychar = key.UnicodeChar;
}

// Exits out of the OSL
void efi_exit()
{
    gBS->Exit(gImageHandle, EFI_NOT_READY, 0, NULL);
}

// Print something out to EFI default console
void efi_printearly(CHAR16* str)
{
    gST->ConOut->OutputString(gST->ConOut, str);
}
