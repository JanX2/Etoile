#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GraphicToolbox.h"

@implementation GraphicToolbox

/*
	Theses two methods implements a cache.
	+imageNamed: will returns the image corresponding to the name or nil if not found
	+setImage:named: will add a new image in the cache
*/

static NSMutableDictionary* cache;

+ (NSColor*) readColorFromImage: (NSImage*) image 
{
	NSColor* color = nil;
	/*
	[image lockFocus];
	color = NSReadPixel (NSMakePoint (0,0));
	[image unlockFocus];
	*/
	if (image)
	{

		NSBitmapImageRep* bmp = [NSBitmapImageRep 
			imageRepWithData: [image TIFFRepresentation]];
		unsigned char* data = [bmp bitmapData];
		if ([bmp isPlanar])
		{
			NSLog (@"Image isPlanar, not yet supported");
		}
		else
		{
			unsigned char R, G, B;
			float fR, fG, fB;

			R = *data;
			G = *(data+1);
			B = *(data+2);
			
			fR = R / 255.0;
			fG = G / 255.0;
			fB = B / 255.0;

			color = [NSColor colorWithCalibratedRed: 
				fR green: fG blue: fB alpha: 1.0];
		}
	}
	if (color == nil) color = [NSColor 
		colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0];
	return color;
}

+ (NSImage*) imageNamed: (NSString*) name
{
	if (cache == nil)
	{
		cache = [NSMutableDictionary new];
	}

	return [cache objectForKey: name];
}

+ (void) setImage: (NSImage*) image named: (NSString*) name
{
	if (cache == nil)
	{
		cache = [NSMutableDictionary new];
	}

	[cache setObject: image forKey: name];
}

/*
	Fill a rect using an image. We tile the image in the rect (the operation is clipped of course)
*/

+ (void) fillRect: (NSRect) rect withImage: (NSImage*) image
{
	NSGraphicsContext* ctxt = GSCurrentContext ();
//	NSAffineTransform *ctm = nil;
	DPSgsave (ctxt);
	NSBezierPath* path = [NSBezierPath bezierPathWithRect: rect];
	[path addClip];

	float wImage = [image size].width;
	float hImage = [image size].height;
	float wRect = rect.size.width;
	float hRect = rect.size.height;

	int nx = wRect / wImage;
	int ny = hRect / hImage;
	int x = 0;
	int y = 0;

	nx++;
	ny++;

//	NSBitmapImageRep* bmp = [[image representations] objectAtIndex: 0];
	for (x=0; x<nx; x++)
	{
		for (y=0; y<ny; y++)
		{
			NSPoint p = NSMakePoint (rect.origin.x + x*wImage, rect.origin.y + y*hImage);
			/*
//			if ([[ctxt focusView] isFlipped])
//				p.y -= hImage;
 			ctm = GSCurrentCTM(ctxt);
			DPStranslate(ctxt, p.x, p.y);
			[bmp draw];
			GSSetCTM(ctxt, ctm);
			*/
			//[bmp drawAtPoint: p]; // we have a drawing problem with it...
			[image compositeToPoint: p operation: NSCompositeSourceOver];
		}
	}

	DPSgrestore (ctxt);	
}

/*
	Fill a rect using an image. We tile the image horizontally in the rect (the operation is clipped of course)
*/

+ (void) fillHorizontalRect: (NSRect) rect withImage: (NSImage*) image
{
	[GraphicToolbox fillHorizontalRect: rect withImage: image flipped: NO];
}

+ (void) fillHorizontalRect: (NSRect) rect withImage: (NSImage*) image flipped: (BOOL) flipped
{
	NSGraphicsContext* ctxt = GSCurrentContext ();
	DPSgsave (ctxt);
	NSBezierPath* path = [NSBezierPath bezierPathWithRect: rect];
	[path addClip];

	float wImage = [image size].width;
//	float hImage = [image size].height;
	float wRect = rect.size.width;
//	float hRect = rect.size.height;

	int nx = wRect / wImage;
	int x = 0;

	nx++;

	float y = rect.origin.y;

	if (flipped) y = rect.origin.y + rect.size.height;
	
//	NSBitmapImageRep* bmp = [[image representations] objectAtIndex: 0];
	for (x=0; x<nx; x++)
	{
		NSPoint p = NSMakePoint (rect.origin.x + x*wImage, y);
		//[bmp drawAtPoint: p]; // we have a drawing problem with it...
		[image compositeToPoint: p operation: NSCompositeSourceOver];
	}

	DPSgrestore (ctxt);	
}

/*
	Fill a rect using an image. We tile the image vertically in the rect (the operation is clipped of course)
*/

+ (void) fillVerticalRect: (NSRect) rect withImage: (NSImage*) image
{
	[GraphicToolbox fillVerticalRect: rect withImage: image flipped: NO];
}

