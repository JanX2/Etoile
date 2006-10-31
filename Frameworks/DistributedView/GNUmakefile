PACKAGE = DistributedView

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

#
# Main application
#
LIBRARY_NAME = libDistributedView
VERSION = 0.1
LIBRARIES_DEPEND_UPON = -lEtoileUI

# For FreeBSD at least
LIBRARIES_DEPEND_UPON += -lm

#
# Resource files
#
$(LIBRARY_NAME)_MAIN_MODEL_FILE =

$(LIBRARY_NAME)_RESOURCE_FILES =

$(LIBRARY_NAME)_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
$(LIBRARY_NAME)_LANGUAGES = \
	English
	
#
# Class files
#
$(LIBRARY_NAME)_OBJC_FILES = \
	UKDistributedView.m \
	UKFinderIconCell.m

#
# Header files to be installed
#
$(LIBRARY_NAME)_HEADER_FILES_DIR = ./

$(LIBRARY_NAME)_HEADER_FILES_INSTALL_DIR = /DistributedView

$(LIBRARY_NAME)_HEADER_FILES = \
	Cocoa.h \
	EtoileCompatibility.h \
	UKDistributedView.h \
	UKFinderIconCell.h
	
#
# C files
#
$(LIBRARY_NAME)_C_FILES =

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/library.make
include ../../etoile.make

-include GNUmakefile.postamble
