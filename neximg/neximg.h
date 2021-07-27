/*
    neximg.h - contains neximg header info
    Distributed with NexNix, licensed under the MIT license
    See LICENSE
*/

#ifndef _NEXIMG_H
#define _NEXIMG_H

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <libgen.h>
#include <assert.h>
#include <dirent.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <locale.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>

// Argument information
#define ARG_IMG 1
#define ARG_IMGSZ  7
#define ARG_DSKFMT 2
#define ARG_PARTS 8
#define ARG_BLOCKSZ 6
#define ARG_SECTORSZ 5
#define ARG_DIR 4
#define ARG_FORMAT 3

typedef struct _arg
{
    int type;                   // Contains the type of this argument
    uintptr_t data;             // Data about this argument
}arg_t;

// getopt string
#define ARG_GETOPTSTR "i:t:p:d:fhs:b:c:"

// Disk types
#define DTYP_GPT 0
#define DTYP_MBR 1
#define DTYP_ISO9660 2

// File systems
#define FS_FAT32 1
#define FS_EXT2 2
#define FS_FAT16 3

// Partition entry argument format
typedef struct _part
{
    uint8_t fstype;             // The FS string
    uint32_t size;              // The size, in sectors
    uint8_t isboot;             // Specifies if this is the bootable partition
}part_t;

// Functions

// Grabs an argument
arg_t* argget(int argid);

// Gets the program name
char* getprogname();

// Gets the number of partitions
int getnumparts();

// Disk stuff
#define DISK_DEFSECTSZ 512
#define DISK_DEFBLOCKSZ 1024

typedef struct _disk
{
    int sectsz;                 // The size of a sector
    int blocksz;                // The size of a block
    int fd;                     // File descriptor for the image
    int sectcount;              // The number of sectors in this disk
}disk_t;

// Disk functions

// Sets up the disk
int diskinit();

// Releases the disk
void diskrelease();

// Reads a sector in
int diskread(int sector, void* buf, uint8_t count);

// Writes out a sector
int diskwrite(int sector, void* buf, uint8_t count);

// Returns the disk data
disk_t* diskget();

// Partition functions

// Creates the partition table
int partcreate();

// Frees partition table data
void partfree();

// The partition table data structure
typedef struct _parts
{
    part_t** parts;             // The array of partitions
    int countpart;              // The number of partitions
    int table;                  // The partition table type
}parts_t;

// Creates a MBR partition table
int mbrcreate(parts_t* parts);

#endif
