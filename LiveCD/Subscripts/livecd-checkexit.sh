#!/bin/sh

if [ -f $LIVECD_DIR/edit/etc/profile.original ]; then
	echo
	echo "LiveCD filesystem is in --test mode, you must first source "
	echo "livecd-exit.sh in the test shell to exit properly"
	echo
	return 1;
fi

return 0;
