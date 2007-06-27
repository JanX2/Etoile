PACKAGE = DistributedView

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

#
# Main application
#
FRAMEWORK_NAME = DistributedView
VERSION = 0.1
LIBRARIES_DEPEND_UPON = -lEtoileUI

# For FreeBSD at least
LIBRARIES_DEPEND_UPON += -lm

#
# Resource files
#
DistributedView_MAIN_MODEL_FILE =

DistributedView_RESOURCE_FILES =

DistributedView_LOCALIZED_RESOURCE_FILES =

#
# Languages we're localized for
#
DistributedView_LANGUAGES = \
	English
	
#
# Class files
#
DistributedView_OBJC_FILES = \
	UKDistributedView.m \
	UKFinderIconCell.m

#
# Header files to be installed
#
DistributedView_HEADER_FILES_DIR = ./

DistributedView_HEADER_FILES = \
	EtoileCompatibility.h \
	UKDistributedView.h \
	UKFinderIconCell.h
	
#
# C files
#
DistributedView_C_FILES =

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../etoile.make
include $(GNUSTEP_MAKEFILES)/framework.make

-include GNUmakefile.postamble