+ (void) fillVerticalRect: (NSRect) rect withImage: (NSImage*) image flipped: (BOOL) flipped
{
	[image retain];
	NSGraphicsContext* ctxt = GSCurrentContext ();
	DPSgsave (ctxt);
	NSBezierPath* path = [NSBezierPath bezierPathWithRect: rect];

//	float wImage = [image size].width;
	float hImage = [image size].height;
//	float wRect = rect.size.width;
	float hRect = rect.size.height;

	[path addClip];

	if (flipped)
	{
		int ny = hRect / hImage;
		int y = 0;

		ny++;

//		NSBitmapImageRep* bmp = [[image representations] objectAtIndex: 0];
		for (y=0; y<ny; y++)
		{
			NSPoint p = NSMakePoint (rect.origin.x, rect.origin.y + hRect - y*hImage);
			//[bmp drawAtPoint: p]; // we have a drawing problem with it...
			[image compositeToPoint: p operation: NSCompositeSourceOver];
		}
	}
	else
	{
		int ny = hRect / hImage;
		int y = 0;

		ny++;

//		NSBitmapImageRep* bmp = [[image representations] objectAtIndex: 0];
		for (y=0; y<ny; y++)
		{
			NSPoint p = NSMakePoint (rect.origin.x, rect.origin.y + y*hImage);
			//[bmp drawAtPoint: p]; // we have a drawing problem with it...
			[image compositeToPoint: p operation: NSCompositeSourceOver];
		}
	}

	DPSgrestore (ctxt);	
	[image release];
}

/*
	Draw a "frame" using images. We have 4 images for each corners, and 4 images for each borders.
	The images for the border are tiled. 
	This method returns the inside rect of the frame (this can be used to fill the inside..)
*/

+ (NSRect) drawFrame: (NSRect) rect 
			withTopLeft: (NSImage*) topLeft
			withTopRight: (NSImage*) topRight
			withBottomLeft: (NSImage*) bottomLeft
			withBottomRight: (NSImage*) bottomRight
			withTop: (NSImage*) top
			withBottom: (NSImage*) bottom
			withLeft: (NSImage*) left
			withRight: (NSImage*) right
{

	[topLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y+rect.size.height-[topLeft size].height)
		operation: NSCompositeSourceOver];
	[topRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-[topRight size].width,rect.origin.y+rect.size.height-[topLeft size].height)
		operation: NSCompositeSourceOver];
	[bottomLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y)
		operation: NSCompositeSourceOver];
	[bottomRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-[bottomRight size].width,rect.origin.y)
		operation: NSCompositeSourceOver];
	[GraphicToolbox fillRect: NSMakeRect (rect.origin.x+[topLeft size].width,
					rect.origin.y+rect.size.height-[top size].height,
					rect.size.width-[topLeft size].width-[topRight size].width,
					[top size].height)
		withImage: top];
	[GraphicToolbox fillRect: NSMakeRect (rect.origin.x+[topLeft size].width,rect.origin.y,
					rect.size.width-[bottomLeft size].width-[bottomRight size].width,
					[bottom size].height)
		withImage: bottom];
	[GraphicToolbox fillRect: NSMakeRect (rect.origin.x,rect.origin.y+[bottomLeft size].height,
					[left size].width, rect.size.height-[topLeft size].height-[bottomLeft size].height)
		withImage: left];
	[GraphicToolbox fillRect: NSMakeRect (rect.origin.x+rect.size.width-[right size].width,
					rect.origin.y+[bottomRight size].height,
					[right size].width,
					rect.size.height-[topRight size].height-[bottomRight size].height)
		withImage: right];

	return NSMakeRect (rect.origin.x+[bottomLeft size].width,
				rect.origin.y+[bottomLeft size].height,
				rect.size.width - [bottomLeft size].width - [bottomRight size].width,
				rect.size.height - [topRight size].height - [bottomRight size].height);
	
}

/*
	Draw a button using two images; the first image (imageCaps) is divided in two, the left part is used
	as the left part of the button, the right part as the right part of the button. The second image
	(imageFill) is used to fill the space between the ends..

	The margins parameters permit to uses images that have margins (empty space) 
*/

+ (void) drawButton: (NSRect) rect withCaps: (NSImage*) imageCaps filledWith: (NSImage*) imageFill 
	withLeftMargin: (float) left rightMargin: (float) right topMargin: (float) top bottomMargin: (float) bottom 
{
	[GraphicToolbox drawButton: rect withCaps: imageCaps filledWith: imageFill withLeftMargin: left 
		rightMargin: right topMargin: top bottomMargin: bottom flipped: NO];
}

