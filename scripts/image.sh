#! /bin/bash
# image.sh - contains disk image management
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

# Data for use by this script
args=$@
image=
size=
type=
dir=
parts=()
types="gpt iso"
fstypes="ext2 fat32 esp"

# Checks if an error occured, and panics if one did
checkerr()
{
    if [ "$1" != "0" ]
    then
        echo "$0: $2"
        exit 1
    fi
}

argparse()
{
    arglist="p:s:i:t:d:"
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
            "t")
                # Validate it
                for curtype in $types; do
                    if [ "$curtype" = "$OPTARG" ]
                    then
                        type=$curtype
                    fi
                done
                if [ -z "$type" ]
                then
                    echo "$0: invalid partition table type"
                    exit 1
                fi
                ;;
            "d")
                # Check that is exists
                if [ ! -d $OPTARG ]
                then
                    echo "$0: directory does not exist"
                    exit 1
                fi
                dir=$OPTARG
                ;;
            "?")
                echo "$0: unrecognized argument"
                exit 1
                ;;
        esac
    done
}

checkarg()
{
    # Check for required arguments
    if [ -z "$size" ]
    then
        echo "$0: size not specified"
        exit 1
    fi

    if [ -z "${parts[0]}" ]
    then
        echo "$0: partition not specified"
        exit 1
    fi

    if [ -z "$image" ]
    then
        echo "$0: image file not specified"
        exit 1
    fi

    if [ -z "$type" ]
    then
        echo "$0: partition table type not specified"
        exit 1
    fi

    if [ -z "$dir" ]
    then
        echo "$0: input directory not specified"
        exit 1
    fi
}

partimg()
{
    # First create a partition table 
    parted -s $image "mktable gpt"
    checkerr $? "unable to create partition table"
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
            echo "$0: invalid partition entry"
            rm -f tmp.img
            exit 1
        fi
        # Grab the size
        psize=$(echo "${parts[$index]}" | awk -F',' '{ print $2 }')
        # Verify that is is numeric
        psize=$(echo "$psize" | awk '/[0-9]/')
        if [ -z "$psize" ]
        then
            echo "$0: invalid partition entry"
            rm -f tmp.img
            exit 1
        fi
        # Grab the filesystem type
        fstype=$(echo "${parts[$index]}" | awk -F',' ' { print $3 }')
        if [ -z "$fstype" ]
        then
            echo "$0: invalid partition entry"
            rm -f tmp.img
            exit 1
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
            echo "$0: invalid partition entry"
            rm -f tmp.img
            exit 1
        fi
        # Grab the directory prefix
        dirprefix=$(echo "${parts[$index]}" | awk -F',' ' { print $4 }')
        if [ -z "$dirprefix" ]
        then
            echo "$0: invalid partition entry"
            rm -f tmp.img
            exit 1
        fi
        # Verify that is starts with a /
        slash=$(echo "$dirprefix" | awk '/^\//')
        if [ -z "$slash" ]
        then
            echo "$0: partition prefix must be absolute"
            rm -f tmp.img
            exit 1
        fi
        if [ "$base" = "0" ]
        then
            base=1
        fi
        # Create the partition
        if [ "$fstype" = "esp" ]
        then
            parted -s $image "unit MiB mkpart empty fat32 $base $psize set $((index+1)) esp on"
            checkerr $? "unable to create partition"
        else
            parted -s $image "unit MiB mkpart empty $fstype $base $psize"
            checkerr $? "unable to create partition"
        fi
        # Create the loopback device
        dev=
        dev=$(kpartx -av $image)
        checkerr $? "adding partition failed"
        dev=$(echo "$dev" | awk -vline=$((index+1)) '$FNR == $line { print $3 }')
        # Format it
        if [ "$fstype" = "fat32" ] || [ "$fstype" = "esp" ]
        then
            mkdosfs -F32 /dev/mapper/$dev > /dev/null 2>&1
        elif [ "$fstype" = "ext2" ]
        then
            mke2fs /dev/mapper/$dev > /dev/null 2>&1
        fi
        # Copy over the needed data to this partitionS
        mkdir fs
        mount /dev/mapper/$dev fs
        cp -r ${dir}${dirprefix}/* fs/
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
    # Create the disk image
    if [ "$type" = "iso" ]
    then
        dd if=/dev/zero of=tmp.img bs=1M count=$size > /dev/null 2>&1
        checkerr $? "disk image creation failed"
    else
        dd if=/dev/zero of=$image bs=1M count=$size > /dev/null 2>&1
        checkerr $? "disk image creation failed"
    fi

    # Partition the disk image
    if [ "$type" = "iso" ]
    then
        isoimage=$image
        image=tmp.img
    fi
    partimg $image
    # If we are building the ISO image, run xorriso now
    if [ "$type" = "iso" ]
    then
        rm -f $isoimage
        xorriso -as mkisofs -o $isoimage -iso-level 3 -V NexNix ./$image -e $image -no-emul-boot \
            >/dev/null 2>&1
        rm tmp.img
    fi
}

# Launch the main part of the script
main
