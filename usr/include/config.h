/*
    config.h - select the right configuration header based off of target arch
    SPDX-License-Identifier: ISC
*/

#ifndef _CONFIG_H
#define _CONFIG_H

#if GLOBAL_ARCH == i386-pc
#include <config-i386-pc.h>
#elif GLOBAL_ARCH == x86_64-pc
#include <config-x86_64-pc.h>
#elif GLOBAL_ARCH == aarch64-sr
#include <config-aarch64-sr.h>
#endif

#endif
