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

# Workaround install bug (probably related to gnustep-make)
# FIXME: Remove this hack.

ln -s /Library/StepTalk /Local/Library/StepTalk
#ln -s /Library/Grr /Local/Library/Grr

# Add a new user named 'etoile' and set up Etoile environment
# NOTE: This is the only part where user interaction is necessary

adduser $ETOILE_USER_NAME
adduser $ETOILE_USER_NAME admin # Add 'etoile' user to sudoers
su $ETOILE_USER_NAME
. /System/Library/Makefiles/GNUstep.sh
./setup.sh

# NOTE: Keep a pristine copy of the defaults to be reset on cleanup
cp /home/$ETOILE_USER_NAME/GNUstep/Defaults/.GNUstepDefaults /home/$ETOILE_USER_NAME/GNUstep/Defaults/.GNUstepDefaults.original

# Register /usr/local/lib so libonig can be found by OgreKit
echo "/usr/local/lib" >> /etc/ld.so.conf
ldconfig

exit

# TODO: Take care of Login.app specific set up

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

