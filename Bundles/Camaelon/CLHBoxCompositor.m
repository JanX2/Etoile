#include "CLHBoxCompositor.h"

@implementation CLHBoxCompositor

- (void) error: (NSString*) msg
{
	[super error: nil];
	NSLog (@"from CLHBoxCompositor, %@ missing", msg);
	exit (-2);
}

- (void) drawInRect: (NSRect) rect flipped: (BOOL) flipped
{
	// A HBox is composed of 3 images:

	NSImage* left = [images objectForKey: @"left"];
	NSImage* right = [images objectForKey: @"right"];
	NSImage* fill = [images objectForKey: @"fill"];

	// The composition is simply as follows:     [left][fill][fill][..][right]

	// In case we don't have the left and right images, we try to generate them using a caps images...

	if ((left == nil) || (right == nil))
	{	
		NSImage* caps = [images objectForKey: @"caps"];
		float w = [caps size].width / 2.0;
		float h = [caps size].height;
		left = [[NSImage alloc] initWithSize: NSMakeSize (w, h)];	
		right = [[NSImage alloc] initWithSize: NSMakeSize (w, h)];	

		[left lockFocus];
		[caps compositeToPoint: NSMakePoint (0,0) operation: NSCompositeSourceOver];
		[left unlockFocus];

		[right lockFocus];
		[caps compositeToPoint: NSMakePoint (-w,0) operation: NSCompositeSourceOver];
		[right unlockFocus];

		[images setObject: left forKey: @"left"];
		[images setObject: right forKey: @"right"];

		// we autorelase as we'll use them now for the drawing

		[left autorelease]; 
		[right autorelease];
	}

	// Before drawing, we check we have the images

	if (left == nil) [self error: @"left"];
	if (right == nil) [self error: @"right"];
	if (fill == nil) [self error: @"fill"];

	// Ok, drawing ...

	float deltaY = (rect.size.height - [fill size].height)/2.0;
	NSPoint compositeOrigin = rect.origin;

	// We must flip the origin for drawing the left and right images

	if (flipped)
		compositeOrigin.y += [fill size].height;

	[left compositeToPoint: NSMakePoint (compositeOrigin.x,compositeOrigin.y+deltaY)
		operation: NSCompositeSourceOver];
	[right compositeToPoint: NSMakePoint (compositeOrigin.x+rect.size.width-[right size].width,compositeOrigin.y+deltaY)
		operation: NSCompositeSourceOver];

	// We fill the space between the left and right images without flipping the 
	// origin by passing rect parameter as is.
	// -fillHorizontalRect:withImage:flipped: knows how to flip the coordinates 
	// based on flipped parameter unlike -compositeToPoint:operation which 
	// accepts no such hint.

	[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+[left size].width, rect.origin.y+deltaY,
		rect.size.width-[left size].width-[right size].width,
				[fill size].height) withImage: fill flipped: flipped];
}

@end
