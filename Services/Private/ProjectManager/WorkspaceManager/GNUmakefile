ETOILE_CORE_MODULE = YES
include $(GNUSTEP_MAKEFILES)/common.make

DEPENDENCIES = EtoileUI XCBKit XWindowServerKit
APP_NAME = PMWorkspace

$(APP_NAME)_OBJC_FILES = \
	main.m \
	PMWindowTracker.m \
	PMImpermanentView.m \
	PMWorkspaceManager.m \


CC=clang
$(APP_NAME)_PRINCIPAL_CLASS = ETApplication
$(APP_NAME)_GUI_LIBS = -lEtoileUI -lXCBKit -lXWindowServerKit

include $(GNUSTEP_MAKEFILES)/application.make
include ../../../../etoile.make
