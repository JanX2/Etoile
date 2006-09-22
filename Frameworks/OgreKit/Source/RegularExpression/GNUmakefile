include $(GNUSTEP_MAKEFILES)/common.make

SUBPROJECT_NAME = RegularExpression

ADDITIONAL_INCLUDE_DIRS += -I../.. `onig-config --cflags`
ADDITIONAL_CFLAGS += `onig-config --cflags`
ADDITIONAL_LIB_DIRS += `onig-config --libs`

RegularExpression_OBJC_FILES = \
	NSString_OgreKitAdditions.m \
	OGRegularExpressionEnumeratorPrivate.m \
	OGAttributedString.m \
	OGRegularExpressionFormatter.m \
	OGMutableAttributedString.m \
	OGMutablePlainString.m \
	OGRegularExpressionMatch.m \
	OGRegularExpressionMatchPrivate.m \
	OGPlainString.m \
	OGRegularExpressionPrivate.m \
	OGRegularExpression.m \
	OGReplaceExpression.m \
	OGRegularExpressionCapture.m \
	OGReplaceExpressionPrivate.m \
	OGRegularExpressionCapturePrivate.m \
	OGString.m \
	OGRegularExpressionEnumerator.m

ifeq ($(test), yes)
RegularExpression_OBJC_FILES += \
	TestOGRegularExpression.m
endif

include $(GNUSTEP_MAKEFILES)/subproject.make
