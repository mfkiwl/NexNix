#! /usr/bin/env sh
# buildrun.sh - build and run shortcut for Linux
# SPDX-License-Identifier: ISC

checkerr()
{
    if [ $1 -ne 0 ]
    then
        echo "$(basename $0): error: $2"
        exit 1
    fi
}

# Grab the architecture
arch=$1
if [ -z "$arch" ]
then
    echo "$(basename $0): error: architecture not specified"
fi

# Configure it, if needed
if [ "$CONFIGURE" = "1" ]
then
    # Figure out what configuration to use
    if [ "$arch" = "i386-pc" ]
    then
        if [ "$USEISO" = "1" ]
        then
            conf=i386pc-iso
        else
            conf=i386pc
        fi
    fi
    ./build.sh -a$arch -Aconfigure -p$PWD/rootdir-$arch -d -j$(nproc) -b$PWD/build-$arch \
                -i$PWD/images-$arch -o$PWD/output-$conf -c$conf
    checkerr $? "unable to configure NexNix"
fi

# Build it
./build.sh -a$arch -Abuild -j$(nproc)
checkerr $? "unable to build NexNix"

# Create it
sudo ./build.sh -a$arch -Aimage -u$(whoami)
checkerr $? "unable to generate image configuration for NexNix"

# Run it in an emulator
./scripts/run.sh $arch
 