include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = UIServer
VERSION = 0.1

$(TOOL_NAME)_TOOL_LIBS = $(ETOILE_CORE_LIBS) -lpq
$(TOOL_NAME)_INCLUDE_DIRS = -I`pg_config --includedir`
$(TOOL_NAME)_LIB_DIRS = -L`pg_config --libdir`

$(TOOL_NAME)_OBJC_FILES = $(wildcard *.m)

include $(GNUSTEP_MAKEFILES)/tool.make
-include ../../../etoile.make
