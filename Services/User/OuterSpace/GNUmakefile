ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = OuterSpace

OuterSpace_OBJC_FILES = \
	OSTrashNode.m \
	OSTrashCan.m \
	OSTrashCanView.m \
	OSObjectFactory.m \
	OSFolderWindow.m \
	OSShelfCell.m \
	OSShelfView.m \
	OSPathCell.m \
	OSPathView.m \
	OSDistributedCell.m \
	OSDistributedView.m \
	OSApplications.m \
	OSVirtualNode.m \
	OSBundleNode.m \
	OSBitmapImageNode.m \
	OSNode.m \
	Controller.m \
	main.m 

OuterSpace_GUI_LIBS += \
	-lIconKit \
	-lEtoileUI \
	-lXWindowServerKit \
	-lInspectorKit \
	-lPaneKit

OuterSpace_RESOURCE_FILES += \
	OuterSpaceInfo.plist \
	OSRightArrow.tiff \
	TrashCan.tiff

OuterSpace_LANGUAGES = 

OuterSpace_LOCALIZED_RESOURCE_FILES += 

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make
-include GNUmakefile.postamble

