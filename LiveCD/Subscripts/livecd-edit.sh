#!/bin/sh

# --edit

echo
echo "Entering Edit/Test stage..."

if [ $SUBSCRIPT_DIR/livecd-checkexit.sh -ne 0 ]; then
	return 1;
fi

# Time to time /dev cannot be unmount on --exit
#sudo umount $LIVECD_DIR/edit/proc;
#sudo umount $LIVECD_DIR/edit/dev;

# Import a script that will allows us to exit cleanly later
sudo cp $SUBSCRIPT_DIR/livecd-exit.sh $LIVECD_DIR/edit

# Export network settings of your own configuration to allow network access 
# from chrooted environment
sudo cp /etc/resolv.conf $LIVECD_DIR/edit/etc/
sudo cp /etc/X11/xorg.conf $LIVECD_DIR/edit/etc/X11/

sudo mount -t proc -o bind /proc $LIVECD_DIR/edit/proc;
sudo mount -t dev -o bind /dev $LIVECD_DIR/edit/dev;

echo
echo "To exit the test/edit environment, type:"
echo ". /livecd-exit.sh"
echo

# chroot
if [ $TEST = yes ]; then
	# Here is the hackish part to run commands immediately after chroot
	# If you want to be kept in chroot as it is the case with --edit
	sudo cp $LIVECD_DIR/edit/etc/profile $LIVECD_DIR/edit/etc/profile.original;
	sudo sh -c "echo \"if [ -f /etc/profile.original ]; then\" >> $LIVECD_DIR/edit/etc/profile;"
	sudo sh -c "echo \"export DISPLAY=:0.9\" >> $LIVECD_DIR/edit/etc/profile;"
	sudo sh -c "echo \"/etc/init.d/gdm start\" >> $LIVECD_DIR/edit/etc/profile;"
	sudo sh -c "echo \"fi\" >> $LIVECD_DIR/edit/etc/profile;"
	sudo sh -c "echo >> $LIVECD_DIR/edit/etc/profile;"
	sudo chroot $LIVECD_DIR/edit /bin/bash -l
else
	sudo chroot $LIVECD_DIR/edit
fi

#export HOME=/root
#export LC_ALL=C

