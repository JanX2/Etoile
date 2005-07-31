include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = OgreKit_Source

OgreKit_Source_OBJC_FILES = \
	NSString_OgreKitAdditions.m \
	OGAttributedString.m \
	OGMutableAttributedString.m \
	OGMutablePlainString.m \
	OGPlainString.m \
	OGRegularExpression.m \
	OGRegularExpressionCapture.m \
	OGRegularExpressionCapturePrivate.m \
	OGRegularExpressionEnumerator.m \
	OGRegularExpressionEnumeratorPrivate.m \
	OGRegularExpressionFormatter.m \
	OGRegularExpressionMatch.m \
	OGRegularExpressionMatchPrivate.m \
	OGRegularExpressionPrivate.m \
	OGReplaceExpression.m \
	OGReplaceExpressionPrivate.m \
	OGString.m 

ifeq ($(test), yes)
OgreKit_Source_OBJC_FILES += \
	TestOGRegularExpression.m 
endif

OgreKit_Source_INCLUDE_DIRS += -I.. -I/opt/local/include

-include ../../GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/subproject.make
-include ../../GNUmakefile.postamble
