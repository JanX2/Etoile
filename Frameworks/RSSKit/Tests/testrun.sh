#!/bin/sh

# When working on BSD: Run with 'bash testrun.sh', this
# will not work with sh (didn't get ANSI colors to work w/ it) :->

ukrun RSSKitTests.bundle/ 2> /dev/null | sed -e $'s/fail$/\x1b[31m FAIL \x1b[39m/' -e $'s/pass$/\x1b[32m PASS \x1b[39m/'

