/*
    main.c - contains main code for neximg
    Distributed with NexNix, licensed under the MIT license
    See LICENSE
*/

#include "neximg.h"

#define PARTMAX 8

arg_t* args = NULL;
char* progname = NULL;
int partmax = 0;
int curarg = 1;
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
                args[curarg].type = ARG_IMG;
                // Add the string to the argument list
                args[curarg].data = (uintptr_t)optarg;
                // Set the table field
                argtable[ARG_IMG - 1] = curarg;
                ++curarg;
                break;
            case 't':
                // Set the argument
                args[curarg].type = ARG_DSKFMT;
                // Add the type to the list, but first convert it to a number
                if(!strcmp(optarg, "gpt"))
                    args[curarg].data = DTYP_GPT;
                else if(!strcmp(optarg, "mbr"))
                    args[curarg].data = DTYP_MBR;
                else if(!strcmp(optarg, "iso9660"))
                    args[curarg].data = DTYP_ISO9660;
                else
                {
                    printf("%s: Invalid disk type specified", progname);
                    return -1;
                }
                // Set the table field
                argtable[ARG_DSKFMT - 1] = curarg;
                ++curarg;
                break;
            case 'd':
                // Get directory from optarg
                args[curarg].type = ARG_DIR;
                args[curarg].data = (uintptr_t)optarg;
                // Set the table field
                argtable[ARG_DIR - 1] = curarg;
                ++curarg;
                break;
            case 'h':
                // Print out help
                printf("%s: - generates disk images for NexNix\n", progname);
                printf("Usage:\n");
                printf("./neximg OPTION...\n");
                printf("Valid options include:\n");
                printf("   -i IMAGE - specifies image file, which must already be created\n");
                printf("   -t TYPE  - specifies the disk partition table type. Can be mbr, gpt, or iso9660\n");
                printf("   -d DIR   - specifies the prefix directory for this image\n");
                printf("   -f       - specifies that this disk's partitions should be formated\n");
                printf("   -p PART  - specifies data about a partition\n");
                printf("   -s SIZE  - specifies the sector size\n");
                printf("   -b SIZE  - specifies the block size for this disk\n");
                printf("   -c COUNT - the number of sectors for this disk, and tell neximg to create the image");
                printf("   -h       - shows this menu\n");
                printf("The format of a partition entry is shown below:\n");
                printf("   startsect,size,fs,boot\n\n");
                printf("\"startsect\" and \"size\" must be a number, \"fs\" can be either ");
                printf("fat32, fat16, or ext2. \"boot\" must be 0 or 1. There can only be one bootable partition. No field is optional\n");
                printf("For MBR and GPT disks, the -f option is optional. For ISO 9660 and floppy, the -f and -p options are ignored\n");
                printf("-s must be before and -p options, else weird things may occur\n");
                exit(EXIT_SUCCESS);
            case 'f':
                // Simply create the entry
                args[curarg].type = ARG_FORMAT;
                // Set the table field
                argtable[ARG_FORMAT - 1] = curarg;
                ++curarg;
                break;
            case 'p':
                if(partmax == 8)
                {
                    printf("%s: only 8 partitions are allowed", progname);
                    return -1;
                }
                // Set up stuff
                argtable[(ARG_PARTS - 1) + partmax] = curarg;
                ++partmax;
                // Allocate the data for this entry
                args[curarg].type = ARG_PARTS;
                args[curarg].data = (uintptr_t)calloc(1, sizeof(part_t));
                // Store the data in the structure
                part_t* part = (part_t*)args[curarg].data;
                ++curarg;
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
                argtable[ARG_SECTORSZ - 1] = curarg;
                args[curarg].type = ARG_SECTORSZ;
                args[curarg].data = sz;
                ++curarg;
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
                argtable[ARG_BLOCKSZ - 1] = curarg;
                args[curarg].type = ARG_BLOCKSZ;
                args[curarg].data = bsz;
                ++curarg;
                break;
            case 'c':
                assert(optarg);
                // Verify that this is a number
                int sectcount = atoi(optarg);
                if(sectcount == 0)
                {
                    printf("%s: sector count must be a number\n", progname);
                    return -1;
                }
                argtable[ARG_IMGSZ - 1] = curarg;
                args[curarg].type = ARG_IMGSZ;
                args[curarg].data = sectcount;
                ++curarg;
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
    int countfound = 0;
    int isiso = 0;
    size_t filesz = 0;
    size_t sectsz = 512;

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
            imagefound = 1;
        }
        else if(arg->type == ARG_PARTS)
        {
            assert(i <= ARG_PARTS);
            assert(arg->data);
            // Check that the data is in range
            part_t* part = (part_t*)arg->data;
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
        else if(arg->type == ARG_IMGSZ)
        {
            assert(arg->data);
            filesz = arg->data;
            countfound = 1;
        }
    }
    // Check if required things were found
    if(!imagefound || !dirfound || !typefound || !countfound)
    {
        printf("%s: required argument missing\n", progname);
        return -1;
    }
    if((!bootfound || !partfound) && !isiso)
    {
        printf("%s: required argument missing\n", progname);
        return -1;
    }
    // Now check that all partitions are in range
    for(int i = ARG_PARTS; i < (ARG_PARTS + partmax); ++i)
    {
        arg_t* arg = &args[argtable[i - 1]];
        assert(arg->type);
        assert(arg->data);
        part_t* part = (part_t*)arg->data;
        if((part->start + part->size) > filesz)
        {
            printf("%s: partition %d is not in range\n", progname, i - ARG_PARTS);
            return -1;
        }
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

    for(int i = 0; i < (ARG_PARTS + (partmax - 1)); ++i)
    {
        arg_t* arg = &args[argtable[i]];
        printf("%d %d %d\n", i, argtable[i], arg->type);
    }
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
