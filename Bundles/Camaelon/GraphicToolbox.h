#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#ifndef __GRAPHIC_TOOLBOX_H__
#define __GRAPHIC_TOOLBOX_H__

@interface GraphicToolbox: NSObject
+ (NSColor*) readColorFromImage: (NSImage*) image;
+ (NSImage*) imageNamed: (NSString*) name;
+ (void) setImage: (NSImage*) image named: (NSString*) name;
+ (void) fillRect: (NSRect) rect withImage: (NSImage*) image;
+ (void) fillHorizontalRect: (NSRect) rect withImage: (NSImage*) image;
+ (void) fillHorizontalRect: (NSRect) rect withImage: (NSImage*) image flipped: (BOOL) flipped;
+ (void) fillVerticalRect: (NSRect) rect withImage: (NSImage*) image;
+ (void) fillVerticalRect: (NSRect) rect withImage: (NSImage*) image flipped: (BOOL) flipped;

+ (NSRect) drawFrame: (NSRect) rect 
withTopLeft: (NSImage*) topLeft
withTopRight: (NSImage*) topRight
withBottomLeft: (NSImage*) bottomLeft
withBottomRight: (NSImage*) bottomRight
			withTop: (NSImage*) top
			withBottom: (NSImage*) bottom
			withLeft: (NSImage*) left
			withRight: (NSImage*) right;
+ (void) drawButton: (NSRect) rect withCaps: (NSImage*) imageCaps filledWith: (NSImage*) imageFill 
	withLeftMargin: (float) left rightMargin: (float) right topMargin: (float) top bottomMargin: (float) bottom;
+ (void) drawButton: (NSRect) rect withCaps: (NSImage*) imageCaps filledWith: (NSImage*) imageFill 
	withLeftMargin: (float) left rightMargin: (float) right topMargin: (float) top bottomMargin: (float) bottom
	flipped: (BOOL) flipped;
+ (void) drawHorizontalButton: (NSRect) rect withCaps: (NSImage*) imageCaps filledWith: (NSImage*) imageFill 
	withLeftMargin: (float) left rightMargin: (float) right topMargin: (float) top bottomMargin: (float) bottom
	flipped: (BOOL) flipped;
+ (void) drawHorizontalButton: (NSRect) rect withLeftCap: (NSImage*) imageLeft
	rightCap: (NSImage*) imageRight filledWith: (NSImage*) imageFill 
	flipped: (BOOL) flipped;
+ (void) drawButton: (NSRect) rect withCaps: (NSImage*) imageCaps filledWith: (NSImage*) imageFill;
+ (void) drawVerticalButton: (NSRect) rect withCaps: (NSImage*) imageCaps filledWith: (NSImage*) imageFill
	withLeftMargin: (float) left rightMargin: (float) right topMargin: (float) top bottomMargin: (float) bottom
	flipped: (BOOL) flipped;
+ (void) drawVerticalButton: (NSRect) rect withUpCap: (NSImage*) imageUp 
	downCap: (NSImage*) imageDown filledWith: (NSImage*) imageFill 
	flipped: (BOOL) flipped;
+ (void) drawVerticalButton: (NSRect) rect withCaps: (NSImage*) imageCaps filledWith: (NSImage*) imageFill;
+ (void) drawButton: (NSRect) rect withCorners: (NSImage*) corners withLeftRight: (NSImage*) leftright withTopBottom: (NSImage*) topbottom;
+ (void) drawButton: (NSRect) rect withCorners: (NSImage*) corners withLeftRight: (NSImage*) leftright 
	 withTopBottom: (NSImage*) topbottom flipped: (BOOL) flipped;
+ (void) drawButton: (NSRect) rect withCorners: (NSImage*) corners withLeft: (NSImage*) left withRight: (NSImage*) right 
	 withTopBottom: (NSImage*) topbottom filledWith: (NSImage*) fill flipped: (BOOL) flipped;
	 
+ (void) drawButton: (NSRect) rect withCorners: (NSImage*) corners withLeft: (NSImage*) left withRight: (NSImage*) right 
	 withTop: (NSImage*) top withBottom: (NSImage*) bottom filledWith: (NSImage*) fill repeatFill: (BOOL) repeat flipped: (BOOL) flipped;
@end

#endif
