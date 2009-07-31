#import "ETOverlayShelf.h"

@implementation ETOverlayShelf

- (void) setUpUI
{
	ETUIItemFactory *itemFactory = [ETUIItemFactory factory];

	[[ETApp mainMenu] addItem: [ETApp arrangeMenuItem]];
	
	/* Set up main item to behave like a very basic compound document editor */

	[self setSize: [[NSScreen mainScreen] frame].size];
	[self setLayout: [ETFreeLayout layout]];

	/* Make self visible by inserting it inside the window layer */

	[[self lastDecoratorItem] setDecoratorItem: [itemFactory transparentFullScreenWindow]];
	
	[self setStyle: [ETTintStyle tintWithStyle: [self style]]];

	/* Insert a bit of everything as content (widgets and shapes) */

	[self addItem: [itemFactory horizontalSlider]];
	[self addItem: [itemFactory textField]];
	[self addItem: [itemFactory labelWithTitle: @"Hello World!"]];
	[self addItem: [itemFactory button]];
	[self addItem: [itemFactory rectangle]];
	[self addItem: [itemFactory oval]];

	/* Give grid-like positions to items initially */

	ETFlowLayout *flow = [ETFlowLayout layout];
	[flow setItemSizeConstraintStyle: ETSizeConstraintStyleNone];
	[(ETFreeLayout *)[self layout] resetItemPersistentFramesWithLayout: flow];
}

- (void) showShelf
{
	[self setVisible: YES];
}

- (void) hideShelf
{
	[self setVisible: NO];
}

- (void) setShelfVisible: (BOOL)show
{
	;
}
@end
