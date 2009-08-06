#import "ETOverlayShelf.h"

@implementation ETOverlayShelf

- (void) setUpUI
{
	ETUIItemFactory *itemFactory = [ETUIItemFactory factory];

	/* Set up main item to behave like a very basic compound document editor */

	[self setSize: [[NSScreen mainScreen] frame].size];
	[self setLayout: [ETFlowLayout layout]];

	/* Make self visible by inserting it inside the window layer */

	[[self lastDecoratorItem] setDecoratorItem: [itemFactory transparentFullScreenWindow]];
	
	[self setStyle: [ETTintStyle tintWithStyle: [self style]]];

	/* Insert a bit of everything as content (widgets and shapes) */

	[self addItem: [itemFactory horizontalSlider]];
	[self addItem: [itemFactory textField]];
	[self addItem: [itemFactory labelWithTitle: @"Hello World!"]];
	[self addItem: [itemFactory buttonWithTitle: @"Hide shelf" target: self action: @selector(hideShelf:)]];
	[self addItem: [itemFactory rectangle]];
	[self addItem: [itemFactory oval]];
}

- (void) showShelf: (id)sender
{
	[self setVisible: YES];
}

- (void) hideShelf: (id)sender
{
	NSLog(@"Hide shelf");
	[self setVisible: NO];
	//FIXME: This doesn't work. Fix ETWindowItem to observe the visible property of the first decorated item,
	// and hide/show the window based on that.
}

- (void) setShelfVisible: (BOOL)show
{
	;
}
@end
