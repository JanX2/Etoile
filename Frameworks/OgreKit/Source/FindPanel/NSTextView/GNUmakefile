include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = FindPanel_TextView

ADDITIONAL_INCLUDE_DIRS += -I../.. -I../../..
ADDITIONAL_CFLAGS += `onig-config --cflags`
ADDITIONAL_LIB_DIRS += `onig-config --libs`


FindPanel_TextView_OBJC_FILES = \
	OgreTextView.m \
	OgreTextViewMatchFindResult.m \
	OgreTextViewAdapter.m \
	OgreTextViewPlainAdapter.m \
	OgreTextViewFindResult.m \
	OgreTextViewRichAdapter.m \
	OgreTextViewGraphicAllowedAdapter.m \
	OgreTextViewUndoer.m

include $(GNUSTEP_MAKEFILES)/subproject.make