+ (void) drawButton: (NSRect) rect withCaps: (NSImage*) imageCaps filledWith: (NSImage*) imageFill 
	withLeftMargin: (float) left rightMargin: (float) right topMargin: (float) top bottomMargin: (float) bottom
	flipped: (BOOL) flipped
{
	float w = ([imageCaps size].width - left - right)/2.0;
	float h = [imageCaps size].height - top - bottom;
	NSImage* imageRight = [[NSImage alloc] initWithSize: NSMakeSize (w,h)];
	NSImage* imageLeft = [[NSImage alloc] initWithSize: NSMakeSize (w,h)];
	NSImage* imagePattern = [[NSImage alloc] initWithSize: NSMakeSize ([imageFill size].width,h)];

	// We get the left part

	[imageLeft lockFocus];
	//[[NSColor greenColor] set];
	//NSRectFill (NSMakeRect(0,0,w,h));
	[imageCaps compositeToPoint: NSMakePoint (-left,-bottom) operation: NSCompositeSourceOver];
	[imageLeft unlockFocus];

	// We get the right part

	[imageRight lockFocus];
	//[[NSColor redColor] set];
	//NSRectFill (NSMakeRect(0,0,w,h));
	[imageCaps compositeToPoint: NSMakePoint (-w-left,-bottom) operation: NSCompositeSourceOver];
	[imageRight unlockFocus];

	// We get the middle part

	[imagePattern lockFocus];
	[imageFill compositeToPoint: NSMakePoint (0,-bottom) operation: NSCompositeSourceOver];
	[imagePattern unlockFocus];
	
	// We calculate the delta Y

	float deltaY = (rect.size.height - [imageFill size].height)/2.0;

	// We draw the components.

	[imageLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y+deltaY)
		operation: NSCompositeSourceOver];
	[imageRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-w,rect.origin.y+deltaY)
		operation: NSCompositeSourceOver];

	[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+w,rect.origin.y+deltaY,rect.size.width-(2*w),
				[imageFill size].height) withImage: imagePattern];

	[imageRight release];
	[imageLeft release];
	[imagePattern release];

}

+ (void) drawHorizontalButton: (NSRect) rect withCaps: (NSImage*) imageCaps filledWith: (NSImage*) imageFill 
	withLeftMargin: (float) left rightMargin: (float) right topMargin: (float) top bottomMargin: (float) bottom
	flipped: (BOOL) flipped
{
	float w = ([imageCaps size].width - left - right)/2.0;
	float h = [imageCaps size].height - top - bottom;
	NSImage* imageRight = [[NSImage alloc] initWithSize: NSMakeSize (w,h)];
	NSImage* imageLeft = [[NSImage alloc] initWithSize: NSMakeSize (w,h)];
	NSImage* imagePattern = [[NSImage alloc] initWithSize: NSMakeSize ([imageFill size].width,h)];

	// We get the left part

	[imageLeft lockFocus];
	//[[NSColor redColor] set];
	//NSRectFill (NSMakeRect(0,0,w,h));
	[imageCaps compositeToPoint: NSMakePoint (-left,-bottom) operation: NSCompositeSourceOver];
	[imageLeft unlockFocus];

	// We get the right part

	[imageRight lockFocus];
	//[[NSColor redColor] set];
	//NSRectFill (NSMakeRect(0,0,w,h));
	[imageCaps compositeToPoint: NSMakePoint (-w-left,-bottom) operation: NSCompositeSourceOver];
	[imageRight unlockFocus];

	// We get the middle part

	[imagePattern lockFocus];
	[imageFill compositeToPoint: NSMakePoint (0,-bottom) operation: NSCompositeSourceOver];
	[imagePattern unlockFocus];
	
	// We calculate the delta Y

	float deltaY = (rect.size.height - [imageFill size].height)/2.0;

	// We draw the components.

	if ((rect.size.height > 0) && (rect.size.width > 0))
	{
		if (flipped)
		{
			[imageLeft compositeToPoint: NSMakePoint (rect.origin.x, rect.origin.y + rect.size.height - deltaY)
				operation: NSCompositeSourceOver];
			[imageRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-w, rect.origin.y+ rect.size.height - deltaY)
				operation: NSCompositeSourceOver];
		}
		else
		{
			[imageLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y+deltaY)
				operation: NSCompositeSourceOver];
			[imageRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-w,rect.origin.y+deltaY)
				operation: NSCompositeSourceOver];
		}

		[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+w,rect.origin.y+deltaY,rect.size.width-(2*w),
			[imageFill size].height) withImage: imagePattern flipped: flipped];
	}

	[imageRight release];
	[imageLeft release];
	[imagePattern release];

}

+ (void) drawHorizontalButton: (NSRect) rect withLeftCap: (NSImage*) imageLeft
	rightCap: (NSImage*) imageRight filledWith: (NSImage*) imageFill 
	flipped: (BOOL) flipped
{
	// We calculate the delta Y

	float deltaY = (rect.size.height - [imageFill size].height)/2.0;

	// We draw the components.

	if ((rect.size.height > 0) && (rect.size.width > 0))
	{
		if (flipped)
		{
			[imageLeft compositeToPoint: NSMakePoint (rect.origin.x, 
				rect.origin.y + rect.size.height - deltaY)
				operation: NSCompositeSourceOver];
			[imageRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width
				-[imageRight size].width, 
				rect.origin.y+ rect.size.height - deltaY)
				operation: NSCompositeSourceOver];
		}
		else
		{
			[imageLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y+deltaY)
				operation: NSCompositeSourceOver];
			[imageRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width
				-[imageRight size].width,rect.origin.y+deltaY)
				operation: NSCompositeSourceOver];
		}

		[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+[imageLeft size].width,
			rect.origin.y+deltaY,rect.size.width-[imageLeft size].width-[imageRight size].width,
			[imageFill size].height) withImage: imageFill flipped: flipped];
	}
}

