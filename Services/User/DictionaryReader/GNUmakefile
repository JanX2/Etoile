
include $(GNUSTEP_MAKEFILES)/common.make

ifeq ($(warnings), yes)
ADDITIONAL_OBJCFLAGS += -W
ADDITIONAL_OBJCPPFLAGS += -W
ADDITIONAL_CFLAGS += -W
ADDITIONAL_CPPFLAGS += -W
endif
ifeq ($(allwarnings), yes)
ADDITIONAL_OBJCFLAGS += -Wall
ADDITIONAL_OBJCPPFLAGS += -Wall
ADDITIONAL_CFLAGS += -Wall
ADDITIONAL_CPPFLAGS += -Wall
endif

APP_NAME = DictionaryReader

DictionaryReader_OBJC_FILES = AppController.m \
StreamLineWriter.m \
StreamLineReader.m \
DictConnection.m \
HistoryManager.m \
NSString+Convenience.m \
NSString+Clickable.m \
main.m \

DictionaryReader_OBJCC_FILES = 
DictionaryReader_C_FILES = 
DictionaryReader_RESOURCE_FILES = Resources/dict.png \

DictionaryReader_LANGUAGES = English \

DictionaryReader_LOCALIZED_RESOURCE_FILES = DictionaryReader.gorm \

DictionaryReader_MAIN_MODEL_FILE = DictionaryReader.gorm

DictionaryReader_PRINCIPAL_CLASS = 

ADDITIONAL_GUI_LIBS = 
SUBPROJECTS = 
-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble
