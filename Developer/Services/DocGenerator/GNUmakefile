include $(GNUSTEP_MAKEFILES)/common.make

CC = clang

TOOL_NAME = etdocgen

$(TOOL_NAME)_CPPFLAGS += -DWITH_CGRAPH=1  
$(TOOL_NAME)_OBJCFLAGS += -Wparentheses `pkg-config libcgraph --cflags` `pkg-config libgvc --cflags` 
$(TOOL_NAME)_TOOL_LIBS = -lEtoileFoundation `pkg-config libcgraph --libs` `pkg-config libgvc --libs`

$(TOOL_NAME)_OBJC_FILES = $(wildcard *.m)

include $(GNUSTEP_MAKEFILES)/tool.make
-include ../../../etoile.make
-include ../../../documentation.make
