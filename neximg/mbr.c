/*
    mbr.c - contains MBR partition table code
    Distributed with NexNix, licensed under the MIT license
    See LICENSE
*/

#include "neximg.h"

// An MBR partition
typedef struct _mbrpart
{
    uint8_t flags;                  // Bit 7 is bootable flag
    uint8_t chsstart[3];            // Partition start in CHS
    uint8_t type;                   // Partition type
    uint8_t chsend[3];              // Partition end in CHS
    uint32_t lbastart;              // The LBA address of the partitions start
    uint32_t size;                  // Size of partition sectors
}__attribute__((packed)) mbrpart_t;

// MBR structure
typedef struct _mbr
{
    uint8_t jmp[3];                 // 0xEB and so on stuff
    uint8_t bpb[60];                // The BIOS parameter block
    uint8_t code[377];              // The boot code
    uint32_t diskid;                // The ID of the disk
    uint16_t resvd;
    mbrpart_t parts[4];             // The partitions
    uint16_t sig;                   // 0xAA55 signature
}__attribute__((packed)) mbr_t;

// MBR defines

// The BIOS signature
#define MBR_BOOTSIG 0xAA55

// Is it active?
#define MBR_ACTIVE (1 << 7)

// Filesystem types
#define MBR_FSFAT 0x0C
#define MBR_FSEXT2 0x83
#define MBR_FSFAT16 0x04
#define MBR_TYPEEXT 0x0F

// Partition type table
uint8_t types[] = { MBR_FSFAT, MBR_FSEXT2, MBR_FSFAT16 };

// Alignment data
#define MBR_PARTALIGN 2048

// EMBR flag
int needembr = 0;

// Partition allocation data
uint32_t cursector = 0;

// Sets up MBR command data
void mbrinitcommon(mbrpart_t* part, uint32_t base, uint32_t size, uint8_t type)
{
    // Copy the data
    part->lbastart = base;
    part->size = size;
    part->type = type;
    // Set up CHS stuff
    part->chsstart[0] = 0xFF;
    part->chsstart[1] = 0xFF;
    part->chsstart[2] = 0xFF;

    part->chsend[0] = 0xFF;
    part->chsend[1] = 0xFF;
    part->chsend[2] = 0xFF;
}

// Creates a partition
int mbrinitpart(part_t* part, int idx, mbr_t* mbr)
{
    mbrpart_t* mbrpart = &mbr->parts[idx];
    // Align cursector to the next 1MiB boundary
    if(cursector == 0)
        cursector = 2048;
    else
        cursector = (cursector & (MBR_PARTALIGN - 1) ? ((cursector + MBR_PARTALIGN) 
                    & ~(MBR_PARTALIGN - 1)) : cursector);
    // Set up the location
    mbrinitcommon(mbrpart, cursector, part->size, types[part->fstype - 1]);
    cursector += part->size;
    // Check if active bit needs to be set
    if(part->isboot)
        mbrpart->flags = MBR_ACTIVE;
    return 0;
}

// Initializes an MBR
void initmbr(mbr_t* mbr)
{
    memset(mbr, 0, sizeof(mbr_t));
    mbr->sig = MBR_BOOTSIG;
    // Setup opcode for near jump
    mbr->jmp[0] = 0xEB;                  // Near jump with 8 bit displacement
    mbr->jmp[1] = 0x3D;                  // It is 61 bytes ahead
    mbr->jmp[2] = 0x90;                  // A NOP
}

// Creates a partition table
int mbrcreate(parts_t* parts)
{
    // Initialize MBR table
    mbr_t* mbr = (mbr_t*)malloc(sizeof(mbr_t));
    if(!mbr)
    {
        printf("%s: out of memory\n", getprogname());
        return -1;
    }
    initmbr(mbr);
    // Set disk ID
    srand(time(NULL));
    mbr->diskid = rand();
    if(getnumparts() > 4)
        needembr = 1;
    int master_parts = needembr ? 3 : 4;
    // Initialize all partitions on sector 0
    for(int i = 0; i < master_parts; ++i)
        mbrinitpart(parts->parts[i], i, mbr);
    // If needed, intialize the EMBRs
    if(needembr)
    {
        mbr_t* prevmbr = mbr;
        int prevmbrsector = 0;
        int embrplace = 3;
        uint32_t extbase = 0;
        // Figure out how many EMBRs are needed
        int numembrs = getnumparts() - 3;
        // Figure out how much space all extended partitions are taking up
        uint32_t extspace = 0;
        for(int i = master_parts; i < getnumparts(); ++i)
        {
            uint32_t sizealign = parts->parts[i]->size;
            sizealign = (sizealign & (MBR_PARTALIGN - 1) ? (sizealign + MBR_PARTALIGN) 
                    & ~(MBR_PARTALIGN - 1) : sizealign);
            extspace += sizealign;
        }
        for(int i = 0; i < numembrs; ++i)
        {
            // Set up the MBR
            mbr_t* embr = (mbr_t*)malloc(sizeof(mbr_t));
            if(!embr)
            {
                printf("%s: out of memory\n", getprogname());
                return -1;
            }
            initmbr(embr);
            int mbrsector = ++cursector;
            cursector++;
            // Initialize the partition for this EMBR
            mbrinitpart(parts->parts[master_parts + i], 0, embr);
            // Reset the base
            embr->parts[0].lbastart = embr->parts[0].lbastart - mbrsector;

            mbrinitcommon(&prevmbr->parts[embrplace], mbrsector - extbase, extspace, MBR_TYPEEXT);
            uint32_t sizealign = parts->parts[i]->size;
            sizealign = (sizealign & (MBR_PARTALIGN - 1) ? (sizealign + MBR_PARTALIGN) 
                    & ~(MBR_PARTALIGN - 1) : sizealign);
            extspace -= sizealign;
            // Write these out to disk
            diskwrite(mbrsector, embr, 1);
            diskwrite(prevmbrsector, prevmbr, 1);
            prevmbrsector = mbrsector;
            free(prevmbr);
            prevmbr = embr;
            if(!extbase)
                extbase = mbrsector;
            embrplace = 1;
        }
    }
    else
    {
        diskwrite(0, mbr, 1);
        free(mbr);
    }
    return 0;
}
