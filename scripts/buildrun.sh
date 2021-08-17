#! /usr/bin/env sh
# buildrun.sh - build and run shortcut for Linux
# Copyright 2021 Jedidiah Thompson
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
if [ ! -d $PWD/build-$arch ] && [ "$RECONFIGURE" != "1" ]
then
    ./build.sh -a$arch -Aconfigure -p$PWD/rootdir-$arch -d -j$(nproc)
    checkerr $? "unable to configure NexNix"
fi

# Build it
./build.sh -a$arch -Abuild -p$PWD/rootdir-$arch -j$(nproc)
checkerr $? "unable to build NexNix"

# Create the images(s)
sudo ./build.sh -a$arch -Aimage -i$PWD/images-$arch -p$PWD/rootdir-$arch -u$(whoami)
checkerr $? "unable to generate disk image(s) for NexNix"

# Run it in QEMU
./scripts/run.sh $arch
