include $(GNUSTEP_MAKEFILES)/common.make

# We reset PROJECT_DIR provided by etoile.make to match the subproject since 
# etoile.make doesn't detect and handle such embedded project
PROJECT_DIR = $(CURDIR)

#
# Library
#
VERSION = 0.1
FRAMEWORK_NAME = SourceCodeKit

${FRAMEWORK_NAME}_OBJC_FILES = \
	SCKCodeCompletionResult.m\
	SCKClangSourceFile.m\
	SCKIntrospection.m\
	SCKSourceCollection.m\
	SCKSourceFile.m\
	SCKSyntaxHighlighter.m\
	SCKTextTypes.m

${FRAMEWORK_NAME}_HEADER_FILES = \
	SourceCodeKit.h\
	SCKCodeCompletionResult.h\
	SCKIntrospection.h\
	SCKSourceCollection.h\
	SCKSourceFile.h\
	SCKSyntaxHighlighter.h\
	SCKTextTypes.h

${FRAMEWORK_NAME}_RESOURCE_FILES = \
	Resources/DefaultArguments.plist

${FRAMEWORK_NAME}_OBJCFLAGS = -fobjc-nonfragile-abi -fblocks -fobjc-arc
${FRAMEWORK_NAME}_CPPFLAGS = -I`llvm-config --src-root`/tools/clang/include/ -DSCKKIT_INTERNAL
${FRAMEWORK_NAME}_LDFLAGS = -L`llvm-config --libdir` -lclang -lstdc++

CC=clang
#CFLAGS += -load=/home/theraven/llvm/Debug+Asserts/lib/libGNUObjCRuntime.so -gnu-objc


include $(GNUSTEP_MAKEFILES)/framework.make
-include ../../etoile.make
#-include ../../documentation.make
