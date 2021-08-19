/*
    entry.c - contains entry point for nexboot
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

#include <boot/nexboot.h>

// Main entry point for nexboot (and NexNix for that matter)
EFI_STATUS EFIAPI nb_main(EFI_HANDLE img, EFI_SYSTEM_TABLE* systab)
{
    // Set up UEFI wrapper and EDK2
    efi_init(img, systab);
    efi_printearly(L"nexboot: starting up\r\n");
    for(;;);
    return EFI_NOT_READY;
}