/*
	Convenient method that uses drawButton:withCaps:filledWith:withLeftMargin:rightMargin:topMargin:bottomMargin
	with margin of 0.
*/

+ (void) drawButton: (NSRect) rect withCaps: (NSImage*) imageCaps filledWith: (NSImage*) imageFill
{
	[GraphicToolbox drawButton: rect withCaps: imageCaps filledWith: imageFill
		withLeftMargin: 0.0 rightMargin: 0.0 topMargin: 0.0 bottomMargin: 0.0];
}

/*
	Draw a vertical button using two images; the first image (imageCaps) is divided in two, the left part is used
	as the left part of the button, the right part as the right part of the button. The second image
	(imageFill) is used to fill the space between the ends..

	The margins parameters permit to uses images that have margins (empty space) 
*/

+ (void) drawVerticalButton: (NSRect) rect withCaps: (NSImage*) imageCaps filledWith: (NSImage*) imageFill 
	withLeftMargin: (float) left rightMargin: (float) right topMargin: (float) top bottomMargin: (float) bottom
	flipped: (BOOL) flipped
{
	float w = ([imageCaps size].width - left - right);
	float h = ([imageCaps size].height - top - bottom)/2.0;
	NSImage* imageRight = [[NSImage alloc] initWithSize: NSMakeSize (w,h)];
	NSImage* imageLeft = [[NSImage alloc] initWithSize: NSMakeSize (w,h)];
	NSImage* imagePattern = [[NSImage alloc] initWithSize: NSMakeSize ([imageFill size].width,h)];

	// We get the left part

	[imageLeft lockFocus];
	[imageCaps compositeToPoint: NSMakePoint (-left,-bottom) operation: NSCompositeSourceOver];
	[imageLeft unlockFocus];

	// We get the right part

	[imageRight lockFocus];
	[imageCaps compositeToPoint: NSMakePoint (-left,-bottom-h) operation: NSCompositeSourceOver];
	[imageRight unlockFocus];

	// We get the middle part

	[imagePattern lockFocus];
	[imageFill compositeToPoint: NSMakePoint (-left,0) operation: NSCompositeSourceOver];
	[imagePattern unlockFocus];

	float deltaX = (rect.size.width - w) / 2.0;

	if ((rect.size.height > 0) && (rect.size.width > 0))
	{
		[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x+deltaX,
			rect.origin.y+h,[imageFill size].width,
			rect.size.height-(2*h)) withImage: imagePattern flipped: flipped];
		if (flipped)
		{
			[imageLeft compositeToPoint: NSMakePoint (rect.origin.x+deltaX,
				rect.origin.y+rect.size.height)
				operation: NSCompositeSourceOver];
			[imageRight compositeToPoint: NSMakePoint (rect.origin.x+deltaX,rect.origin.y+h)
				operation: NSCompositeSourceOver];
		}
		else
		{
			[imageLeft compositeToPoint: NSMakePoint (rect.origin.x+deltaX,rect.origin.y)
				operation: NSCompositeSourceOver];
			[imageRight compositeToPoint: NSMakePoint (rect.origin.x+deltaX,
				rect.origin.y+rect.size.height-h)
				operation: NSCompositeSourceOver];
		}
	}

	[imageRight release];
	[imageLeft release];
	[imagePattern release];
}

+ (void) drawVerticalButton: (NSRect) rect withUpCap: (NSImage*) imageUp 
	downCap: (NSImage*) imageDown filledWith: (NSImage*) imageFill 
	flipped: (BOOL) flipped
{
	float deltaX = (rect.size.width - [imageFill size].width) / 2.0;

	if ((rect.size.height > 0) && (rect.size.width > 0))
	{
		[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x+deltaX,
			rect.origin.y+[imageUp size].height,[imageFill size].width,
			rect.size.height-[imageUp size].height-[imageDown size].height) 
			withImage: imageFill flipped: flipped];
		if (flipped)
		{
			[imageDown compositeToPoint: NSMakePoint (rect.origin.x+deltaX,
				rect.origin.y+rect.size.height)
				operation: NSCompositeSourceOver];
			[imageUp compositeToPoint: NSMakePoint (rect.origin.x+deltaX,
				rect.origin.y+[imageUp size].height)
				operation: NSCompositeSourceOver];
		}
		else
		{
			[imageDown compositeToPoint: NSMakePoint (rect.origin.x+deltaX,rect.origin.y)
				operation: NSCompositeSourceOver];
			[imageUp compositeToPoint: NSMakePoint (rect.origin.x+deltaX,
				rect.origin.y+rect.size.height-[imageUp size].height)
				operation: NSCompositeSourceOver];
		}
	}
}

