
include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME=ClockMenulet
BUNDLE_EXTENSION=.menulet

$(BUNDLE_NAME)_OBJC_FILES=$(wildcard *.m)
$(BUNDLE_NAME)_RESOURCE_FILES=\
$(filter-out Images/CVS, $(wildcard Images/*)) \
$(filter-out Resources/CVS, $(wildcard Resources/*))

$(BUNDLE_NAME)_LOCALIZED_RESOURCE_FILES=$(sort $(notdir $(wildcard *.lproj/*)))
$(BUNDLE_NAME)_LANGUAGES=$(basename $(wildcard *.lproj))
$(BUNDLE_NAME)_STANDARD_INSTALL=no

ADDITIONAL_OBJCFLAGS += -W -Wall -Wno-unused -Wno-import

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
