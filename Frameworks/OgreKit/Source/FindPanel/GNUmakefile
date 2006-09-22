include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = FindPanel

ADDITIONAL_INCLUDE_DIRS += -I../.. `onig-config --cflags`
ADDITIONAL_CFLAGS += `onig-config --cflags`
ADDITIONAL_LIB_DIRS += `onig-config --libs`

FindPanel_SUBPROJECTS = \
	NSTextView 

FindPanel_OBJC_FILES = \
	OgreFindAllThread.m \
	OgreFindResultBranch.m \
	OgreFindResultLeaf.m \
	OgreFindResultRoot.m \
	OgreFindThread.m \
	OgreHighlightThread.m \
	OgreReplaceAllThread.m \
	OgreReplaceAndFindThread.m \
	OgreTextFindBranch.m \
	OgreTextFindComponentEnumerator.m \
	OgreTextFindLeaf.m \
	OgreTextFindResult.m \
	OgreTextFindReverseComponentEnumerator.m \
	OgreTextFindRoot.m \
	OgreTextFindThread.m \
	OgreTextFinder.m \
	OgreUnhighlightThread.m \
        OgreTextFindProgressSheet.m \
	OgreFindPanel.m \
        OgreFindPanelController.m \
        OgreFindResultWindowController.m

include $(GNUSTEP_MAKEFILES)/subproject.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
