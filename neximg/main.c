/*
    main.c - contains main code for neximg
    Distributed with NexNix, licensed under the MIT license
    See LICENSE
*/

#include "neximg.h"

#define PARTMAX 8

arg_t* args = NULL;
char* progname = NULL;

int partarg = 0;
int partmax = 0;

int curarg = 1;

int imagearg = 0;
int typearg = 0;
int dirarg = 0;
int fmtarg = 0;
int sectszarg = 0;
int blockszarg = 0;

int argtable[ARG_PARTS + PARTMAX] = { 0 };

// Argument parsing functions
int argparse(int argc, char** argv)
{
    // Prevent getopt from printing error messages
    opterr = 0;
    // Allocate the args structure
    args = (arg_t*)calloc(1, argc * sizeof(arg_t));
    if(args == NULL)
    {
        printf("%s: Out of memory\n", progname);
        return -1;
    }
    // Use getopt to parse every argument
    char ch = 0;
    while((ch = getopt(argc, argv, ARG_GETOPTSTR)) != -1)
    {
        switch(ch)
        {
            case 'i':
                // Set the argument
                imagearg = curarg;
                ++curarg;
                args[imagearg].type = ARG_IMG;
                // Add the string to the argument list
                args[imagearg].data = (uintptr_t)optarg;
                // Set the table field
                argtable[ARG_IMG - 1] = imagearg;
                break;
            case 't':
                // Set the argument
                typearg = curarg;
                ++curarg;
                args[typearg].type = ARG_DSKFMT;
                // Add the type to the list, but first convert it to a number
                if(!strcmp(optarg, "gpt"))
                    args[typearg].data = DTYP_GPT;
                else if(!strcmp(optarg, "mbr"))
                    args[typearg].data = DTYP_MBR;
                else if(!strcmp(optarg, "iso9660"))
                    args[typearg].data = DTYP_ISO9660;
                else
                {
                    printf("%s: Invalid disk type specified", progname);
                    return -1;
                }
                // Set the table field
                argtable[ARG_DSKFMT - 1] = typearg;
                break;
            case 'd':
                dirarg = curarg;
                ++curarg;
                // Get directory from optarg
                args[dirarg].type = ARG_DIR;
                args[dirarg].data = (uintptr_t)optarg;
                // Set the table field
                argtable[ARG_DIR - 1] = dirarg;
                break;
            case 'h':
                // Print out help
                printf("%s: - generates disk images for NexNix\n", progname);
                printf("Usage:\n");
                printf("./neximg OPTION...\n");
                printf("Valid options include:\n");
                printf("   -i IMAGE - specifies image file, which must already be created\n");
                printf("   -t TYPE  - specifies the disk partition table type. Can be mbr, gpt, or, iso9660\n");
                printf("   -d DIR   - specifies the prefix directory for this image\n");
                printf("   -f       - specifies that this disk's partitions should be formated\n");
                printf("   -p PART  - specifies data about a partition\n");
                printf("   -s SIZE  - specifies the sector size\n");
                printf("   -b SIZE  - specifies the block size for this disk\n");
                printf("   -h       - shows this menu\n");
                printf("The format of a partition entry is shown below:\n");
                printf("   startsect,size,fs,boot\n\n");
                printf("\"startsect\" and \"size\" must be a number, \"fs\" can be either ");
                printf("fat32, fat16, or ext2. \"boot\" must be 0 or 1. There can only be one bootable partition. No field is optional\n");
                printf("For MBR and GPT disks, the -f option is optional. For ISO 9660, the -f and -p options are ignored\n");
                printf("-s must be before and -p options, else weird things may occur\n");
                exit(EXIT_SUCCESS);
            case 'f':
                fmtarg = curarg;
                ++curarg;
                // Simply create the entry
                args[fmtarg].type = ARG_FORMAT;
                // Set the table field
                argtable[ARG_FORMAT - 1] = fmtarg;
                break;
            case 'p':
                if(partmax == 8)
                {
                    printf("%s: only 8 partitions are allowed", progname);
                    return -1;
                }
                // Set up stuff
                partarg = curarg;
                ++curarg;
                argtable[(ARG_PARTS - 1) + partmax] = partarg;
                ++partmax;
                // Allocate the data for this entry
                args[partarg].type = ARG_PARTS;
                args[partarg].data = (uintptr_t)calloc(1, sizeof(part_t));
                // Store the data in the structure
                part_t* part = (part_t*)args[partarg].data;
                if(part == NULL)
                {
                    printf("%s: Out of memory\n", progname);
                    return -1;
                }
                char* tok = strtok(optarg, ",");
                if(tok == NULL)
                {
                    printf("%s: Invalid partition entry\n", progname);
                    return -1;
                }
                part->start = atoi(tok);
                if(!part->start)
                {
                    printf("%s: Invalid partition entry\n", progname);
                    return -1;
                }
                tok = strtok(NULL, ",");
                if(tok == NULL)
                {
                    printf("%s: Invalid partition entry\n", progname);
                    return -1;
                }
                part->size = atoi(tok);
                if(!part->size)
                {
                    printf("%s: Invalid partition entry\n", progname);
                    return -1;
                }
                part->fstype = strtok(NULL, ",");
                if(part->fstype == NULL)
                {
                    printf("%s: Invalid partition entry\n", progname);
                    return -1;
                }
                // Verify the FSType is valid
                if(strcmp(part->fstype, "ext2") && strcmp(part->fstype, "fat32") 
                    && strcmp(part->fstype, "fat16"))
                {
                    printf("%s: Invalid partition entry\n", progname);
                    return -1;
                }
                tok = strtok(NULL, ",");
                if(tok == NULL)
                {
                    printf("%s: Invalid partition entry\n", progname);
                    return -1;
                }
                part->isboot = atoi(tok);
                // Validate bootable flag
                if(part->isboot > 1)
                {
                    printf("%s: bootable flag must only be 0 or 1\n", progname);
                    return -1;
                }
                break;
            case 's':
                // Verify that it is a number and set it
                assert(optarg);
                int sz = atoi(optarg);
                if(sz == 0)
                {
                    printf("%s: sector size must be a number\n", progname);
                    return -1;
                }
                sectszarg = curarg;
                ++curarg;
                argtable[ARG_SECTORSZ - 1] = sectszarg;
                args[sectszarg].type = ARG_SECTORSZ;
                args[sectszarg].data = sz;
                break;
            case 'b':
                // Verify that it is a number and set it
                assert(optarg);
                int bsz = atoi(optarg);
                if(bsz == 0)
                {
                    printf("%s: block size must be a number\n", progname);
                    return -1;
                }
                blockszarg = curarg;
                ++curarg;
                argtable[ARG_BLOCKSZ - 1] = blockszarg;
                args[blockszarg].type = ARG_BLOCKSZ;
                args[blockszarg].data = bsz;
                break;
            case ':':
                // Print out the error
                printf("%s: Required argument not passed\n", progname);
                return -1;
                break;
            case '?':
                // Print out an error
                printf("%s: Unrecognized option passed\n", progname);
                return -1;
                break;
            default:
                // Unreachable (in theory)
                printf("%s: An error occured during argument parsing\n", progname);
                return -1;
        }
    }
    return 0;
}

