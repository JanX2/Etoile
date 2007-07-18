#!/bin/sh

# --edit

# Import a script that will allows us to exit cleanly later
sudo $SUBSCRIPT_DIR/livecd-exit.sh $LIVECD_DIR/edit

# Export network settings of your own configuration to allow network access 
# from chrooted environment
sudo cp /etc/resolv.conf $LIVECD_DIR/edit/etc/

# chroot

sudo chroot $LIVECD_DIR/edit

mount -t proc none /proc
mount -t sysfs none /sys
export HOME=/root
export LC_ALL=C

