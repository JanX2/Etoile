include $(GNUSTEP_MAKEFILES)/common.make

CC = clang

TOOL_NAME = etdocgen

$(TOOL_NAME)_CPPFLAGS += -DWITH_CGRAPH=1  
$(TOOL_NAME)_OBJCFLAGS += -fobjc-arc -Wparentheses `pkg-config libcgraph --cflags` `pkg-config libgvc --cflags` 
$(TOOL_NAME)_TOOL_LIBS = -lEtoileFoundation -lSourceCodeKit `pkg-config libcgraph --libs` `pkg-config libgvc --libs`

# For SourceCodeKit dependencies
$(TOOL_NAME)_CPPFLAGS += -I`llvm-config --src-root`/tools/clang/include/ -I`llvm-config --includedir`
$(TOOL_NAME)_TOOL_LIBS += -lgnustep-gui
$(TOOL_NAME)_LDFLAGS += -L`llvm-config --libdir`

$(TOOL_NAME)_OBJC_FILES = $(wildcard *.m)

include $(GNUSTEP_MAKEFILES)/tool.make
-include ../../../etoile.make
-include ../../../documentation.make
