
include $(GNUSTEP_MAKEFILES)/common.make
#GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

SUBPROJECT_NAME = AZRender

AZRender_OBJC_FILES = \
	color.m \
	font.m \
	gradient.m \
	image.m \
	instance.m \
	mask.m \
	render.m \
	theme.m

ADDITIONAL_INCLUDE_DIRS += `pkg-config --cflags glib-2.0` `pkg-config --cflags freetype2` `pkg-config --cflags libxml-2.0` -I.. -I/usr/X11R6/include

ADDITIONAL_LIB_DIRS += `pkg-config --libs glib-2.0` `pkg-config --libs freetype2` `pkg-config --libs libxml-2.0`

include $(GNUSTEP_MAKEFILES)/subproject.make

