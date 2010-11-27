include $(GNUSTEP_MAKEFILES)/common.make

CC = clang

TOOL_NAME = etdocgen

$(TOOL_NAME)_OBJCFLAGS += -Wparentheses #-fblocks
$(TOOL_NAME)_TOOL_LIBS = -lEtoileFoundation

$(TOOL_NAME)_OBJC_FILES = $(wildcard *.m)

include $(GNUSTEP_MAKEFILES)/tool.make
-include ../../../etoile.make
