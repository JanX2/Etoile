#!/bin/sh

# --build

mkdir build
cd build

# Install Etoile and GNUstep dependencies

sudo apt-get -y install gobjc-4.1 openssl libssl-dev libxml2-dev libxslt1-dev libffi4-dev libjpeg62-dev libtiff4-dev libpng12-dev libungif4-dev libfreetype6-dev libx11-dev libart-2.0-dev libxft-dev libxmu-dev libxss-dev xscreensaver libdbus-1-dev libstartup-notification0-dev g++ libpoppler-dev

# Install Subversion to be able to check both GNUstep and Etoile stable versions

sudo apt-get -y install subversion

# Check out and build GNUstep stable version

svn co http://svn.gna.org/svn/gnustep/tools/make/branches/stable gnustep-make
svn co http://svn.gna.org/svn/gnustep/libs/base/branches/stable gnustep-base
svn co http://svn.gna.org/svn/gnustep/libs/gui/branches/stable gnustep-gui
svn co http://svn.gna.org/svn/gnustep/libs/back/branches/stable gnustep-back

cd gnustep-make
./configure --prefix=/ && make && sudo make install
cd ..
. /System/Library/Makefiles/GNUstep.sh
cd gnustep-base
./configure && make && sudo make install
cd ..
cd gnustep-gui
./configure && make && sudo make install
cd ..
cd gnustep-back
./configure && make && sudo make install
cd ..

# Download latest StepTalk release over FTP, uncompress and build it

wget ftp://ftp.gnustep.org/pub/gnustep/libs/StepTalk-0.10.0.tar.gz
tar -xzf StepTalk-0.10.0.tar.gz
cd StepTalk
make && sudo make install
cd ..

# Download latest Gorm release over FTP, uncompress and build it

wget ftp://ftp.gnustep.org/pub/gnustep/dev-apps/gorm-1.2.1.tar.gz
tar -xzf gorm-1.2.1.tar.gz

cd gorm-1.2.1
make && sudo make install
cd ..

# Check out and build Etoile stable version

svn co http://svn.gna.org/svn/etoile/trunk/Dependencies Dependencies
svn co http://svn.gna.org/svn/etoile/stable/Etoile Etoile

cd Dependencies/oniguruma5
./configure && make && sudo make install # Build and install Oniguruma first
cd ../..
cd Etoile
make && sudo make install

# Register /usr/local/lib so libonig can be found by OgreKit
echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig

# Workaround install bug (probably related to gnustep-make)
# FIXME: Remove this hack.

ln -s /Library/StepTalk /Local/Library/StepTalk
#ln -s /Library/Grr /Local/Library/Grr

#
# In all the code that follows it's important to take in account it can be run
# multiple times, so we must restore any conf file in its original state before
# applying modifications.
#

# Login panel specific stuff
# NOTE: Keep a copy of original gdm.conf before deleting it to force 
# gdm.conf-custom to be used
cp /etc/gdm/gdm.conf /etc/gdm.conf-original 
rm /etc/gdm/gdm.conf
sed -e '/^Greeter.*$/d' /etc/gdm/gdm.conf-custom
sed -e 's/\(^\[greeter\].*$\)/\1\nGreeter=\/usr\/local\/bin\/etoile_login.sh/' /etc/gdm/gdm.conf-custom
# NOTE: su gdm doesn't work, so we pass the default in GDM greeter script
#su gdm
#defaults write Login ETAllowUserToChooseEnvironment 'NO'
cp Services/Private/Login/etoile_login.sh /usr/local/bin
sed -e '/-ETAllowUserToChooseEnvironment "NO"/d' /usr/local/bin/etoile_login.sh
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
	cp /etc/sudoers /etc/sudoers-original;
else
	cp /etc/sudoers-original /etc/sudoers;
fi
echo '%admin	ALL=(ALL) ALL' >> /etc/sudoers

su $ETOILE_USER_NAME
. /System/Library/Makefiles/GNUstep.sh
./setup.sh

# NOTE: Keep a pristine copy of the defaults to be reset on cleanup
cp /home/$ETOILE_USER_NAME/GNUstep/Defaults/.GNUstepDefaults /home/$ETOILE_USER_NAME/GNUstep/Defaults/.GNUstepDefaults.original

exit

cd .. # Move out of Etoile directory

# Customize boot screens with usplash

apt-get install libusplash-dev # libupsplash-dev requires libc6-dev

cd LiveCD/BootScreen
make && make install
cd..

# Install hidden root directory list and init script (which will be run as root 
# on GDM login)

cd LiveCD
cp hidden /.hidden
cp init.sh /etc/gdm/PostLogin/Default
cd ..