/*
	Convenient method that uses drawVerticalButton:withCaps:filledWith:withLeftMargin:rightMargin:topMargin:bottomMargin
	with margin of 0.
*/

+ (void) drawVerticalButton: (NSRect) rect withCaps: (NSImage*) imageCaps filledWith: (NSImage*) imageFill
{
	[GraphicToolbox drawVerticalButton: rect withCaps: imageCaps filledWith: imageFill
		withLeftMargin: 0.0 rightMargin: 0.0 topMargin: 0.0 bottomMargin: 0.0 flipped: NO];
}

+ (void) drawButton: (NSRect) rect withCorners: (NSImage*) corners withLeftRight: (NSImage*) leftright withTopBottom: (NSImage*) topbottom
{

	NSSize lrSize = [leftright size];
	NSImage* imageRight = [[NSImage alloc] initWithSize: NSMakeSize (lrSize.width/2,lrSize.height)];
	NSImage* imageLeft = [[NSImage alloc] initWithSize: NSMakeSize (lrSize.width/2,lrSize.height)];
	NSSize tbSize = [topbottom size];
	NSImage* imageTop = [[NSImage alloc] initWithSize: NSMakeSize (tbSize.width,tbSize.height/2)];
	NSImage* imageBottom = [[NSImage alloc] initWithSize: NSMakeSize (tbSize.width,tbSize.height/2)];
	NSSize cSize = [corners size];
	NSImage* imageTopLeft = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* imageTopRight = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* imageBottomLeft = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* imageBottomRight = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];

	[imageLeft lockFocus];
	[leftright compositeToPoint: NSMakePoint (0,0) operation: NSCompositeSourceOver];
	[imageLeft unlockFocus];
	
	[imageRight lockFocus];
	[leftright compositeToPoint: NSMakePoint (-lrSize.width/2,0) operation: NSCompositeSourceOver];
	[imageRight unlockFocus];

	[imageTop lockFocus];
	[topbottom compositeToPoint: NSMakePoint (0,-tbSize.height/2) operation: NSCompositeSourceOver];
	[imageTop unlockFocus];

	[imageBottom lockFocus];
	[topbottom compositeToPoint: NSMakePoint (0,0) operation: NSCompositeSourceOver];
	[imageBottom unlockFocus];

	[imageTopLeft lockFocus];
	[corners compositeToPoint: NSMakePoint (0,-cSize.height/2) operation: NSCompositeSourceOver];
	[imageTopLeft unlockFocus];

	[imageTopRight lockFocus];
	[corners compositeToPoint: NSMakePoint (-cSize.width/2,-cSize.height/2) operation: NSCompositeSourceOver];
	[imageTopRight unlockFocus];

	[imageBottomLeft lockFocus];
	[corners compositeToPoint: NSMakePoint (0,0) operation: NSCompositeSourceOver];
	[imageBottomLeft unlockFocus];

	[imageBottomRight lockFocus];
	[corners compositeToPoint: NSMakePoint (-cSize.width/2,0) operation: NSCompositeSourceOver];
	[imageBottomRight unlockFocus];

	[imageTopLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y+rect.size.height-cSize.height/2)
		operation: NSCompositeSourceOver];
	[imageTopRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-cSize.width/2,
		rect.origin.y+rect.size.height-cSize.height/2)
		operation: NSCompositeSourceOver];
	[imageBottomLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y)
		operation: NSCompositeSourceOver];
	[imageBottomRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-cSize.width/2,rect.origin.y)
		operation: NSCompositeSourceOver];

	[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+cSize.width/2,rect.origin.y,
		rect.size.width-cSize.width,tbSize.height/2)
		withImage: imageBottom];
	[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+cSize.width/2,
		rect.origin.y+rect.size.height-tbSize.height/2,
		rect.size.width-cSize.width,tbSize.height/2)
		withImage: imageTop];
	[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x,rect.origin.y+cSize.height/2,
		lrSize.width/2,rect.size.height-cSize.height)
		withImage: imageLeft];
	[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x+rect.size.width-lrSize.width/2,
		rect.origin.y+cSize.height/2,
		lrSize.width/2,rect.size.height-cSize.height)
		withImage: imageRight];

	[imageRight release];
	[imageLeft release];
	[imageTop release];
	[imageBottom release];
	[imageTopLeft release];
	[imageTopRight release];
	[imageBottomLeft release];
	[imageBottomRight release];
	
}

