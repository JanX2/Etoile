include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Sandbox

$(APP_NAME)_OBJC_FILES = \
	main.m \
	Controller.m \
	IDETextView.m \
	NoodleLineNumberMarker.m \
	NoodleLineNumberView.m

$(APP_NAME)_PRINCIPAL_CLASS = ETApplication

$(APP_NAME)_MAIN_MODEL_FILE = $(APP_NAME).gorm

$(APP_NAME)_RESOURCE_FILES = $(APP_NAME).gorm

$(APP_NAME)_INCLUDE_DIRS = -I`llvm-config --src-root`/tools/clang/include/ -I`llvm-config --includedir`
$(APP_NAME)_LIB_DIRS = -L`llvm-config --libdir`
$(APP_NAME)_GUI_LIBS += -lSourceCodeKit -lEtoileUI

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make
