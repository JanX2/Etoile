
# For example ~/live
$LIVECD_DIR=/home/qmathe/live

# For example ~/Desktop/ubuntu-6.06.1-desktop-i386.iso
$UBUNTU_IMAGE=/home/qmathe/live/ubuntu-7.04-desktop-i386.iso
$UBUNTU_IMAGE_NAME=/home/qmathe/live/ubuntu-7.04-desktop-i386.iso

$ETOILE_LIVECD_NAME="Etoile LiveCD 0.2"
$ETOILE_IMAGE_NAME=etoile.iso

$ETOILE_USER_NAME=guest

#
# --prepare
#

# Set up Squashfs

sudo apt-get install squashfs-tools
sudo modprobe squashfs

# Move existing livecd image into work directory

mkdir $LIVECD_DIR
mv $UBUNTU_IMAGE $LIVECD_DIR
cd $LIVECD_DIR

# Mount the existing image

mkdir mnt
sudo mount -o loop $UBUNTU_IMAGE_NAME mnt

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

# --customize

mkdir build
cd build

# Install Etoile and GNUstep dependencies

# NOTE: Not including openssl, this means no SSL support built by GNUstep
sudo apt-get -y install gobjc-4.1 openssl libxml2-dev libxslt1-dev libffi4-dev libjpeg62-dev libtiff4-dev libpng12-dev libungif4-dev libfreetype6-dev libx11-dev libart-2.0-dev libxft-dev libxmu-dev libxss-dev xscreensaver libdbus-1-dev libstartup-notification0-dev g++ libpoppler-dev

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

# --cleanup

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

# Try to clean up as much GNOME stuff as possible

# NOTE: Trick to enable universe repository install deborphan that allows to purge which got removed without --purge
#cp /etc/apt/sources.list /etc/apt/sources.list.backup
#sudo sed -i -e "s/# deb/deb/g" /etc/apt/sources.list

# NOTE: 'dpkg -l' reports them but 'apt-get remove' cannot find them
# app-install-data* before-light

# FIXME: compiz* removes too many stuff like objc compiler
# fstobdf
# ^gconf* removes gdm
# ^gij* matches way too many things
# ^gnome* removes gdm
# ^languages-pack-gnome-*
# ^libdb4*
# ^libgcj*
# ^libgconf* ^libgda*
# ^libgdbm* ^libgdi* 
# ^libmagick*
# ^libnewt*
# ^liborbit* removes gconf
# ^libpango* removes gdm
# ^libpq* ^libpt* 
# ^libsasl* removes gconf and gdm
# ^libselinux* ^libpi* libtext-charwidth-perl libtext-wrapi18n-perl ^libxaw* removes xorg
# ^libslab* ^libslang* ^libslp* creates conflicts with ubiquity and/or font-config
# ^python* removes gdm and gconf and probably too many things
# gksu ^libgksu* ^libcroco* ^libglade*  ^libgnome* ^libgtop* removes gdm
#^libbrlapi* ^libatk1*
#^gtk2* ^libgtk*

apt-get remove alacarte apport-gtk at-spi ^brltty* bug-buddy capplets-data cli-common contact-lookup-applet deskbar-applet desktop-effects diveintopython docbook-xml ekiga eog evince ^evolution* f-spot file-roller ^gaim* gcalctool gcc-3.3-base ^gedit* gimp gparted gstreamer0.10-gnomevfs ^gtkhtml* ^guile* hwdb-client-gnome ^language-pack-* libapr1 ^libatspi* ^libaudio* ^libaudiofile* ^libbeagle* ^libbonobo* ^libcamel* ^libdjvulibre* ^libebook* ^libecal* ^libedata* ^libeel* ^libegroupwise* ^libexchange-storage* ^libgadu* ^libgail* ^libgamin* ^libgimp*  libglib-perl libglib2.0-cil libgmime2.2-cil  ^libgucharmap* ^libguile* libhsqldb-java ^libhtml* ^libjaxp* libjline-java ^liblaunchpad-integration* ^liblircclient* ^liblpint-bonobo* ^libmetacity* ^libmono* ^libnautilus* libnet-dbus-perl ^libnm-glib* ^libnspr* ^libopal*  ^libparted* ^libperl*  libpoppler1-glib ^libqthreads*  ^libscrollkeeper* ^libsdl* libservlet2.3-java ^libsexy* ^libsigc++* ^libsoup* ^libtotem-plparser* ^libuniconf* liburi-perl libvisual* ^libvte* ^libwmf* ^libwnck* ^libwpd8c2a ^libwps* ^libwvstreams* libwww-perl libxalan2-java  libxerces2-java libxml-parser-perl libxml-twig-perl ^libxplc* ^metacity* ^mono-* mscompress ^nautilus* ^network-manager* ^openoffice.org* rdesktop rhythmbox scim-gtk2-immodule scrollkeeper serpentine software-properties-gtk sound-juicer ssh-askpass-gnome thunderbird-locale-en-gb tomboy totem tsclient ^update-manager* update-notifier vino w3m yelp

deborphan | xargs apt-get remove --purge -y # deborphan --guess-all
dpkg --list | grep ^rc | awk '{print $2}'
... et pour les purger :
# COLUMNS=300 dpkg --list | grep ^rc | awk '{print $2}' | xargs dpkg -P

# To be sure some critical packages haven't been removed during the last step
apt-get -y install locales ssh firefox #language-pack-en-base

apt-get check

#ubiquity

# --build

# Regenerate manifest

chmod +w extract-cd/casper/filesystem.manifest
sudo chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract-cd/casper/filesystem.manifest
sudo cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
sudo sed -ie '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop

# Recompress the livecd filesystem now customized

sudo rm extract-cd/casper/filesystem.squashfs
sudo mksquashfs edit extract-cd/casper/filesystem.squashfs

# Give a lengthy name that will be used in boot screens to the new livecd 

sudo pico extract-cd/README.diskdefines

# Remove old md5sum.txt and calculate new md5 sums

sudo -s
rm extract-cd/md5sum.txt
(cd extract-cd && find . -type f -print0 | xargs -0 md5sum > md5sum.txt)
exit

# Create Iso

cd extract-cd
sudo mkisofs -r -V "$ETOILE_LIVECD_NAME" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../$ETOILE_IMAGE_NAME .


