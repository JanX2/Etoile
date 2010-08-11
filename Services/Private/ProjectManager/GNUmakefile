ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

#
# Application
#
VERSION = 0.1
TOOL_NAME = ProjectManager

#
# Resource files
#
$(TOOL_NAME)_LANGUAGES = English

$(TOOL_NAME)_OBJC_FILES = \
	 PMNotifications.m\
	 PMConnectionDelegate.m \
	 PMScreen.m \
	 PMCompositeWindow.m \
	 PMManagedWindow.m \
	 XCBAtomCache.m\
	 XCBConnection.m\
	 XCBNotifications.m\
	 XCBWindow.m\
	 XCBScreen.m\
	 XCBDamage.m \
	 XCBExtension.m \
	 XCBComposite.m \
	 XCBGeometry.m \
	 XCBRender.m \
	 XCBFixes.m \
	 XCBPixmap.m \
	 XCBVisual.m \
	 XCBCachedProperty.m \
	 XCBSelection.m \
	 XCBShape.m \
	 XCBPropertyHelpers.m \
	 ICCCM.m \
	 EWMH.m \
	 main.m

ADDITIONAL_OBJCFLAGS = -std=c99 -g -Wno-unused  -Werror -Wall
ADDITIONAL_INCLUDE_DIRS += -I/usr/X11R6/include
ADDITIONAL_LIB_DIRS += -L/usr/X11R6/lib -lxcb \
	-lxcb-composite -lxcb-damage \
	-lxcb-render-util -lxcb-xfixes \
	-lxcb-shape

include $(GNUSTEP_MAKEFILES)/tool.make
-include ../../../etoile.make
