/*
    disk.c - contains disk managment routines
    Distirbuted with NexNix, licensed under the MIT license
    See LICENSE
*/

#include "neximg.h"

disk_t disk;

// Initializes the disk system
int diskinit()
{
    // Get sector and block sizes
    arg_t* sectszarg = (arg_t*)argget(ARG_SECTORSZ);
    if(sectszarg == NULL)
        disk.sectsz= DISK_DEFSECTSZ;
    else
        disk.sectsz = sectszarg->data;
    
    arg_t* blockszarg = (arg_t*)argget(ARG_BLOCKSZ);
    if(blockszarg == NULL)
        disk.blocksz= DISK_DEFBLOCKSZ;
    else
        disk.blocksz = blockszarg->data;

    // Get the image data
    arg_t* imgarg = argget(ARG_IMG);
    assert(imgarg);
    
    return 0;
}
