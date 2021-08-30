#! /bin/bash
# image.sh - contains disk image management
# SPDX-License-Identifier: ISC

# Data for use by this script
args=$@
image=
size=
type=
dir=
parts=()
fstypes="ext2 fat32 active esp"
parttypes="mbr gpt iso isohybrid"
parttype=
user=

# Panics
panic()
{
    echo "$(basename $0): $1"
    exit 1
}

# Checks if an error occured, and panics if one did
checkerr()
{
    if [ "$1" != "0" ]
    then
        panic "$2"
    fi
}

argparse()
{
    arglist="p:s:i:d:u:t:"
    # Read them in
    while getopts $arglist arg $args > /dev/null 2> /dev/null; do
        case ${arg} in
            "p")
                parts+=($OPTARG)
                ;;
            "s")
                size=$OPTARG
                ;;
            "i")
                image=$OPTARG
                ;;
            "d")
                # Check that is exists
                if [ ! -d $OPTARG ]
                then
                    panic "directory does not exist"
                fi
                dir=$OPTARG
                ;;
            "u")
                user=$OPTARG
                ;;
            "t")
                # Check that is is valid
                for type in $parttypes
                do
                    if [ "$OPTARG" = "$type" ]
                    then
                        parttype=$OPTARG
                        break
                    fi
                done
                if [ -z "$parttype" ]
                then
                    panic "partition type invalid"
                fi
                ;;
            "?")
                panic "unrecognized argument specified"
                ;;
        esac
    done
}

checkarg()
{
    # Check for required arguments
    if [ -z "$size" ]
    then
        panic "size not specified"
    fi

    if [ -z "${parts[0]}" ]
    then
        panic "partition not specified"
    fi

    if [ -z "$image" ]
    then
        panic "image file not specified"
    fi

    if [ -z "$dir" ]
    then
        panic "input directory not specified"
    fi

    if [ -z "$user" ]
    then
        panic "user not specified"
    fi

    if [ -z "$parttype" ]
    then
        panic "partition type not specified"
    fi
}

