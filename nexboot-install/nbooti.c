/*
    nbooti.c - contains nexboot-install app
    Distributed with NexNix, licensed under the MIT license
    See LICENSE
*/

// Includes
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>

// Global variables
int sector = 0;
char* image = NULL;
char* mbr = NULL;
int imgfd = 0;
int mbrfd = 0;

// Prints out help
void help(char* name)
{
    printf("Usage: %s -i IMAGE -m MBRPATH [-s SECTOR -h]\n", name);
    exit(0);
}

int main(int argc, char** argv)
{
    // Grab the arguments
    char ch = 0;
    while((ch = getopt(argc, argv, "i:m:s:h")) != -1)
    {
        // Parse the argument
        if(ch == 'i')
        {
            // Grab optarg and copy it
            image = (char*)malloc(strlen(optarg));
            strcpy(image, optarg);
        }
        else if(ch == 'm')
        {
            // Grab optarg and copy it
            mbr = (char*)malloc(strlen(optarg));
            strcpy(mbr, optarg);
        }
        else if (ch == 's')
        {
            // Convert optarg to number
            sector = atoi(optarg);
        }
        else if(ch == 'h')
        {
            // Print out help
            help(argv[0]);
        }
        else
        {
            // Print an error message, then help
            help(argv[0]);
        }
    }
    // Check that required arguments were passed
    if(!image || !image)
    {
        printf("%s: Required argument not passed\n", argv[0]);
        return 0;
    }
    // Open everything
    imgfd = open(image, O_WRONLY);
    mbrfd = open(mbr, O_RDONLY);

    if(!imgfd || !mbrfd)
    {
        printf("%s: Error opening a file\n", argv[0]);
        return 0;
    }

    // Write out the MBR to sector 0
    uint8_t mbrbuf[512];
    read(mbrfd, mbrbuf, 512);
    write(imgfd, mbrbuf, 512);

    // Now close it
    close(imgfd);
    close(mbrfd);
    return 0;
}
