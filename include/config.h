/*
    config.h - select the right configuration header based off of target arch
    SPDX-License-Identifier: ISC
*/

#ifndef _CONFIG_H
#define _CONFIG_H

#if GLOBAL_ARCH == i386-pc
#include <config-i386-pc.h>
#endif

#endif
