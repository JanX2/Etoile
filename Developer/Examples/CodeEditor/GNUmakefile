include $(GNUSTEP_MAKEFILES)/common.make

DEPENDENCIES = OgreKit

APP_NAME = SimpleCodeEditor

SimpleCodeEditor_OBJC_FILES = \
	main.m \
	Controller.m \
	TWTextView.m \
	TWDocument.m \
	TWCharacterPanel.m

SimpleCodeEditor_GUI_LIBS += -lOgreKit -lScriptKit -lIDEKit

SimpleCodeEditor_LANGUAGES = \
	English

SimpleCodeEditor_LOCALIZED_RESOURCE_FILES = \
	MainMenu.gorm \
	Document.gorm \
	CharacterPanel.gorm

SimpleCodeEditor_RESOURCE_FILES = \
	Resources/Document-Text.tiff \
	Resources/Document-RichText.tiff \
	Resources/SimpleCodeEditor.tiff

SimpleCodeEditor_MAIN_MODEL_FILE = MainMenu.gorm

include $(GNUSTEP_MAKEFILES)/application.make
-include ../../../etoile.make
