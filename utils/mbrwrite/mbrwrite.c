/*
    mbrwrite.c - writes out the MBR to a disk image
    SPDX-License-Identifier: ISC
*/

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <libgen.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>

char* progname = NULL;

#define SECTSZ 512

int main(int argc, char** argv)
{
    progname = basename(argv[0]);
    // Check arguments
    if(argc < 5)
    {
        printf("%s: not enough arguments passed\n", progname);
        return 1;
    }
    // Grab the VBR sector start
    int vbrstart = atoi(argv[4]);
    if(!vbrstart)
    {
        printf("%s: sector start must be a number\n", progname);
        return 1;
    }
    // Open up the MBR
    int mbrfd = open(argv[1], O_RDONLY);
    if(!mbrfd)
    {
        printf("%s: %s: %s\n", progname, argv[1], strerror(errno));
        return 1;
    }
    // Open up the VBR
    int vbrfd = open(argv[3], O_RDONLY);
    if(!vbrfd)
    {
        printf("%s: %s: %s\n", progname, argv[3], strerror(errno));
        close(vbrfd);
        return 1;
    }
    // Open up the disk image
    int imgfd = open(argv[2], O_RDWR);
    if(!imgfd)
    {
        printf("%s: %s: %s\n", progname, argv[2], strerror(errno));
        close(mbrfd);
        close(vbrfd);
        return 1;
    }
    uint8_t buf[1024];

    read(mbrfd, buf, 446);
    close(mbrfd);
    write(imgfd, buf, 446);
    
    read(vbrfd, buf, 1024);
    lseek(imgfd, vbrstart * 512, SEEK_SET);
    read(imgfd, buf, 90);

    uint32_t* partbase = (uint32_t*)&buf[52];
    *partbase = vbrstart;

    lseek(imgfd, vbrstart * 512, SEEK_SET);
    write(imgfd, buf, 1024);

    close(vbrfd);
    close(imgfd);
    return 0;
}
