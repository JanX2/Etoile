
include $(GNUSTEP_MAKEFILES)/common.make
#GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

SUBPROJECT_NAME = AZParse

AZParse_OBJC_FILES = \
	parse.m

ADDITIONAL_INCLUDE_DIRS += `pkg-config --cflags glib-2.0` `pkg-config --cflags libxml-2.0` -I..

ADDITIONAL_LIB_DIRS += `pkg-config --libs glib-2.0` `pkg-config --libs libxml-2.0`

include $(GNUSTEP_MAKEFILES)/subproject.make

