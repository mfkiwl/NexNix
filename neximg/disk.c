/*
    disk.c - contains disk managment routines
    Distirbuted with NexNix, licensed under the MIT license
    See LICENSE
*/

#include "neximg.h"

disk_t disk;

// Uses DD to write out the disk image
int diskcreate()
{
    // Prepare arguments
    char* argv[6] = { "dd", "if=/dev/zero", "", "bs=512", "", NULL };
    // Set the destination image now
    char* imgfile = (char*)argget(ARG_IMG)->data;
    // Allocate the string
    char* fullstr = (char*)malloc(strlen(imgfile) + 3);
    if(fullstr == NULL)
    {
        printf("%s: out of memory\n", getprogname());
        _exit(1);
    }
    // Copy over the "of=" part
    strcpy(fullstr, "of=");
    // Concatenate the image file name
    strcat(fullstr, imgfile);
    argv[2] = fullstr;
    // Now do the same to the "count=" part. First we must convert the number to a string
    int len = snprintf(NULL, 0, "%d", disk.sectcount);
    fullstr = (char*)malloc(len + 7);
    if(fullstr == NULL)
    {
        printf("%s: out of memory\n", getprogname());
        _exit(1);
    }
    // Copy over "count="
    strcpy(fullstr, "count=");
    // Concatenate the number
    sprintf(fullstr + 6, "%d", disk.sectcount);
    argv[4] = fullstr;
    // Now we must execute DD
    pid_t pid = fork();
    if(pid == 0)
    {
        // Prepare stdout and stderr
        int fd = open("/dev/null", O_RDWR);
        if(fd == -1)
        {
            // Exit with an error
            _exit(1);
        }
        // Redirect stdout and stderr to here
        dup2(fd, STDOUT_FILENO);
        dup2(fd, STDERR_FILENO);
        // Execute DD
        if(execvp("dd", argv) == -1)
        {
            _exit(1);
        }
    }
    else
    {
        int stat = 0;
        waitpid(pid, &stat, 0);
        if(stat != 0)
        {
            printf("%s: DD invocation failed\n", getprogname());
            free((void*)argv[2]);
            free((void*)argv[4]);
            return -1;
        }
    }
    free((void*)argv[2]);
    free((void*)argv[4]);
    return 0;
}

// Initializes the disk system
int diskinit()
{
    memset(&disk, 0, sizeof(disk_t));
    // Get sector and block sizes
    arg_t* sectszarg = (arg_t*)argget(ARG_SECTORSZ);
    if(sectszarg == NULL)
        disk.sectsz = DISK_DEFSECTSZ;
    else
        disk.sectsz = sectszarg->data;
    
    arg_t* blockszarg = (arg_t*)argget(ARG_BLOCKSZ);
    if(blockszarg == NULL)
        disk.blocksz= DISK_DEFBLOCKSZ;
    else
        disk.blocksz = blockszarg->data;

    // Get the count argument
    disk.sectcount = (int)argget(ARG_IMGSZ)->data;
    // Now we must invoke DD to create the disk image. Lets do that next
    if(diskcreate())
        return -1;
    // Open up the disk image
    disk.fd = open((const char*)argget(ARG_IMG)->data, O_RDWR);
    if(disk.fd == -1)
    {
        printf("%s: couldn't open disk image", getprogname());
        return -1;
    }
    // Now we are done
    return 0;
}

// Releases the disk
void diskrelease()
{
    // Close it
    close(disk.fd);
}

// Reads a sector in
int diskread(int sector, void* buf, uint8_t count)
{
    // Get the absolute offset and seek to it
    int offset = sector * disk.sectsz;
    lseek(disk.fd, offset, SEEK_SET);
    // Read it in
    if(read(disk.fd, buf, count * disk.sectsz) == -1)
        return -1;
    return 0;
}

// Writes out a sector
int diskwrite(int sector, void* buf, uint8_t count)
{
    // Get the offset into the file
    off_t offset = sector * disk.sectsz;
    lseek(disk.fd, offset, SEEK_SET);
    // Write it out
    if(write(disk.fd, buf, count * disk.sectsz) == -1)
        return -1;
    return 0;
}

// Returns the disk data
disk_t* diskget()
{
    return &disk;
}
