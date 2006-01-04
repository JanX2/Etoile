#ifndef __PreferencesKit_PKMatrixView__
#define __PreferencesKit_PKMatrixView__

#include <AppKit/AppKit.h>

@interface PKMatrixView: NSControl
{
	NSMatrix *matrix;
	NSScrollView *scrollView;
	NSView *contentView;
	int count;
}

- (id) initWithFrame: (NSRect) rect
       numberOfButtons: (int) count;

- (NSSize) frameSizeForContentSize: (NSSize) size;
- (void) addButtonCell: (NSButtonCell *) cell;
- (NSButtonCell *) selectedButtonCell;

/* The view below matrix */
- (NSView *) contentView;

@end

#endif /* __PreferencesKit_PKMatrixView__ */
