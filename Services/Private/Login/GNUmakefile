ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

APP_NAME = Login

Login_OBJC_FILES = \
	main.m \
	NSFileHandle+line.m \
	GDMClient.m \
	Controller.m \
	Background.m

Login_LANGUAGES = English

Login_RESOURCE_FILES = \
	login-images/*.png \
	login-images/*.jpg

Login_LOCALIZED_RESOURCE_FILES = login.gorm

Login_MAIN_MODEL_FILE = login.gorm

include $(GNUSTEP_MAKEFILES)/application.make
include ../../../etoile.make
