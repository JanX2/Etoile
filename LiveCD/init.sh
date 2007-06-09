#!/bin/sh

# Make sure dhcp is properly started because it isn't always true with Feisty
/etc/init.d/networking restart

# Start HAL

# Register /usr/local/lib so libonig can be found by OgreKit
# Already set up in /etc/ld.so.conf on livecd creation
#export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