+ (void) drawButton: (NSRect) rect withCorners: (NSImage*) corners withLeftRight: (NSImage*) leftright 
	 withTopBottom: (NSImage*) topbottom flipped: (BOOL) flipped
{
	NSSize lrSize = [leftright size];
	NSImage* imageRight = [[NSImage alloc] initWithSize: NSMakeSize (lrSize.width/2,lrSize.height)];
	NSImage* imageLeft = [[NSImage alloc] initWithSize: NSMakeSize (lrSize.width/2,lrSize.height)];
	NSSize tbSize = [topbottom size];
	NSImage* imageTop = [[NSImage alloc] initWithSize: NSMakeSize (tbSize.width,tbSize.height/2)];
	NSImage* imageBottom = [[NSImage alloc] initWithSize: NSMakeSize (tbSize.width,tbSize.height/2)];
	NSSize cSize = [corners size];
	NSImage* imageTopLeft = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* imageTopRight = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* imageBottomLeft = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* imageBottomRight = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];

	[imageLeft lockFocus];
	[leftright compositeToPoint: NSMakePoint (0,0) operation: NSCompositeSourceOver];
	[imageLeft unlockFocus];
	
	[imageRight lockFocus];
	[leftright compositeToPoint: NSMakePoint (-lrSize.width/2,0) operation: NSCompositeSourceOver];
	[imageRight unlockFocus];

	[imageTop lockFocus];
	[topbottom compositeToPoint: NSMakePoint (0,-tbSize.height/2) operation: NSCompositeSourceOver];
	[imageTop unlockFocus];

	[imageBottom lockFocus];
	[topbottom compositeToPoint: NSMakePoint (0,0) operation: NSCompositeSourceOver];
	[imageBottom unlockFocus];

	[imageTopLeft lockFocus];
	[corners compositeToPoint: NSMakePoint (0,-cSize.height/2) operation: NSCompositeSourceOver];
	[imageTopLeft unlockFocus];

	[imageTopRight lockFocus];
	[corners compositeToPoint: NSMakePoint (-cSize.width/2,-cSize.height/2) operation: NSCompositeSourceOver];
	[imageTopRight unlockFocus];

	[imageBottomLeft lockFocus];
	[corners compositeToPoint: NSMakePoint (0,0) operation: NSCompositeSourceOver];
	[imageBottomLeft unlockFocus];

	[imageBottomRight lockFocus];
	[corners compositeToPoint: NSMakePoint (-cSize.width/2,0) operation: NSCompositeSourceOver];
	[imageBottomRight unlockFocus];

	if (flipped)
	{
		[imageTopLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y+cSize.height/2)
			operation: NSCompositeSourceOver];
		[imageTopRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-cSize.width/2,
			rect.origin.y+cSize.height/2)
			operation: NSCompositeSourceOver];
		[imageBottomLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y+rect.size.height)
			operation: NSCompositeSourceOver];
		[imageBottomRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-cSize.width/2,
			rect.origin.y+rect.size.height)
			operation: NSCompositeSourceOver];

		[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+cSize.width/2,
			rect.origin.y+rect.size.height,
			rect.size.width-cSize.width,-tbSize.height/2)
			withImage: imageBottom];
		[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+cSize.width/2,
			rect.origin.y+tbSize.height/2,
			rect.size.width-cSize.width,-tbSize.height/2)
			withImage: imageTop];
		[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x,rect.origin.y+rect.size.height-cSize.height/2,
			lrSize.width/2,-rect.size.height+cSize.height)
			withImage: imageLeft];
		[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x+rect.size.width-lrSize.width/2,
			rect.origin.y+rect.size.height-cSize.height/2,
			lrSize.width/2,-rect.size.height+cSize.height)
			withImage: imageRight];
	}
	else
	{
		[imageTopLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y+rect.size.height-cSize.height/2)
			operation: NSCompositeSourceOver];
		[imageTopRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-cSize.width/2,
			rect.origin.y+rect.size.height-cSize.height/2)
			operation: NSCompositeSourceOver];
		[imageBottomLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y)
			operation: NSCompositeSourceOver];
		[imageBottomRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-cSize.width/2,rect.origin.y)
			operation: NSCompositeSourceOver];

		[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+cSize.width/2,rect.origin.y,
			rect.size.width-cSize.width,tbSize.height/2)
			withImage: imageBottom];
		[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+cSize.width/2,
			rect.origin.y+rect.size.height-tbSize.height/2,
			rect.size.width-cSize.width,tbSize.height/2)
			withImage: imageTop];
		[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x,rect.origin.y+cSize.height/2,
			lrSize.width/2,rect.size.height-cSize.height)
			withImage: imageLeft];
		[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x+rect.size.width-lrSize.width/2,
			rect.origin.y+cSize.height/2,
			lrSize.width/2,rect.size.height-cSize.height)
			withImage: imageRight];
	}

	[imageRight release];
	[imageLeft release];
	[imageTop release];
	[imageBottom release];
	[imageTopLeft release];
	[imageTopRight release];
	[imageBottomLeft release];
	[imageBottomRight release];
	
}

/*
	This is the one used at the moment in GSDrawFunctions' drawButton 
*/

