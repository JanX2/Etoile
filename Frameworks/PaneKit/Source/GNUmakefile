include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = PaneKit
else
LIBRARY_NAME = PaneKit
endif
VERSION = 0.1

PaneKit_OBJC_FILES = \
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
PaneKit_OBJC_FILES += 
endif

PaneKit_HEADER_FILES_DIR = ../Headers

PaneKit_HEADER_FILES_INSTALL_DIR = PaneKit

PaneKit_HEADER_FILES = \
	CocoaCompatibility.h \
	PKMatrixViewPresentation.h \
	PKTableViewPresentation.h \
	PKPlainPresentation.h \
	PKToolbarPresentation.h \
	PKPopUpButtonPresentation.h \
	PKPresentationBuilder.h \
	PKPreferencesController.h \
	PKPreferencePaneRegistry.h \
	PKPreferencePane.h \
	NSPreferencePane.h \
	PKPanesController.h \
	PKPaneRegistry.h \
	PKPane.h \
	PaneKit.h

-include ../GNUmakefile.preamble

ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/library.make
endif

-include ../GNUmakefile.postamble
