/*
    mbrwrite.c - writes out the MBR to a disk image
    Copyright 2021 Jedidiah Thompson

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
*/

#include <stdio.h>
#include <stdint.h>
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
    if(argc < 3)
    {
        printf("%s: not enough arguments passed\n", progname);
        return 1;
    }
    // Open up the MBR
    int mbrfd = open(argv[1], O_RDONLY);
    if(!mbrfd)
    {
        printf("%s: %s: %s\n", progname, argv[1], strerror(errno));
        return 1;
    }
    // Open up the disk image
    int imgfd = open(argv[2], O_RDWR);
    if(!imgfd)
    {
        printf("%s: %s: %s\n", progname, argv[2], strerror(errno));
        return 1;
    }
    // Read in the MBR file
    uint8_t mbrbuf[446];
    read(mbrfd, mbrbuf, 446);
    close(mbrfd);
    // Write it out
    write(imgfd, mbrbuf, 446);
    close(imgfd);
    return 0;
}
