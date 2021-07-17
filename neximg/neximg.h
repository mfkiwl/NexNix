/*
    neximg.h - contains neximg header info
    Distributed with NexNix, licensed under the MIT license
    See LICENSE
*/

#ifndef _NEXIMG_H
#define _NEXIMG_H

// Argument information
#define ARG_IMG 0
#define ARG_DSKFMT 1
#define ARG_PARTS 2
#define ARG_DIR 3
#define ARG_FORMAT 4

// Arg function
arg_t* getarg(int type);

typedef struct _arg
{
    int type;
}arg_t;

#endif
