include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(test), yes)
BUNDLE_NAME = PaneKit
else
FRAMEWORK_NAME = PaneKit
endif

PaneKit_SUBPROJECTS = Source

PaneKit_HEADER_FILES_DIR = Headers

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

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/aggregate.make
include ../../etoile.make
ifeq ($(test), yes)
include $(GNUSTEP_MAKEFILES)/bundle.make
else
include $(GNUSTEP_MAKEFILES)/framework.make
endif

-include GNUmakefile.postamble