partimg()
{
    # First create a partition table, except on floppies
    if [ "$parttype" = "gpt" ]
    then
        parted -s $image "mklabel gpt"
        checkerr $? "unable to create partition table"
    elif [ "$parttype" = "mbr" ]
    then
        parted -s $image "mklabel msdos"
        checkerr $? "unable to create partition table"
    fi
    # Loop through every partition
    index=0
    while [ ! -z "${parts[$index]}" ]
    do
        # Pull apart the partition data
        base=$(echo "${parts[$index]}" | awk -F',' '{ print $1 }')
        # Verify that it is numeric
        base=$(echo "$base" | awk '/[0-9]/')
        if [ -z "$base" ]
        then
            panic "base sector not specified in partition entry"
        fi
        # Grab the size
        psize=$(echo "${parts[$index]}" | awk -F',' '{ print $2 }')
        # Verify that is is numeric
        psize=$(echo "$psize" | awk '/[0-9]/')
        if [ -z "$psize" ]
        then
            panic "size not specified in partition entry"
        fi
        # Grab the filesystem type
        fstype=$(echo "${parts[$index]}" | awk -F',' ' { print $3 }')
        if [ -z "$fstype" ]
        then
            panic "filesystem not specified on partition entry"
        fi
        typefound=0
        # Verify it
        for typ in $fstypes
        do
            if [ "$typ" = "$fstype" ]
            then
                typefound=1
                break
            fi
        done
        if [ $typefound -ne 1 ]
        then
            panic "invalid filesystem specified in partition entry"
        fi
        # Grab the directory prefix
        dirprefix=$(echo "${parts[$index]}" | awk -F',' ' { print $4 }')
        if [ -z "$dirprefix" ]
        then
            panic "prefix not specified in partition entry"
        fi
        # Verify that is starts with a /
        slash=$(echo "$dirprefix" | awk '/^\//')
        if [ -z "$slash" ]
        then
            panic "partition prefix must be absolute"
        fi
        if [ "$base" = "0" ]
        then
            base=1
        fi
        # Create the partition
        if [ "$fstype" = "esp" ]
        then
            if [ "$parttype" = "mbr" ]
            then
                panic "ESP cannot be created on MBR volume"
            fi
            parted -s $image "unit MiB mkpart empty fat32 $base $psize set $((index+1)) esp on"
            checkerr $? "unable to create partition"
        elif [ "$fstype" = "active" ]
        then
            if [ "$parttype" = "gpt" ]
            then
                panic "active partition cannot be created on GPT volume"
            fi
            parted -s $image "unit MiB mkpart primary fat32 $base $psize set $((index+1)) boot on"
            checkerr $? "unable to create partition"
        else
            if [ "$parttype" = "mbr" ]
            then
                parted -s $image "unit MiB mkpart primary $base $psize"
            elif [ "$parttype" = "gpt" ]
            then
                parted -s $image "unit MiB mkpart empty $base $psize"
            fi
            checkerr $? "unable to create partition"
        fi
        # Create the loopback device
        dev=
        dev=$(kpartx -av $image)
        checkerr $? "adding partition failed"
        dev=$(echo "$dev" | awk -vline=$((index+1)) '$FNR == $line { print $3 }')
        # Format it
        if [ "$fstype" = "fat32" ] || [ "$fstype" = "esp" ] || [ "$fstype" = "active" ]
        then
            mkfs.fat -F32 /dev/mapper/$dev > /dev/null 2>&1
        elif [ "$fstype" = "ext2" ]
        then
            mke2fs /dev/mapper/$dev > /dev/null 2>&1
        fi
        # Copy over the needed data to this partition
        mkdir fs
        mount /dev/mapper/$dev fs
        sleep 1
        cp -r ${dir}${dirprefix}/* fs/
        sleep 1
        # Now we can cleanup
        umount fs
        kpartx -d $image > /dev/null 2>&1
        rm -rf fs
        index=$((index+1))
    done
}

main()
{
    export LC_ALL=C
    # Read in all arguments
    argparse
    # Verfiy the arguments
    checkarg
    # Handle an ISO image
    if [ "$parttype" = "iso" ] || [ "$parttype" = "isohybrid" ]
    then
        mbrfile=$(echo "${parts[0]}" | awk -F',' '{ print $2 }')
        if [ -z "$mbrfile" ]
        then
            panic "ISOMBR path not specified"
        fi
        inputdir=$(echo "${parts[0]}" | awk -F',' '{ print $1 }')
        if [ -z "$inputdir" ]
        then
            panic "input directory not specified"
        fi
        img=${dir}/${inputdir}/tmp.img
        if [ ! -f $img ]
        then
            dd if=/dev/zero of=$img bs=1M count=$size > /dev/null 2>&1
        fi
        size=$((size * 512))
        size=$((size / 1024))
        # Format this disk
        dev=$(losetup -f)
        losetup $dev $img
        mkfs.vfat -F32 $dev > /dev/null 2>&1
        mkdir fs
        mount $dev fs
        sleep 1
        cp -r ${dir}/boot/* fs/
        sleep 1
        umount fs
        losetup -d $dev
        rm -rf fs
        # Convert it to a CDROM
        if [ "$parttype" = "iso" ]
        then
            xorriso -as mkisofs ${dir}/${inputdir} -R -J -c bootcat -b ${mbrfile} \
                -no-emul-boot -boot-load-size 4 \
                -eltorito-alt-boot -e $(basename $img) -no-emul-boot -isohybrid-gpt-basdat -o $image \
                > /dev/null 2>&1
        elif [ "$parttype" = "isohybrid" ]
        then
            xorriso -as mkisofs ${dir}/${inputdir} -R -J -c bootcat -b $(basename $img) \
                    -hard-disk-boot -boot-load-size 4 -o $image > /dev/null 2>&1
        fi
        exit 0
    fi
    # Create the disk image
    if [ ! -f $image ] && [ ! -b $image ]
    then
        dd if=/dev/zero of=$image bs=1M count=$size > /dev/null 2>&1
        checkerr $? "disk image creation failed"
    fi
    # Partition the disk image
    partimg $image
    # Change ownership to caller
    chown $user $image
    chown $user $(dirname $image)
}

# Launch the main part of the script
main
