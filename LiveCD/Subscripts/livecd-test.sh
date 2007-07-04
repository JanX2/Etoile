#sudo update-rc.d -f gdm remove
#sudo update-rc.d -f gdm defaults

#sudo /etc/init.d/networking restart
sudo cp /etc/resolv.conf edit/etc/
sudo cp /etc/X11/xorg.conf edit/etc/X11/
#sudo mount -o loop ubuntu-fs.ext2 edit
sudo mount -t proc -o bind /proc edit/proc
sudo mount -t dev -o bind /dev edit/dev
sudo chroot edit /bin/bash
#mount -t proc none /proc
#mount -t sysfs none /sys
#export HOME=/etc/skel/
#cd /dev/
#MAKEDEV generic
#/etc/init.d/dbus start
#/etc/init.d/gdm start

