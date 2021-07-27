/*
    part.c - contains partition table independent wrapper for part operations
    Distributed with NexNix, licensed under the MIT license
    See LICENSE
*/

#include "neximg.h"

parts_t parts;                  // The data structure of this module

// Creates the partition table
int partcreate()
{
    memset(&parts, 0, sizeof(parts_t));
    // Intialize the partition table type
    parts.table = (int)argget(ARG_DSKFMT)->data;
    // Allocate the table
    parts.parts = (part_t**)malloc(sizeof(part_t*) * getnumparts());
    parts.countpart = getnumparts();
    // Add all partitions to the table
    for(int i = 0; i < getnumparts(); ++i)
        parts.parts[i] = (part_t*)argget(ARG_PARTS + i)->data;

    // Now figure out what kind of table to use
    if(parts.table == DTYP_MBR)
    {
        if(mbrcreate(&parts))
            return -1;
    }
    return 0;
}

// Frees partition table data
void partfree()
{
    free(parts.parts);
}
