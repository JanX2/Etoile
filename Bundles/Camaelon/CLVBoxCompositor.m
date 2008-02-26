#include "CLVBoxCompositor.h"

@implementation CLVBoxCompositor

- (void) error: (NSString*) msg
{
	[super error: nil];
	NSLog (@"from CLVBoxCompositor, %@ missing", msg);
	exit (-2);
}

- (void) drawInRect: (NSRect) rect flipped: (BOOL) flipped
{
	// A VBox is composed of 3 images:

	NSImage* bottom = [images objectForKey: @"bottom"];
	NSImage* top = [images objectForKey: @"top"];
	NSImage* fill = [images objectForKey: @"fill"];

	// The composition is simply as follows:     
	
	//	 [top]
	//	 [fill]
	//	 [fill]
	//	 [....]
	//	[bottom]

	// In case we don't have the bottom and top images, we try to generate them using a caps images...

	if ((bottom == nil) || (top == nil))
	{	
		NSImage* caps = [images objectForKey: @"caps"];
		float w = [caps size].width;
		float h = [caps size].height / 2.0;
		bottom = [[NSImage alloc] initWithSize: NSMakeSize (w, h)];	
		top = [[NSImage alloc] initWithSize: NSMakeSize (w, h)];	

		[bottom lockFocus];
		[caps compositeToPoint: NSMakePoint (0,0) operation: NSCompositeSourceOver];
		[bottom unlockFocus];

		[top lockFocus];
		[caps compositeToPoint: NSMakePoint (0,-h) operation: NSCompositeSourceOver];
		[top unlockFocus];

		[images setObject: bottom forKey: @"bottom"];
		[images setObject: top forKey: @"top"];

		// we autorelase as we'll use them now for the drawing

		[bottom autorelease]; 
		[top autorelease];
	}

	// Before drawing, we check we have the images

	if (bottom == nil) [self error: @"bottom"];
	if (top == nil) [self error: @"top"];
	if (fill == nil) [self error: @"fill"];

	// Ok, drawing ...

	float deltaX = (rect.size.width - [fill size].width)/2.0;
	NSPoint compositeOrigin = rect.origin;

	// We must flip the origin for drawing the left and right images

	if (flipped)
		compositeOrigin.y += rect.size.height;
	[bottom compositeToPoint: 
		NSMakePoint (compositeOrigin.x + deltaX, compositeOrigin.y)
		operation: NSCompositeSourceOver];

	if (flipped)
	{
		compositeOrigin.y = rect.origin.y + [top size].height;
	}
	else
	{
		compositeOrigin.y = rect.origin.y + rect.size.height - [top size].height;
	}
	[top compositeToPoint: NSMakePoint (compositeOrigin.x + deltaX, 
		compositeOrigin.y)
 		operation: NSCompositeSourceOver];
 
	// We fill the space between the left and right images without flipping the 
	// origin by passing rect parameter as is.
	// More explanations in CLHBoxCompositor
	
	[GraphicToolbox fillVerticalRect: 
		NSMakeRect (rect.origin.x+deltaX, rect.origin.y + [bottom size].height,
			[fill size].width, rect.size.height - [bottom size].height - [top size].height)
		withImage: fill flipped: flipped];
}

@end
