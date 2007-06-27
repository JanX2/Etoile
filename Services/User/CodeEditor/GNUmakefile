include $(GNUSTEP_MAKEFILES)/common.make

DEPENDENCIES = OgreKit PaneKit

APP_NAME = CodeEditor

CodeEditor_OBJC_FILES = \
	ViewPreferencePane.m \
	FontPreferencePane.m \
	SyntaxHandler.m \
	CommentHandler.m \
	CodeParser.m \
	SyntaxManager.m \
	CETabView.m \
	CEWindow.m \
	CELineNumberView.m \
	CETextView.m \
	Controller.m \
	main.m 

CodeEditor_INCLUDE_DIRS += `onig-config --cflags`
CodeEditor_GUI_LIBS += -lOgreKit -lPaneKit
CodeEditor_RESOURCE_FILES = \
	Syntax/*.plist

CodeEditor_LANGUAGES = \
	English

ifeq ($(FOUNDATION_LIB), apple)
CodeEditor_LOCALIZED_RESOURCE_FILES = \
	ViewPreferencePane.nib \
	FontPreferencePane.nib \
	MainMenu.nib

CodeEditor_MAIN_MODEL_FILE = MainMenu.nib
else
CodeEditor_LOCALIZED_RESOURCE_FILES = \
	ViewPreferencePane.gorm \
	FontPreferencePane.gorm \
	MainMenu.gorm 

CodeEditor_MAIN_MODEL_FILE = MainMenu.gorm
endif

include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../../etoile.make
-include GNUmakefile.postamble

