#include "CLBoxCompositor.h"

@implementation CLBoxCompositor

- (void) error: (NSString*) msg
{
	[super error: nil];
	NSLog (@"from CLBoxCompositor, %@ missing", msg);
	exit (-2);
}

- (void) setFill: (CLFill) filling { fillType = filling; }
- (void) setFillColor: (NSColor*) color { ASSIGN (colorFill, color); }

- (void) getCorners
{
	NSImage* corners = [images objectForKey: @"corners"];
	NSSize cSize = [corners size];
	NSImage* topLeft = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* topRight = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* bottomLeft = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* bottomRight = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];

	[topLeft lockFocus];
	[corners compositeToPoint: NSMakePoint (0,-cSize.height/2) operation: NSCompositeSourceOver];
	[topLeft unlockFocus];

	[topRight lockFocus];
	[corners compositeToPoint: NSMakePoint (-cSize.width/2,-cSize.height/2) operation: NSCompositeSourceOver];
	[topRight unlockFocus];

	[bottomLeft lockFocus];
	[corners compositeToPoint: NSMakePoint (0,0) operation: NSCompositeSourceOver];
	[bottomLeft unlockFocus];

	[bottomRight lockFocus];
	[corners compositeToPoint: NSMakePoint (-cSize.width/2,0) operation: NSCompositeSourceOver];
	[bottomRight unlockFocus];

	[images setObject: topLeft forKey: @"topLeft"];
	[images setObject: topRight forKey: @"topRight"];
	[images setObject: bottomLeft forKey: @"bottomLeft"];
	[images setObject: bottomRight forKey: @"bottomRight"];

	[topLeft release];
	[topRight release];
	[bottomLeft release];
	[bottomRight release];
}

- (void) getTopBottom
{
	NSImage* topbottom = [images objectForKey: @"topbottom"];
	NSSize tbSize = [topbottom size];
	NSImage* top = [[NSImage alloc] initWithSize: NSMakeSize (tbSize.width,tbSize.height/2)];
	NSImage* bottom = [[NSImage alloc] initWithSize: NSMakeSize (tbSize.width,tbSize.height/2)];

	[top lockFocus];
	[topbottom compositeToPoint: NSMakePoint (0,-tbSize.height/2) operation: NSCompositeSourceOver];
	[top unlockFocus];

	[bottom lockFocus];
	[topbottom compositeToPoint: NSMakePoint (0,0) operation: NSCompositeSourceOver];
	[bottom unlockFocus];

	[images setObject: top forKey: @"top"];
	[images setObject: bottom forKey: @"bottom"];

	[top release];
	[bottom release];
}

- (float) topHeight { return topHeight; }
- (float) bottomHeight { return bottomHeight; }

- (void) drawInRect: (NSRect) rect
{
	/* 
		A Box is a quite complex rendering... it is composed of 9 parts:

		TopLeft-------Top------TopRight
		 |             |             |
		Left---------fill---------Right
		 |             |             |
		BottomLeft--Bottom--BottomRight
	
		
		TopLeft, TopRight, BottomLeft, BottomRight are the corners -- simple images.
		Left, Right, Top, Bottom are repeated images, either horizontally or vertically.
		Fill is either an image, tiled or scaled, or a color.
	*/

	NSImage* left = [images objectForKey: @"left"];
	NSImage* right = [images objectForKey: @"right"];
	NSImage* top = [images objectForKey: @"top"];
	NSImage* bottom = [images objectForKey: @"bottom"];

	NSImage* topLeft = [images objectForKey: @"topLeft"];
	NSImage* topRight = [images objectForKey: @"topRight"];
	NSImage* bottomLeft = [images objectForKey: @"bottomLeft"];
	NSImage* bottomRight = [images objectForKey: @"bottomRight"];

	NSImage* fill = [images objectForKey: @"fill"];

	// In case we don't have the corners, we try to generate them using a corners image

	if ((topLeft == nil) || (topRight == nil) || (bottomLeft == nil) || (bottomRight == nil))
	{
		[self getCorners];
		topLeft = [images objectForKey: @"topLeft"];
		topRight = [images objectForKey: @"topRight"];
		bottomLeft = [images objectForKey: @"bottomLeft"];
		bottomRight = [images objectForKey: @"bottomRight"];
	}

	if ((top == nil) || (bottom == nil))
	{
		[self getTopBottom];
		top = [images objectForKey: @"top"];
		bottom = [images objectForKey: @"bottom"];
	}
	// Before drawing, we check we have the images

	if (left == nil) [self error: @"left"];
	if (right == nil) [self error: @"right"];
	if (top == nil) [self error: @"top"];
	if (bottom == nil) [self error: @"bottom"];

	if (topLeft == nil) [self error: @"topLeft"];
	if (topRight == nil) [self error: @"topRight"];
	if (bottomLeft == nil) [self error: @"bottomLeft"];
	if (bottomRight == nil) [self error: @"bottomRight"];

	// We get the height of the top/bottom borders... (useful for NSBox's title positioning)
	
	topHeight = [top size].height / 2.0;
	bottomHeight = [bottom size].height / 2.0;

//	rect.origin.x -= leftWidth;
//	rect.origin.y -= topHeight;
//	rect.size.width += leftWidth + rightWidth;
//	rect.size.height += topHeight + bottomHeight;
	
	// Ok, drawing ...

	[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+[bottomLeft size].width,
		rect.origin.y,
		rect.size.width-[bottomLeft size].width-[bottomRight size].width,
		[bottom size].height)
		withImage: bottom];

	[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+[topLeft size].width,
		rect.origin.y+rect.size.height-[top size].height,
		rect.size.width-[topLeft size].width-[topRight size].width,
		[top size].height)
		withImage: top];

	[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x,
		rect.origin.y+[bottomLeft size].height,
		[left size].width,rect.size.height-[topLeft size].height-[bottomLeft size].height)
		withImage: left];

	[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x+rect.size.width-[right size].width,
		rect.origin.y+[bottomRight size].height,
		[right size].width,rect.size.height-[topRight size].height-[bottomRight size].height)
		withImage: right];

	[topLeft compositeToPoint: NSMakePoint (rect.origin.x,
		rect.origin.y+rect.size.height-[topLeft size].height)
		operation: NSCompositeSourceOver];

	[topRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-[topRight size].width,
		rect.origin.y+rect.size.height-[topRight size].height)
		operation: NSCompositeSourceOver];
	[bottomLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y)
		operation: NSCompositeSourceOver];
	[bottomRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-[bottomRight size].width,rect.origin.y)
		operation: NSCompositeSourceOver];

	NSRect rFill = NSMakeRect (rect.origin.x+[left size].width,
		rect.origin.y+[bottom size].height,
		rect.size.width-[right size].width-[left size].width,
		rect.size.height-[top size].height-[bottom size].height);
	if (fillType == CLFillColor) 
	{
		[colorFill set];
		NSRectFill (rFill);
	}

	if (fillType == CLFillScaledImage)
	{
		[fill setScalesWhenResized: YES];
		[fill setSize: rFill.size];
		[fill compositeToPoint: rFill.origin operation: NSCompositeSourceOver];
	}

	if (fillType == CLFillTiledImage)
	{
	}

}

@end
