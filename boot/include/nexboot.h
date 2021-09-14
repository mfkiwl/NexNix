/*
    nexboot.h - contains bootloader definitions
    SPDX-License-Identifier: ISC
*/

#ifndef _NEXBOOT_H
#define _NEXBOOT_H

// Version info
#include <ver.h>

// Only include UEFI stuff if needed
#if NEXBOOT_EFI == 1
#include <boot/nbefi.h>
#endif

// Build configuration
#include <config.h>

// Freestanding headers
#include <stdint.h>
#include <stddef.h>

#endif
