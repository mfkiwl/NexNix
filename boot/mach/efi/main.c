/*
    main.c - contains EFI loader entry point
    SPDX-License-Identifier: ISC
*/

#include <boot/nexboot.h>

EFI_STATUS EFIAPI nb_efistart(EFI_HANDLE img, EFI_SYSTEM_TABLE* systab)
{
    // Initialize EFI global variables
    nb_efiinit(img, systab);

    WCHAR* data = nb_malloc(15 * sizeof(WCHAR));
    for(int i = 0; i < 12; ++i)
    {
        data[i] = 'c';
    }
    data[12] = L'\r';
    data[13] = L'\n';
    data[14] = '\0';
    st->ConOut->OutputString(st->ConOut, data);
    nb_free(data);
    for(;;);
    return EFI_SUCCESS;
}
