#!/bin/sh

# Be sure you test it, especially the path.
. /usr/local/GNUstep/System/Library/Makefiles/GNUstep.sh
openapp /usr/local/GNUstep/System/Applications/Login.app -GSAppKitUserBundles "("/usr/local/GNUstep/Local/Library/Bundles/Camaelon.themeEngine")"

