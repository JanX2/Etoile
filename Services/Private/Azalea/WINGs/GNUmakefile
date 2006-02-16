include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = WINGs

WINGs_C_FILES = \
	array.c \
	bagtree.c \
	configuration.c \
	data.c \
	dragcommon.c \
	dragdestination.c \
	dragsource.c \
	error.c \
	findfile.c \
	handlers.c \
	hashtable.c \
	memory.c \
	misc.c \
	notification.c \
	proplist.c \
	selection.c \
	snprintf.c \
	string.c \
	usleep.c \
	wapplication.c \
	wappresource.c \
	wballoon.c \
	wbox.c \
	wbutton.c \
	wcolor.c \
	wframe.c \
	wfont.c \
	widgets.c \
	winputmethod.c \
	wlabel.c \
	wmenuitem.c \
	wmisc.c \
	wpanel.c \
	wpixmap.c \
	wpopupbutton.c \
	wtextfield.c \
	wview.c \
	wwindow.c

WINGs_INCLUDE_DIRS += `freetype-config --cflags` -DRESOURCE_PATH=\"./\"
WINGs_LDFLAGS = -L/usr/lib -lc `freetype-config --libs`

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include GNUmakefile.postamble

