PACKAGE_NAME = IconKit

include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME = IconKit
VERSION = 0.2

IconKit_LIBRARIES_DEPEND_UPON += $(GUI_LIBS) $(FND_LIBS) $(OBJC_LIBS) $(SYSTEM_LIBS)

ifeq ($(test), yes)
BUNDLE_NAME = IconKit
IconKit_LDFLAGS += -lUnitKit $(IconKit_LIBRARIES_DEPEND_UPON)
endif

IconKit_RESOURCE_FILES = IconKitInfo.plist GNUstep.icontheme ExtensionMapping.plist

IconKit_HEADER_FILES_DIR = Headers

IconKit_HEADER_FILES = \
        IconKit.h \
        IKCompositorOperation.h \
        IKCompositor.h \
        IKIcon.h \
        IKIconTheme.h \
        IKIconIdentifier.h \
        IKIconPositions.h \
        IKIconProvider.h \
        IKThumbnailProvider.h \
        IKApplicationIconProvider.h \
        IKWorkspaceAdditions.h

IconKit_OBJC_FILES = \
	Source/IKCompositorOperation.m \
	Source/IKCompositor.m \
	Source/IKIcon.m \
	Source/IKIconTheme.m \
	Source/IKIconProvider.m \
	Source/IKApplicationIconProvider.m \
	Source/IKThumbnailProvider.m \
	Source/IKWorkspaceAdditions.m \
	Source/NSFileManager+IconKit.m \
	Source/NSString+MD5Hash.m

ifeq ($(test), yes)
IconKit_OBJC_FILES += Tests/TestIconTheme.m
endif

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif
-include ../../etoile.make
