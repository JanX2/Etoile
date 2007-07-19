#!/bin/sh

#
# --prepare
#

# Set up Squashfs

sudo apt-get install squashfs-tools
sudo modprobe squashfs

# Move into new work directory

mkdir $LIVECD_DIR
cd $LIVECD_DIR

# Fetch original image file from Ubuntu server

if [ ! -f $UBUNTU_IMAGE ]; then
	wget $UBUNTU_DOWNLOAD_URL
	export UBUNTU_IMAGE=$LIVECD_DIR/$UBUNTU_IMAGE_NAME
fi

# Mount the existing image

mkdir mnt
sudo mount -o loop $UBUNTU_IMAGE mnt

# Extract the content of mounted image into extract-cd directory

mkdir extract-cd
rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract-cd

# Mount squashfs of existing image. Squashfs represents the filesystem of the
# livecd when it's running. Filesystem you see when you use the livecd after
# booting is different from the livecd's filesystem itself you can browse
# by simply inserting the livecd in the context of another system already 
# booted.

mkdir squashfs
sudo mount -t squashfs -o loop mnt/casper/filesystem.squashfs squashfs

# Extract squashfs in another directory named edit. This is the directory 
# where all customization will take place and which will be used as source of
# the new image to generate.

mkdir edit
sudo cp -a squashfs/* edit/

