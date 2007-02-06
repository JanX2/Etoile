ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

BUNDLE_NAME = EtoileBehavior

$(BUNDLE_NAME)_OBJC_FILES=$(wildcard *.m)

$(BUNDLE_NAME)_RESOURCE_FILES=\
$(filter-out Resources/CVS, $(wildcard Resources/*)) \
$(filter-out Images/CVS, $(wildcard Images/*.tiff)) \
$(filter-out SyntaxDefinitions/CVS, $(wildcard SyntaxDefinitions/*.syntax))

$(BUNDLE_NAME)_LANGUAGES=$(basename $(wildcard *.lproj))
$(BUNDLE_NAME)_LOCALIZED_RESOURCE_FILES=$(sort $(notdir $(wildcard *.lproj/*)))

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/bundle.make
-include ../../etoile.make
-include GNUmakefile.postamble

