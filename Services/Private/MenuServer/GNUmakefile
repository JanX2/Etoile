include $(GNUSTEP_MAKEFILES)/common.make

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

SUBPROJECTS= \
$(wildcard Menulets/*) \
$(wildcard SystemBarEntries/*)

APP_NAME=EtoileMenuServer

$(APP_NAME)_OBJC_FILES=$(wildcard *.m)

$(APP_NAME)_RESOURCE_FILES=\
$(filter-out Resources/CVS, $(wildcard Resources/*)) \
$(filter-out Images/CVS, $(wildcard Images/*.tiff)) \
$(filter-out SyntaxDefinitions/CVS, $(wildcard SyntaxDefinitions/*.syntax))

$(APP_NAME)_LANGUAGES=$(basename $(wildcard *.lproj))
$(APP_NAME)_LOCALIZED_RESOURCE_FILES=$(sort $(notdir $(wildcard *.lproj/*)))

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/application.make
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include GNUmakefile.postamble
