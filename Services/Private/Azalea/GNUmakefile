
include $(GNUSTEP_MAKEFILES)/common.make
GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

PACKAGE_NAME = Azalea
VERSION = 0.1

# The application to be compiled
APP_NAME = Azalea 
Azalea_PRINCIPAL_CLASS = WMApplication
Azalea_APPLICATION_ICON = Desktop.tiff
Azalea_SUBPROJECTS = WINGs

Azalea_HAS_RESOURCE_BUNDLE = yes

Azalea_RESOURCE_FILES = \
    Resources/Images/* 

Azalea_LANGUAGES = 

Azalea_OBJC_FILES = \
	main.m \
	WMApplication.m \
	WMApplication+Event.m \
	WMDefaults.m \
	WMDialogController.m \
	WMWindowInspector.m \
	WMDockedAppPanel.m \
	actions.m \
	appicon.m \
	application.m \
	appmenu.m \
	balloon.m \
	client.m \
	colormap.m \
	cycling.m \
	defaults.m \
	dock.m \
	event.m \
	framewin.m \
	geomview.m \
	icon.m \
	menu.m \
	misc.m \
	monitor.m \
	motif.m \
	moveres.m \
	openlook.m \
	pixmap.m \
	placement.m \
	properties.m \
	resources.m \
	rootmenu.m \
	screen.m \
	session.m \
	shutdown.m \
	stacking.m \
	startup.m \
	superfluous.m \
	switchmenu.m \
	switchpanel.m \
	texture.m \
	xdnd.m \
	xinerama.m \
	xmodifier.m \
	xutil.m \
	wcore.m \
	wdefaults.m \
	wevent.m \
	window.m \
	wmspec.m \
	winmenu.m \
	workspace.m \
	wsound.m 

ADDITIONAL_INCLUDE_DIRS += -I/usr/local/include -I/usr/X11R6/include
ADDITIONAL_INCLUDE_DIRS += `freetype-config --cflags` -DRESOURCE_PATH=\"./\"

ADDITIONAL_LIB_DIRS += -L/usr/local/lib -L/usr/X11R6/lib

ADDITIONAL_GUI_LIBS += -ltiff -lXpm -lpng -lz -ljpeg -lungif -lXft

ADDITIONAL_GUI_LIBS += -lwraster
ADDITIONAL_GUI_LIBS += `freetype-config --libs`
ADDITIONAL_GUI_LIBS += -lXext -lX11 -ldl

-include GNUmakefile.preamble

-include GNUmakefile.local

include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make

-include GNUmakefile.postamble