+ (void) drawButton: (NSRect) rect withCorners: (NSImage*) corners withLeft: (NSImage*) left withRight: (NSImage*) right 
	 withTopBottom: (NSImage*) topbottom filledWith: (NSImage*) fill flipped: (BOOL) flipped
{
	NSSize tbSize = [topbottom size];
	NSImage* imageTop = [[NSImage alloc] initWithSize: NSMakeSize (tbSize.width,tbSize.height/2)];
	NSImage* imageBottom = [[NSImage alloc] initWithSize: NSMakeSize (tbSize.width,tbSize.height/2)];
	NSSize cSize = [corners size];
	NSImage* imageTopLeft = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* imageTopRight = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* imageBottomLeft = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* imageBottomRight = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];

	[imageTop lockFocus];
	[topbottom compositeToPoint: NSMakePoint (0,-tbSize.height/2) operation: NSCompositeSourceOver];
	[imageTop unlockFocus];

	[imageBottom lockFocus];
	[topbottom compositeToPoint: NSMakePoint (0,0) operation: NSCompositeSourceOver];
	[imageBottom unlockFocus];

	[imageTopLeft lockFocus];
	[corners compositeToPoint: NSMakePoint (0,-cSize.height/2) operation: NSCompositeSourceOver];
	[imageTopLeft unlockFocus];

	[imageTopRight lockFocus];
	[corners compositeToPoint: NSMakePoint (-cSize.width/2,-cSize.height/2) operation: NSCompositeSourceOver];
	[imageTopRight unlockFocus];

	[imageBottomLeft lockFocus];
	[corners compositeToPoint: NSMakePoint (0,0) operation: NSCompositeSourceOver];
	[imageBottomLeft unlockFocus];

	[imageBottomRight lockFocus];
	[corners compositeToPoint: NSMakePoint (-cSize.width/2,0) operation: NSCompositeSourceOver];
	[imageBottomRight unlockFocus];

	flipped = NO;

	if (flipped)
	{

		[[NSColor redColor] set];
		NSRectFill (rect);

		[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+cSize.width/2,
			rect.origin.y,
			rect.size.width-cSize.width,
			tbSize.height/2)
			withImage: imageBottom];
		[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+cSize.width/2,
			rect.origin.y+tbSize.height/2,
			rect.size.width-cSize.width,-tbSize.height/2)
			withImage: imageTop];
		[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x,rect.origin.y+cSize.height/2,
			[left size].width,rect.size.height-cSize.height)
			withImage: left flipped: YES];
		[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x+rect.size.width-[right size].width,
			rect.origin.y+cSize.height/2,
			[right size].width,rect.size.height-cSize.height)
			withImage: right flipped: YES];

		[imageTopLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y+cSize.height/2)
			operation: NSCompositeSourceOver];
		[imageTopRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-cSize.width/2,
			rect.origin.y+cSize.height/2)
			operation: NSCompositeSourceOver];
		[imageBottomLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y+rect.size.height)
			operation: NSCompositeSourceOver];
		[imageBottomRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-cSize.width/2,rect.origin.y+rect.size.height)
			operation: NSCompositeSourceOver];

		NSRect rFill = NSMakeRect (rect.origin.x+2,rect.origin.y+2,rect.size.width-4,rect.size.height-4);
		[fill setScalesWhenResized: YES];
		[fill setSize: rFill.size];
		//[fill compositeToPoint: rFill.origin operation: NSCompositeSourceOver];
	}
	else
	{

		[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+cSize.width/2,rect.origin.y,
			rect.size.width-cSize.width,tbSize.height/2)
			withImage: imageBottom];
		[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+cSize.width/2,
			rect.origin.y+rect.size.height-tbSize.height/2,
			rect.size.width-cSize.width,tbSize.height/2)
			withImage: imageTop];
		[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x,rect.origin.y+cSize.height/2,
			[left size].width,rect.size.height-cSize.height)
			withImage: left];
		[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x+rect.size.width-[right size].width,
			rect.origin.y+cSize.height/2,
			[right size].width,rect.size.height-cSize.height)
			withImage: right];

		[imageTopLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y+rect.size.height-cSize.height/2)
			operation: NSCompositeSourceOver];
		[imageTopRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-cSize.width/2,
			rect.origin.y+rect.size.height-cSize.height/2)
			operation: NSCompositeSourceOver];
		[imageBottomLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y)
			operation: NSCompositeSourceOver];
		[imageBottomRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-cSize.width/2,rect.origin.y)
			operation: NSCompositeSourceOver];

		//NSRect rFill = NSMakeRect (rect.origin.x+2,rect.origin.y+2,rect.size.width-4,rect.size.height-4);
		float border = [imageTopLeft size].width;
		NSRect rFill = NSMakeRect (rect.origin.x+border,rect.origin.y+border,
			rect.size.width-border*2,rect.size.height-border*2);
		[fill setScalesWhenResized: YES];
		[fill setSize: rFill.size];
		//[fill compositeToPoint: rFill.origin operation: NSCompositeSourceOver];
	}


	[imageTop release];
	[imageBottom release];
	[imageTopLeft release];
	[imageTopRight release];
	[imageBottomLeft release];
	[imageBottomRight release];

}

