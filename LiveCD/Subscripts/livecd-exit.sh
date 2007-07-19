#!/bin/sh

#
# Source this script to exit your test/edit environment by typing
# . /livecd-exit.sh
# This script is automatically copied inside chroot environment when you call
# livecd.sh with --edit or --test
#
# --exit
#

# First stops GDM in case it is running like in --test mode
/etc/init.d/gdm stop;

# Restore initial profile and remove profile.original which plays test lock role
sudo cp /etc/profile.original /etc/profile
sudo rm /etc/profile.original

rm -rf /tmp/*;

rm -f /etc/resolv.conf;
#rm -f /etc/X11/xorg.conf;

umount /proc;
#umount /sys # Looks not really necessary...
umount /dev;
rm -f /dev/null;

# Exit chroot
echo
echo "Finished cleaning edit/test environment, exiting now..."
echo
exit

