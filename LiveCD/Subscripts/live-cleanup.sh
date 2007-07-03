#!/bin/sh

#
# --cleanup
#

apt-get clean
rm -rf /tmp/*
rm /etc/resolv.conf
umount /proc
umount /sys # Looks not really necessary...
umount /dev && rm /dev/null

# Etoile specific cleanup
rm -f /root/GNUstep/Defaults/*
cp /home/$ETOILE_USER_NAME/GNUstep/Defaults/.GNUstepDefaults.original /home/$ETOILE_USER_NAME/GNUstep/Defaults/.GNUstepDefaults
rm -r /home/$ETOILE_USER_NAME/GNUstep/Library/ApplicationSupport/AZDock
rm -r /home/$ETOILE_USER_NAME/GNUstep/Library/Addresses
rm -r /home/$ETOILE_USER_NAME/GNUstep/Library/Bookmark

# Build cleanup

rm -r /build
apt-get -y uninstall subversion

exit

$SUBSCRIPT_DIR/livecd-shrink.sh