+ (void) drawButton: (NSRect) rect withCorners: (NSImage*) corners withLeft: (NSImage*) left withRight: (NSImage*) right 
	 withTop: (NSImage*) top withBottom: (NSImage*) bottom filledWith: (NSImage*) fill repeatFill: (BOOL) repeat flipped: (BOOL) flipped
{
	NSSize cSize = [corners size];
	NSImage* imageTopLeft = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* imageTopRight = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* imageBottomLeft = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];
	NSImage* imageBottomRight = [[NSImage alloc] initWithSize: NSMakeSize (cSize.width/2, cSize.height/2)];

	[imageTopLeft lockFocus];
	[corners compositeToPoint: NSMakePoint (0,-cSize.height/2) operation: NSCompositeSourceOver];
	[imageTopLeft unlockFocus];

	[imageTopRight lockFocus];
	[corners compositeToPoint: NSMakePoint (-cSize.width/2,-cSize.height/2) operation: NSCompositeSourceOver];
	[imageTopRight unlockFocus];

	[imageBottomLeft lockFocus];
	[corners compositeToPoint: NSMakePoint (0,0) operation: NSCompositeSourceOver];
	[imageBottomLeft unlockFocus];

	[imageBottomRight lockFocus];
	[corners compositeToPoint: NSMakePoint (-cSize.width/2,0) operation: NSCompositeSourceOver];
	[imageBottomRight unlockFocus];

	flipped = NO;

	if (flipped)
	{

		[[NSColor redColor] set];
		NSRectFill (rect);

		[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+cSize.width/2,
			rect.origin.y,
			rect.size.width-cSize.width,
			[bottom size].height)
			withImage: bottom];
		[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+cSize.width/2,
			rect.origin.y+[top size].height,
			rect.size.width-cSize.width,-[top size].height)
			withImage: top];
		[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x,rect.origin.y+cSize.height/2,
			[left size].width,rect.size.height-cSize.height)
			withImage: left flipped: YES];
		[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x+rect.size.width-[right size].width,
			rect.origin.y+cSize.height/2,
			[right size].width,rect.size.height-cSize.height)
			withImage: right flipped: YES];

		[imageTopLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y+cSize.height/2)
			operation: NSCompositeSourceOver];
		[imageTopRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-cSize.width/2,
			rect.origin.y+cSize.height/2)
			operation: NSCompositeSourceOver];
		[imageBottomLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y+rect.size.height)
			operation: NSCompositeSourceOver];
		[imageBottomRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-cSize.width/2,rect.origin.y+rect.size.height)
			operation: NSCompositeSourceOver];

		NSRect rFill = NSMakeRect (rect.origin.x+2,rect.origin.y+2,rect.size.width-4,rect.size.height-4);
		[fill setScalesWhenResized: YES];
		[fill setSize: rFill.size];
		[fill compositeToPoint: rFill.origin operation: NSCompositeSourceOver];
	}
	else
	{

		[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+cSize.width/2,rect.origin.y,
			rect.size.width-cSize.width,[bottom size].height)
			withImage: bottom];
		[GraphicToolbox fillHorizontalRect: NSMakeRect (rect.origin.x+cSize.width/2,
			rect.origin.y+rect.size.height-[top size].height,
			rect.size.width-cSize.width,[top size].height)
			withImage: top];
		[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x,rect.origin.y+cSize.height/2,
			[left size].width,rect.size.height-cSize.height)
			withImage: left];
		[GraphicToolbox fillVerticalRect: NSMakeRect (rect.origin.x+rect.size.width-[right size].width,
			rect.origin.y+cSize.height/2,
			[right size].width,rect.size.height-cSize.height)
			withImage: right];

		[imageTopLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y+rect.size.height-cSize.height/2)
			operation: NSCompositeSourceOver];
		[imageTopRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-cSize.width/2,
			rect.origin.y+rect.size.height-cSize.height/2)
			operation: NSCompositeSourceOver];
		[imageBottomLeft compositeToPoint: NSMakePoint (rect.origin.x,rect.origin.y)
			operation: NSCompositeSourceOver];
		[imageBottomRight compositeToPoint: NSMakePoint (rect.origin.x+rect.size.width-cSize.width/2,rect.origin.y)
			operation: NSCompositeSourceOver];

		NSRect rFill = NSMakeRect (rect.origin.x+2,rect.origin.y+2,rect.size.width-4,rect.size.height-4);
		//NRO: correct behavior..
		//rFill = NSMakeRect (rect.origin.x + [left size].width, rect.origin.y + [bottom size].height,
		//			rect.size.width - [right size].width - [left size].width, 
		//			rect.size.height - [top size].height - [bottom size].height);
		if (repeat)
		{
			[GraphicToolbox fillRect: rFill withImage: fill];
		}
		else
		{
			[fill setScalesWhenResized: YES];
			[fill setSize: rFill.size];
			[fill compositeToPoint: rFill.origin operation: NSCompositeSourceOver];
		}
	}


	[imageTopLeft release];
	[imageTopRight release];
	[imageBottomLeft release];
	[imageBottomRight release];

}

@end
