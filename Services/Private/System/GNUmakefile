include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_OBJCFLAGS = -Wno-import

GNUSTEP_INSTALLATION_DIR = $(GNUSTEP_SYSTEM_ROOT)

# That's not the perfect solution, have to improve this when no admin access is 
# possible. Finally we should install on /usr/bin when a package dependency
# system is used for the deployment.
# From tool.make: FINAL_TOOL_INSTALL_DIR = $(TOOL_INSTALL_DIR)/$(GNUSTEP_TARGET_LDIR)
# FINAL_TOOL_INSTALL_DIR = /usr/local/bin

#
# Main application
#
# TOOL_NAME = EtoileSystem
TOOL_NAME = etoile_system
VERSION = 0.1

#
# Class files
#
$(TOOL_NAME)_OBJC_FILES = $(wildcard *.m)

#
# Resource files
#
$(TOOL_NAME)_RESOURCE_FILES = \
	$(filter-out Resources/CVS, $(wildcard Resources/*)) \
	$(filter-out Images/CVS, $(wildcard Images/*.tiff)) \
	$(filter-out SyntaxDefinitions/CVS, $(wildcard SyntaxDefinitions/*.syntax))

#
# Languages we're localized for
#
$(TOOL_NAME)_LANGUAGES = $(basename $(wildcard *.lproj))
$(TOOL_NAME)_LOCALIZED_RESOURCE_FILES = $(sort $(notdir $(wildcard *.lproj/*)))

#
# C files
#
$(TOOL_NAME)_C_FILES =

-include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
