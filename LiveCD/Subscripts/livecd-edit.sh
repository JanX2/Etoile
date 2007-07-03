#!/bin/sh

# --edit

# Export network settings of your own configuration to allow network access 
# from chrooted environment
sudo cp /etc/resolv.conf edit/etc/

# chroot

sudo chroot edit

mount -t proc none /proc
mount -t sysfs none /sys
export HOME=/root
export LC_ALL=C

