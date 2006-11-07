#
#    Makefile for Etoile DistributedViewExample
#

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

ADDITIONAL_INCLUDE_DIRS = \
	-I$(GNUSTEP_SYSTEM_ROOT)/Library/Headers/

PACKAGE_NAME = DistributedViewExample

#
# Main application
#	
APP_NAME = DistributedViewExample
VERSION = 0.1

DistributedViewExample_PRINCIPAL_CLASS = NSApplication
DistributedViewExample_APPLICATION_ICON =

DistributedViewExample_GUI_LIBS = -lEtoileUI -lDistributedView

#
# Resource files
#
DistributedViewExample_MAIN_MODEL_FILE = MainMenu.gorm
DistributedViewExample_RESOURCE_FILES = \
	DistributedViewExampleInfo.plist \
	MainMenu.gorm \
	LadyJayeIcon.tiff \
	MediDoc.tiff \
	MimiRogersIcon.tiff

DistributedViewExample_LOCALIZED_RESOURCE_FILES=

#
# Languages we're localized for
#
DistributedViewExample_LANGUAGES = \
	English

#
# Header files
#
DistributedViewExample_HEADER_FILES_DIR = .

DistributedViewExample_HEADERS = \
	MyDataSource.h \
	MyDistViewItem.h

#
# Class files
#
DistributedViewExample_OBJC_FILES = \
	MyDataSource.m \
	MyDistViewItem.m \
	main.m

#
# C files
#
DistributedViewExample_C_FILES =

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble
