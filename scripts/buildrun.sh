#! /usr/bin/env sh
# buildrun.sh - build and run shortcut for Linux
# Distributed with NexNix, licensed under the MIT license
# See LICENSE

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
    echo "$(basename $0): error: architecture must be set"
fi

# Check if we need to configure it
if [ ! -d $PWD/build-$arch ]
then
    ./build.sh -a$arch -Aconfigure -p$PWD/rootdir-$arch -d -j$(nproc)
    checkerr $? "unable to configure NexNix"
fi

# Build it
./build.sh -a$arch -Abuild -p$PWD/rootdir-$arch -j$(nproc)
#checkerr $? "unable to build NexNix"

# Create the images(s)
sudo ./build.sh -a$arch -Aimage -i$PWD/images-$arch -p$PWD/rootdir-$arch -u$(whoami)
checkerr $? "unable to generate disk image(s) for NexNix"

# Run it in QEMU
./scripts/run.sh $arch
