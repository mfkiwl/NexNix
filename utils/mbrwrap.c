/*
    mbrwrap.c - wraps ESP in MBR partition
    SPDX-License-Identifier: ISC
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <libgen.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

char* progname = NULL;

// MBR structures
typedef struct _mbrpart
{
    uint8_t flags;              // 0x80 = active
    uint8_t chsstart[3];        // Unused
    uint8_t type;               // Partition type
    uint8_t chsend[3];          // Unused
    uint32_t lbastart;          // LBA start address
    uint32_t lbasize;           // LBA end address
}__attribute__((packed)) mbrpart_t;

typedef struct _mbr
{
    uint8_t code[446];
    mbrpart_t parts[4];
    uint16_t sig;
}__attribute__((packed)) mbr_t;

#define SECTSZ 512

int main(int argc, char** argv)
{
    progname = basename(argv[0]);
    // Grab the arguments
    if(argc <= 3)
    {
        printf("%s: not enough arguments passed\n", progname);
        return 1;
    }

    char* img = argv[1];
    if(!img)
    {
        printf("%s: invalid image passed\n", progname);
        return 1;
    }
    long base = strtol(argv[2], NULL, 10);
    if(!base)
    {
        printf("%s: base must be an integer\n", progname);
        return 1;
    }
    // Grab the size
    long size = strtol(argv[3], NULL, 10);
    if(!size)
    {
        printf("%s: size must be an integer\n", progname);
        return 1;
    }
    // Now we must open up the image file
    int imgfd = open(img, O_RDWR);
    if(imgfd == -1)
    {
        printf("%s: %s: %s\n", progname, img, strerror(errno));
        return 1;
    }
    // Read in the MBR
    mbr_t mbr;
    read(imgfd, &mbr, sizeof(mbr_t));
    memset(&mbr.parts[1].chsstart, 0xFF, 3);            // Set default CHS values
    memset(&mbr.parts[1].chsend, 0xFF, 3);
    mbr.parts[1].flags = 0x80;
    mbr.parts[1].type = 0x0C;                           // Win95 LBA type
    mbr.parts[1].lbastart = ((base * 1048576) / 512);   // Set base (in sectors)
    mbr.parts[1].lbasize = ((size * 1048576) / 512);    // Set LBA end
    // Write it out
    lseek(imgfd, 0, SEEK_SET);
    write(imgfd, &mbr, sizeof(mbr_t));
    close(imgfd);
    return 0;
}
