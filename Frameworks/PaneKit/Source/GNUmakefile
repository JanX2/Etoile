include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = libPaneKit

libPaneKit_OBJC_FILES = \
	CocoaCompatibility.m \
	NSPreferencePane.m \
	PKPanesController.m \
	PKPreferencesController.m \
	PKPreferencePane.m \
	PKPane.m \
	PKPresentationBuilder.m \
	PKPopUpButtonPresentation.m \
	PKTableViewPresentation.m \
	PKMatrixViewPresentation.m \
	PKMatrixView.m \
	PKToolbarPresentation.m \
	PKPlainPresentation.m \
	PKPreferencePaneRegistry.m \
	PKPaneRegistry.m 

ifeq ($(test), yes)
libPaneKit_OBJC_FILES += 
endif

include $(GNUSTEP_MAKEFILES)/subproject.make

