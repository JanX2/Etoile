include $(GNUSTEP_MAKEFILES)/common.make

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

BUNDLE_NAME=EtoileMenus

$(BUNDLE_NAME)_OBJC_FILES=$(wildcard *.m)

$(BUNDLE_NAME)_RESOURCE_FILES=\
$(filter-out Resources/CVS, $(wildcard Resources/*)) \
$(filter-out Images/CVS, $(wildcard Images/*.tiff)) \
$(filter-out SyntaxDefinitions/CVS, $(wildcard SyntaxDefinitions/*.syntax))

$(BUNDLE_NAME)_LANGUAGES=$(basename $(wildcard *.lproj))
$(BUNDLE_NAME)_LOCALIZED_RESOURCE_FILES=$(sort $(notdir $(wildcard *.lproj/*)))

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include GNUmakefile.postamble
