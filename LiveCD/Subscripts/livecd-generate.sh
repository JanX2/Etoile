#!/bin/sh

# --generate

if [ -f $LIVECD_DIR/edit/etc/profile.original ]; then
	echo
	echo "LiveCD filesystem is in --test mode, you must first source "
	echo "livecd-exit.sh in the test shell to exit properly"
	echo
	return
fi

echo
echo "WARNING: You are entering Generate stage and you will be asked to type a
echo "name to identify the LiveCD in boot menu... You just have to be patient"
echo

cd $LIVECD_DIR

# Regenerate manifest

chmod +w extract-cd/casper/filesystem.manifest
sudo chroot edit dpkg-query -W --showformat='${Package} ${Version}\n' > extract-cd/casper/filesystem.manifest
sudo cp extract-cd/casper/filesystem.manifest extract-cd/casper/filesystem.manifest-desktop
sudo sed -ie '/ubiquity/d' extract-cd/casper/filesystem.manifest-desktop

# Recompress the livecd filesystem now customized

sudo rm extract-cd/casper/filesystem.squashfs
sudo mksquashfs edit extract-cd/casper/filesystem.squashfs

# Give a lengthy name that will be used in boot screens to the new livecd 

echo
echo "WARNING: Type a lengthy name that will be used in boot menu to identify
echo "the operating system on the LiveCD, then exits the editor..."
echo

sudo pico extract-cd/README.diskdefines

# Remove old md5sum.txt and calculate new md5 sums

sudo -s
rm extract-cd/md5sum.txt
(cd extract-cd && find . -type f -print0 | xargs -0 md5sum > md5sum.txt)
exit

# Create Iso

cd extract-cd
sudo mkisofs -r -V "$ETOILE_LIVECD_NAME" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o $LIVECD_DIR/$ETOILE_IMAGE_NAME .

echo
echo "Finished to generate new Etoile LiveCD image :-)"
ls -l $LIVECD_DIR/$ETOILE_IMAGE_NAME
echo

