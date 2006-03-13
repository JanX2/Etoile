include $(GNUSTEP_MAKEFILES)/common.make

PACKAGE_NAME = iTerm

ADDITIONAL_OBJCFLAGS = -Wno-import -w

ADDITIONAL_INCLUDE_DIRS = -I./Headers/iTerm -I./Headers

#
# Main application
#
APP_NAME = iTerm
VERSION = 0.1

$(APP_NAME)_PRINCIPAL_CLASS = NSApplication
$(APP_NAME)_APPLICATION_ICON =

# NOTE: Next line mandatory with Linux
$(APP_NAME)_OBJC_LIBS = -lutil 

$(APP_NAME)_LIB_DIRS = -L../$(GNUSTEP_LIBRARIES_ROOT)
$(APP_NAME)_GUI_LIBS = -lAddresses -lAddressView

#$(APP_NAME)_OBJCFLAGS = -I../Frameworks -Wall
#$(APP_NAME)_LDFLAGS = \
#	-L../Frameworks/AddressView/AddressView.framework/Versions/A \
#	-L../Frameworks/Addresses/Addresses.framework/Versions/A     \
#	-lAddressView -lAddresses

#
# Resource files
#
$(APP_NAME)_MAIN_MODEL_FILE = \
	MainMenu.gorm

$(APP_NAME)_RESOURCE_FILES = \
	$(wildcard *.plist) \
	$(filter-out Fonts/CVS, $(wildcard Fonts/*)) \
	$(filter-out images/CVS, $(wildcard images/*.tiff)) \
	$(filter-out *.lproj/CVS, $(wildcard *.lproj/*.gorm)) \
	iTerm.iconheader

# $(filter-out *.lproj/CVS, $(wildcard *.lproj/*.nib)) \
# $(filter-out images/CVS, $(wildcard Images/*.png))
# $(wildcard *.icns)

$(APP_NAME)_LOCALIZED_RESOURCE_FILES =
# $(sort $(notdir $(wildcard *.lproj/*)))

#
# Languages we're localized for
#
$(APP_NAME)_LANGUAGES = \
	English
# $(basename $(wildcard *.lproj))

#
# Class files
#
$(APP_NAME)_OBJC_FILES = \
	$(wildcard *.m)

#
# Header files
#
$(APP_NAME)_HEADER_FILES =

#
# C files
#
$(APP_NAME)_C_FILES =


-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make

-include GNUmakefile.postamble
