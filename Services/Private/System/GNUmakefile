ETOILE_CORE_MODULE = YES

include $(GNUSTEP_MAKEFILES)/common.make

ADDITIONAL_CPPFLAGS += -DDBUS_API_SUBJECT_TO_CHANGE=1
ADDITIONAL_INCLUDE_DIRS += `pkg-config --cflags dbus-1`

SUBPROJECTS = WorkspaceCommKit

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

# FIXME: When you take in account System can be use without any graphical UI 
# loaded, linking AppKit by default is bad.
$(TOOL_NAME)_TOOL_LIBS = -lEtoileFoundation -lgnustep-gui `pkg-config --libs dbus-1`

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
include $(GNUSTEP_MAKEFILES)/aggregate.make
-include ../../../etoile.make
include $(GNUSTEP_MAKEFILES)/tool.make
-include GNUmakefile.postamble
