#!/bin/sh

# Download and install Etoile, GNUstep and all required dependencies
$SUBSCRIPT_DIR/ubuntu-install-etoile.sh

#
# In all the code that follows it's important to take in account it can be run
# multiple times, so we must restore any conf file in its original state before
# applying modifications.
#

# Login panel specific stuff
# NOTE: Keep a copy of original gdm.conf before deleting it to force 
# gdm.conf-custom to be used
if [ -f /etc/gdm.conf ]; then
	cp /etc/gdm/gdm.conf /etc/gdm.conf-original
	rm /etc/gdm/gdm.conf
fi
sed -e '/^Greeter.*$/d' /etc/gdm/gdm.conf-custom
sed -e 's/\(^\[greeter\].*$\)/\1\nGreeter=\/usr\/local\/bin\/etoile_login.sh/' /etc/gdm/gdm.conf-custom
# NOTE: su gdm doesn't work, so we pass the default in GDM greeter script
#su gdm
#defaults write Login ETAllowUserToChooseEnvironment 'NO'
cp Services/Private/Login/etoile_login.sh /usr/local/bin
#sed -e '/-ETAllowUserToChooseEnvironment "NO"/d' /usr/local/bin/etoile_login.sh
sed -e 's/\(Login.*\)/\1 -ETAllowUserToChooseEnvironment "NO"/' /usr/local/bin/etoile_login.sh
exit

# Add a new user named 'etoile' and set up Etoile environment
# NOTE: This is the only part where user interaction is necessary

adduser $ETOILE_USER_NAME
adduser $ETOILE_USER_NAME powerdev lpadmin netdev scanner plugdev video dip 
adduser $ETOILE_USER_NAME audio floppy cdrom dialout adm
# Add 'etoile' user to sudoers
adduser $ETOILE_USER_NAME admin
if [ ! -f /etc/sudoers-original ]; then
	cp /etc/sudoers /etc/sudoers-original
else
	cp /etc/sudoers-original /etc/sudoers
fi
echo '%admin	ALL=(ALL) ALL' >> /etc/sudoers

su $ETOILE_USER_NAME
. /System/Library/Makefiles/GNUstep.sh
./setup.sh

defaults write AZDock DockedApplications "({ Command = Typewriter; Type = 0; }, { Command = Grr; Type = 0; },  { Command = StepChat; Type = 0; }, { Command = "/usr/bin/firefox"; Type = 1; WMClass = "Firefox-bin"; WMInstance = "firefox-bin"; }, { Command = Gorm; Type = 0; })"

# NOTE: Keep a pristine copy of the defaults to be reset on cleanup
cp /home/$ETOILE_USER_NAME/GNUstep/Defaults/.GNUstepDefaults /home/$ETOILE_USER_NAME/GNUstep/Defaults/.GNUstepDefaults.original

exit

cd .. # Move out of Etoile directory

# Customize boot screens with usplash

apt-get install libusplash-dev # libupsplash-dev requires libc6-dev

cd LiveCD/BootScreen
make && make install
dpkg-reconfigure linux-image-$(uname -r)
cd..

# Install hidden root directory list and init script (which will be run as root 
# on GDM login)

cd LiveCD
cp hidden /.hidden
cp init.sh /etc/gdm/PostLogin/Default
cd ..

# Finally remove some Ubuntu user stuff
rm -rf /home/$ETOILE_USER_NAME/Desktop
rm -rf /home/$ETOILE_USER_NAME/Examples

