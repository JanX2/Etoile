#!/bin/sh

# When working on BSD: Run with 'bash testrun.sh', this
# will not work with sh (didn't get ANSI colors to work w/ it) :->

ukrun RSSKitTests.bundle/ 2> /dev/null | sed -e $'s/Failed/\x1b[31mFAILED\x1b[39m/' -e $'s/Passed/\x1b[32mPASSED\x1b[39m/'

