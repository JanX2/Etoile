#!/bin/sh

#
# Switches Addresses.framework to use giesler.no-ip.org over the network,
# or back again. Be gentle to my server, it's behind a DSL line...
#

MODE=$1

case "$MODE" in
	--on-ro)
		defaults write Addresses AddressBooks \
			'({ Class = Remote; Host = giesler.no-ip.org; Password = gnustep; })'
		;;

	--on-rw)
		defaults write Addresses AddressBooks \
			'({ Class = Remote; Host = giesler.no-ip.org; Password = gunstop; })'
		;;

	--off)
		defaults delete Addresses AddressBooks
		;;

	*)
		echo "Usage: $0 --on-ro|--on-rw|--off"
		echo "          --on-{ro,rw}: Use giesler.biz's addressbook as primary"
		echo "          --off: Use local addressbook as primary"
		;;

esac
		