// Checks to ensure that arguments are valid
int argcheck()
{
    int imagefound = 0;
    int dirfound = 0;
    int typefound = 0;
    int partfound = 0;
    int bootfound = 0;
    int isiso = 0;
    size_t filesz = 0;
    size_t sectsz = 512;

    // Get the user sector override, if sent
    arg_t* sectarg = argget(ARG_SECTORSZ);
    if(sectarg)
        sectsz = sectarg->data;

    // Figure out the sector size
    arg_t* sectszarg = argget(ARG_SECTORSZ);
    if(sectszarg)
        sectsz = sectszarg->data;
    else
        sectsz = DISK_DEFSECTSZ;

    // Loop through every argument
    for(int i = 0; i < (ARG_PARTS + partmax) - 1; ++i)
    {
        // Check what argument this is
        arg_t* arg = &args[argtable[i]];
        if(arg->type == ARG_DIR)
        {
            // Ensure that the directory is valid
            assert(arg->data);
            // Check that the directory exists
            DIR* dir = opendir((const char*)arg->data);
            if(dir == NULL)
            {
                printf("%s: %s: %s\n", progname, (char*)arg->data, strerror(errno));
                return -1;
            }
            closedir(dir);
            dirfound = 1;
        }
        else if(arg->type == ARG_DSKFMT)
        {
            assert(arg->data);
            // Check if this an ISO 9660 disk
            if(arg->data == DTYP_ISO9660)
                isiso = 1;
            typefound = 1;
        }
        else if(arg->type == ARG_IMG)
        {
            assert(arg->data);
            // Ensure that is exists
            int fd = open((const char*)arg->data, O_RDONLY);
            if(fd != -1)
            {
                // Get the size of file
                struct stat st;
                if(fstat(fd, &st))
                {
                    printf("%s: %s: %s\n", progname, (char*)arg->data, strerror(errno));
                    return -1;
                }
                filesz = st.st_size / sectsz;
                if(!S_ISREG(st.st_mode))
                {
                    printf("%s: %s: Not a regular file\n", progname, (char*)arg->data);
                    return -1;
                }
                close(fd);
            }
            // Else, they specified the size here
            else
            {
                // Get the size, which is in megabytes
                int sz = atoi((const char*)arg->data);
                if(sz == 0)
                {
                    // The user probably entered a non existant file
                    printf("%s: invalid image size. This error occurs if you enter a non existant image file\n", \
                            progname);
                    return -1;
                }
                filesz = sz;
            }
            imagefound = 1;
        }
        else if(arg->type == ARG_PARTS)
        {
            assert(i <= ARG_PARTS);
            assert(arg->data);
            // Check that the data is in range
            part_t* part = (part_t*)arg->data;
            if(((part->start * sectsz) + (part->size * sectsz)) > (filesz * sectsz))
            {
                printf("%s: partition %d not in range\n", progname, (i - (ARG_PARTS - 1)) + 1);
                return -1;
            }
            if(part->isboot)
            {
                if(bootfound)
                {
                    printf("%s: only one boot partition is allowed\n", progname);
                    return -1;
                }
                bootfound = 1;
            }
            assert(part->fstype);
            partfound = 1;
        }
    }
    // Check if required things were found
    if(!imagefound || !dirfound || !typefound)
    {
        printf("%s: required argument missing\n", progname);
        return -1;
    }
    if((!bootfound || !partfound) && !isiso)
    {
        printf("%s: required argument missing\n", progname);
        return -1;
    }
    return 0;
}

// Grabs an argument
arg_t* argget(int argid)
{
    // Check for overflow
    assert(argid <= (ARG_PARTS + 8));
    // Get the argument
    arg_t* arg = &args[argtable[argid - 1]];
    assert(arg != NULL);
    // Check if it set
    if(!arg->type)
        return NULL;
    return arg;
}

int main(int argc, char** argv)
{
    progname = basename(argv[0]);
    // Parse the arguments passed to us
    if(argparse(argc, argv))
        return 1;
    if(argcheck())
        return 1;

    // Prepare the disk image
    if(diskinit())
        return 1;

    // Free up argument memory
    for(int i = 0; i < PARTMAX; ++i)
    {
        int idx = argtable[(ARG_PARTS - 1) + i];
        uintptr_t addr = args[idx].data;
        if(addr)
            free((void*)addr);
    }
    free((void*)args);
    return 0;
}
