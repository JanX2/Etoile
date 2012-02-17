#include <AppKit/AppKit.h>
#include "IDETextView.h"

@interface Controller : NSObject
{
	id window;
	IDETextView* textView;
	NSScrollView* scrollView;

	NSTextStorage* textStorage;

    	SCKSourceCollection* project;
    	SCKSourceFile* sourceFile;
}

@end
