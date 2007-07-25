#!/bin/sh

#
# --cleanup
#

echo
echo "Entering Cleanup stage..."

# For extra safety (normally handled by livecd-exit.sh)
rm -rf /tmp/*
rm -f /etc/resolv.conf

# Linux/GNOME specific cleanup
rm -f /home/$ETOILE_USER_NAME/.bash_history
rm -f /home/$ETOILE_USER_NAME/.esd_auth
rm -f /home/$ETOILE_USER_NAME/.gtkrc-1.2-gnome2
rm -f /home/$ETOILE_USER_NAME/.lesshst
rm -f /home/$ETOILE_USER_NAME/.recently-used.xbel
rm -f /home/$ETOILE_USER_NAME/.sudo_as_admin_successful
rm -f /home/$ETOILE_USER_NAME/.xsession-errors
rm -rf /home/$ETOILE_USER_NAME/.gnome
rm -rf /home/$ETOILE_USER_NAME/.gnome2
rm -rf /home/$ETOILE_USER_NAME/.gnome2_private
rm -rf /home/$ETOILE_USER_NAME/.gstreamer-0.10
rm -rf /home/$ETOILE_USER_NAME/.metacity
rm -rf /home/$ETOILE_USER_NAME/.nautilus
rm -rf /home/$ETOILE_USER_NAME/.Trash
rm -rf /home/$ETOILE_USER_NAME/.update-notifier

# Etoile specific cleanup
rm -f /root/GNUstep/Defaults/*
cp /home/$ETOILE_USER_NAME/GNUstep/Defaults/.GNUstepDefaults.original /home/$ETOILE_USER_NAME/GNUstep/Defaults/.GNUstepDefaults
# Don't clean up AZDock because it contains Firefox cached icon actually
#rm -r /home/$ETOILE_USER_NAME/GNUstep/Library/ApplicationSupport/AZDock
rm -rf /home/$ETOILE_USER_NAME/GNUstep/Library/Addresses
rm -rf /home/$ETOILE_USER_NAME/GNUstep/Library/Bookmark

# Build cleanup
if [ $REMOVE_BUILD_FILES = yes ]; then
	rm -r /build
	apt-get -y uninstall subversion
fi

apt-get clean

exit

