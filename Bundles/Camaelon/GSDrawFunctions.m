#include "GSDrawFunctions.h"

@implementation GSDrawFunctions (theme)
/*
+ (NSRect) drawButton: (NSRect)border : (NSRect)clip
{ 
	NSBezierPath* path = [NSBezierPath bezierPath];
	NSRect r = NSMakeRect (border.origin.x + 1, border.origin.y +1, border.size.width -=2, border.size.height -=2);
	[path appendBezierPathWithRect: r];
	[[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.4 alpha: 0.8] set];
	[path setLineWidth: 1.5];
	[path stroke];
}

+ (NSRect) drawDarkButton: (NSRect)border : (NSRect)clip
{ 
	NSBezierPath* path = [NSBezierPath bezierPath];
	NSRect r = NSMakeRect (border.origin.x + 1, border.origin.y +1, border.size.width -=2, border.size.height -=2);
	//[path appendBezierPathWithRoundedRectangle: r withRadius: 8.0];
	[path appendBezierPathWithRect: r];
	[[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.4 alpha: 0.8] set];
	[path setLineWidth: 1.5];
	[path stroke];
}
*/

+ (NSRect) drawGrayBezelRound: (NSRect)border : (NSRect)clip
{ 
	NSBezierPath* path = [NSBezierPath bezierPath];
	NSBezierPath* path2 = [NSBezierPath bezierPath];
	NSBezierPath* inside = [NSBezierPath bezierPath];
	
	NSRect r = NSMakeRect (border.origin.x + 1, border.origin.y +3, border.size.width -4, border.size.height -4);
	NSRect r2 = NSMakeRect (border.origin.x + 3, border.origin.y +1, border.size.width -4, border.size.height -4);
	NSRect r3 = NSMakeRect (border.origin.x + 2, border.origin.y +2, border.size.width -4, border.size.height -4);
	float radius = 8;
	if ((border.size.height < 20) || (border.size.width < 20)) { radius = 4; }
	if ((border.size.height < 10) || (border.size.width < 10)) { radius = 2; }
	[path appendBezierPathWithRoundedRectangle: r withRadius: radius];
	[path2 appendBezierPathWithRoundedRectangle: r2 withRadius: radius];
	[inside appendBezierPathWithRoundedRectangle: r3 withRadius: radius];
	[[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.4 alpha: 0.8] set];
	[path setLineWidth: 1.5];
	[path2 setLineWidth: 2.5];
	[[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 0.7] set];
	[path2 stroke];
 	[[NSColor blackColor] set];
	[path stroke];
	[[NSColor windowBackgroundColor] set];
	[inside fill];
	return r3;
}
+ (NSRect) drawGrayBezel: (NSRect)border : (NSRect)clip
{ 
	NSBezierPath* path = [NSBezierPath bezierPath];
	NSBezierPath* path2 = [NSBezierPath bezierPath];
	NSBezierPath* inside = [NSBezierPath bezierPath];
	
	NSRect r = NSMakeRect (border.origin.x + 1, border.origin.y +3, border.size.width -4, border.size.height -4);
	NSRect r2 = NSMakeRect (border.origin.x + 3, border.origin.y +1, border.size.width -4, border.size.height -4);
	NSRect r3 = NSMakeRect (border.origin.x + 2, border.origin.y +2, border.size.width -4, border.size.height -4);
	[path appendBezierPathWithRect: r];
	[path2 appendBezierPathWithRect: r2];
	[inside appendBezierPathWithRect: r3];
	[[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.4 alpha: 0.8] set];
	[path setLineWidth: 1.5];
	[path2 setLineWidth: 2.5];
	[[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 0.7] set];
	[path2 stroke];
 	[[NSColor blackColor] set];
	[path stroke];
	[[NSColor windowBackgroundColor] set];
	[inside fill];
	return r3;
}
+ (NSRect) drawGroove: (NSRect)border : (NSRect)clip
{ 
	NSBezierPath* path = [NSBezierPath bezierPath];
	NSBezierPath* path2 = [NSBezierPath bezierPath];
	NSRect r = NSMakeRect (border.origin.x + 1, border.origin.y +3, border.size.width -4, border.size.height -4);
	NSRect r2 = NSMakeRect (border.origin.x + 3, border.origin.y +1, border.size.width -4, border.size.height -4);
	float radius = 8;
	if ((border.size.height < 20) || (border.size.width < 20)) { radius = 4; }
	if ((border.size.height < 10) || (border.size.width < 10)) { radius = 2; }
	[path appendBezierPathWithRoundedRectangle: r withRadius: radius];
	[path2 appendBezierPathWithRoundedRectangle: r2 withRadius: radius];
	[[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.4 alpha: 0.8] set];
	[path setLineWidth: 1.5];
	[path2 setLineWidth: 2.5];
	[[NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 0.5] set];
	[path2 stroke];
 	[[NSColor blackColor] set];
	[path stroke];
}

////

+ (void) drawBrowserHeaderInRect: (NSRect) frame
{
	NSImage* fill = [NSImage imageNamed: @"ListHeader/ListHeader-fill-unselected.tiff"];
	NSSize fillSize = NSMakeSize ([fill size].width, frame.size.height);
	[fill setScalesWhenResized: YES];
	[fill setSize: fillSize];
	[GraphicToolbox fillHorizontalRect: frame withImage: fill];
  	NSGraphicsContext     *ctxt = GSCurrentContext();
	DPSsetlinewidth (ctxt, 1);
	[[NSColor colorWithCalibratedRed: 0.6 green: 0.6 blue: 0.6 alpha: 1.0] set];
	DPSrectstroke (ctxt, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
}

+ (float) ListHeaderHeight
{
	return [[NSImage imageNamed: @"ListHeader/ListHeader-fill-unselected.tiff"] size].height;
}

+ (void) drawTableHeaderInRect: (NSRect) frame
{
	NSImage* fill = [NSImage imageNamed: @"ListHeader/ListHeader-fill-unselected.tiff"];
	NSSize fillSize = NSMakeSize ([fill size].width, frame.size.height);
	[fill setScalesWhenResized: YES];
	[fill setSize: fillSize];
	[GraphicToolbox fillHorizontalRect: frame withImage: fill];
}

+ (void) drawTableHeaderCellInRect: (NSRect) frame highlighted: (BOOL) highlighted 
{
	frame.origin.y -= 1;
	NSImage* separation = nil;
	NSImage* fill = nil;
	if (highlighted)
	{
		fill = [NSImage imageNamed: @"ListHeader/ListHeader-fill-selected.tiff"];
		separation = [NSImage imageNamed: @"ListHeader/ListHeader-separator-selected.tiff"];
		[GraphicToolbox fillHorizontalRect: frame withImage: fill];
	}
	else
	{
		fill = [NSImage imageNamed: @"ListHeader/ListHeader-fill-unselected.tiff"];
		separation = [NSImage imageNamed: @"ListHeader/ListHeader-separator-unselected.tiff"];
	}
	[separation compositeToPoint: NSMakePoint (frame.origin.x + frame.size.width -1, frame.origin.y +1)
		operation: NSCompositeSourceOver];
}

+ (void) drawGradient: (NSData*) gradient withSize: (NSArray*) size 
	border: (NSRect) border
{
        NSAffineTransform *transform;
	NSDictionary* shader;

	transform=[[NSAffineTransform alloc] init];
	transform->matrix.m11=border.size.width;
	transform->matrix.m12=0.0;
	transform->matrix.m21=0.0;
	transform->matrix.m22=border.size.height;
	transform->matrix.tX=border.origin.x;
	transform->matrix.tY=border.origin.y;

	shader = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSNumber numberWithInt: 1], @"ShadingType",
			[NSArray arrayWithObjects:
				[NSNumber numberWithFloat: 0.0],
				[NSNumber numberWithFloat: 1.0],
				[NSNumber numberWithFloat: 0.0],
				[NSNumber numberWithFloat: 1.0], nil], @"Domain",
			transform, @"Matrix",
                        [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt: 0],@"FunctionType",
                                [NSArray arrayWithObjects:
                                        [NSNumber numberWithFloat: 0.0], // origin.x
                                        [NSNumber numberWithFloat: 1.0], // x + width
                                        [NSNumber numberWithFloat: 0.0], // origin.y
                                        [NSNumber numberWithFloat: 1.0], // y + height
                                        nil],
                                        @"Domain",
                                [NSArray arrayWithObjects:
                                        [NSNumber numberWithFloat: 0.0],
                                        [NSNumber numberWithFloat: 1.0],
                                        [NSNumber numberWithFloat: 0.0],
                                        [NSNumber numberWithFloat: 1.0],
                                        [NSNumber numberWithFloat: 0.0],
                                        [NSNumber numberWithFloat: 1.0],
                                        nil],
                                        @"Range",
                                [NSNumber numberWithInt: 8],@"BitsPerSample",
				size, @"Size",
                                gradient ,@"DataSource",
                                nil], @"Function", 
			nil];

        PSshfill(shader);
	[transform release];
	//[shader release]; //FIXME ..
}

+ (void) drawHorizontalGradient: (NSColor*) start to: (NSColor*) end frame: (NSRect) frame
{

	unsigned char * data;
	int datasize = 6 * sizeof (unsigned char);
	data = malloc (datasize);

	data [0] = [start redComponent] * 255;
	data [1] = [start greenComponent] * 255;
	data [2] = [start blueComponent] * 255;
	data [3] = [end redComponent] * 255;
	data [4] = [end greenComponent] * 255;
	data [5] = [end blueComponent] * 255;

	NSData* gradient = [NSData dataWithBytesNoCopy: data length: datasize];
	NSArray* size = [NSArray arrayWithObjects: [NSNumber numberWithInt: 2], [NSNumber numberWithInt: 1], nil];
	[GSDrawFunctions drawGradient: gradient withSize: size border: frame];
	free (data);
}

+ (void) drawVerticalGradient: (NSColor*) start to: (NSColor*) end frame: (NSRect) frame
{

	unsigned char * data;
	int datasize = 6 * sizeof (unsigned char);
	data = malloc (datasize);

	data [0] = [start redComponent] * 255;
	data [1] = [start greenComponent] * 255;
	data [2] = [start blueComponent] * 255;
	data [3] = [end redComponent] * 255;
	data [4] = [end greenComponent] * 255;
	data [5] = [end blueComponent] * 255;

	NSData* gradient = [NSData dataWithBytesNoCopy: data length: datasize];
	NSArray* size = [NSArray arrayWithObjects: [NSNumber numberWithInt: 1], [NSNumber numberWithInt: 2], nil];
	[GSDrawFunctions drawGradient: gradient withSize: size border: frame];
	free (data);
}

+ (void) drawDiagonalGradient: (NSColor*) start to: (NSColor*) end frame: (NSRect) frame direction: (int) direction
{

	unsigned char * data;
	int datasize = 12 * sizeof (unsigned char);
	data = malloc (datasize);
	float startR,startG,startB;
	float midR,midG,midB;
	float endR,endG,endB;
	
	startR = [start redComponent];
	startG = [start greenComponent];
	startB = [start blueComponent];
	endR = [end redComponent];
	endG = [end greenComponent];
	endB = [end blueComponent];
	if (endR > startR) midR = endR - startR;
	else midR = startR - endR;
	if (endG > startG) midG = endG - startG;
	else midG = startG - endG;
	if (endB > startB) midB = endB - startB;
	else midB = startB - endB;

	midR = startR + (midR/2);
	midG = startG + (midG/2);
	midB = startB + (midB/2);

	if (direction == 0) // bottom left to top right
	{
		data [0] = startR * 255;
		data [1] = startG * 255;
		data [2] = startB * 255;

		data [3] = midR * 255;
		data [4] = midG * 255;
		data [5] = midB * 255;

		data [6] = midR * 255;
		data [7] = midG * 255;
		data [8] = midB * 255;

		data [9] = endR * 255;
		data [10] = endG * 255;
		data [11] = endB * 255;
	}
	else if (direction == 1) // top left to bottom right
	{
		data [0] = midR * 255;
		data [1] = midG * 255;
		data [2] = midB * 255;

		data [3] = endR * 255;
		data [4] = endG * 255;
		data [5] = endB * 255;

		data [6] = startR * 255;
		data [7] = startG * 255;
		data [8] = startB * 255;

		data [9] = midR * 255;
		data [10] = midG * 255;
		data [11] = midB * 255;
	}

	NSData* gradient = [NSData dataWithBytesNoCopy: data length: datasize];
	NSArray* size = [NSArray arrayWithObjects: [NSNumber numberWithInt: 2], [NSNumber numberWithInt: 2], nil];
	[GSDrawFunctions drawGradient: gradient withSize: size border: frame];
	free (data);
}

+ (void) drawRadioButton: (NSRect) border inView: (NSView*) view highlighted: (BOOL) highlighted 
{
	NSBezierPath* path = [NSBezierPath bezierPath];
	NSRect r = NSMakeRect (border.origin.x + 1, border.origin.y + 1, border.size.width -2 , border.size.height -2);
	[path appendBezierPathWithOvalInRect: r];

	NSColor* start = [NSColor colorWithCalibratedRed: 0.8 green: 0.8 blue: 0.8 alpha: 1.0];
	NSColor* end   = [NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0];

	NSGraphicsContext *ctxt = GSCurrentContext();
	//DPSgsave (ctxt);
	//[path addClip];
	[GSDrawFunctions drawVerticalGradient: start to: end frame: border];
	//DPSgrestore (ctxt);
	[[NSColor blackColor] set];
	[path setLineWidth: 1.5];
	[path stroke];

	if (highlighted)
	{
		NSBezierPath* pathCircle = [NSBezierPath bezierPath];
		NSRect r = NSMakeRect (border.origin.x +4, border.origin.y +4, border.size.width -8, border.size.height -8);
		[pathCircle appendBezierPathWithOvalInRect: r];
		[[NSColor blackColor] set];
		[pathCircle fill];
	}
}

+ (void) drawMenu: (NSRect) border inView: (NSView*) view 
{
	NSBezierPath* path = [NSBezierPath bezierPath];
	[path appendBezierPathWithRect: border];
/*
	NSRect r = NSMakeRect (border.origin.x + 1, border.origin.y + 1, border.size.width -2 , border.size.height -2);
	[path appendBezierPathWithRect: r];

	NSColor* start = [NSColor colorWithCalibratedRed: 0.8 green: 0.8 blue: 0.8 alpha: 1.0];
	NSColor* end   = [NSColor colorWithCalibratedRed: 1.0 green: 1.0 blue: 1.0 alpha: 1.0];

	[GSDrawFunctions drawHorizontalGradient: end to: start frame: border];

	[[NSColor blackColor] set];
	[path setLineWidth: 1.5];
	[path stroke];
*/
	[GraphicToolbox fillRect: border withImage: [NSImage imageNamed: @"Menu/Menu-background-fill.tiff"]];
	[[NSColor blackColor] set];
	[path setLineWidth: 1.5];
	[path stroke];
}

+ (void) drawTextField: (NSRect) border focus: (BOOL) focus flipped: (BOOL) flipped
{
	if (focus)
	{
		NSLog (@"FOCUS TEXTFIELD");
		[GraphicToolbox drawButton: border
			withCorners: [NSImage imageNamed: @"Textfield/Textfield-corners-selected.tiff"]
			withLeftRight: [NSImage imageNamed: @"Textfield/Textfield-leftright-selected.tiff"]
			withTopBottom: [NSImage imageNamed: @"Textfield/Textfield-topbottom-selected.tiff"]
			flipped: flipped
		];
	}
	else
	{
		[GraphicToolbox drawButton: border
			withCorners: [NSImage imageNamed: @"Textfield/Textfield-corners-unselected.tiff"]
			withLeftRight: [NSImage imageNamed: @"Textfield/Textfield-leftright-unselected.tiff"]
			withTopBottom: [NSImage imageNamed: @"Textfield/Textfield-topbottom-unselected.tiff"]
			flipped: flipped
		];
	}
}

+ (void) drawButton: (NSRect) border inView: (NSView*) view highlighted: (BOOL) highlighted 
{
	NSSize windowSize = [view frame].size;
	NSString* key;
	if (highlighted)
		key = [NSString stringWithFormat: @"buttonHighlightedBackground-%.0fx%.0f", windowSize.width, windowSize.height];
	else
		key = [NSString stringWithFormat: @"buttonBackground-%.0fx%.0f", windowSize.width, windowSize.height];

	NSImage* img = [[CLCache cache] imageNamed: key];
	BOOL isFlipped = [view isFlipped];
	
	if (img == nil)
	{
		img = [[NSImage alloc] initWithSize: border.size];
		[img lockFocus];
	if (highlighted)
	{
		if ((border.size.height >= 22) && (border.size.height <= 28))
		{
			[GraphicToolbox drawButton: border 
				withCaps: [NSImage imageNamed: @"Button/Button-selected.tiff"]
				filledWith: [NSImage imageNamed: @"Button/Button-fill-selected.tiff"]];
		}
		else
		{
			[GraphicToolbox drawButton: border
				withCorners: [NSImage imageNamed: @"BevelButton/BevelButton-corners-selected.tiff"]
				withLeft: [NSImage imageNamed: @"BevelButton/BevelButton-left-selected.tiff"]
				withRight: [NSImage imageNamed: @"BevelButton/BevelButton-right-selected.tiff"]
				withTopBottom: [NSImage imageNamed: @"BevelButton/BevelButton-topbottom-selected.tiff"]
				filledWith: [NSImage imageNamed: @"BevelButton/BevelButton-fill-selected.tiff"]
				flipped: isFlipped
			];
		}
	}
	else
	{
		if ((border.size.height >= 22) && (border.size.height <= 28))
		{
			[GraphicToolbox drawButton: border 
				withCaps: [NSImage imageNamed: @"Button/Button-unselected.tiff"]
				filledWith: [NSImage imageNamed: @"Button/Button-fill-unselected.tiff"]];
		}
		else
		{
			[GraphicToolbox drawButton: border
				withCorners: [NSImage imageNamed: @"BevelButton/BevelButton-corners-unselected.tiff"]
				withLeft: [NSImage imageNamed: @"BevelButton/BevelButton-left-unselected.tiff"]
				withRight: [NSImage imageNamed: @"BevelButton/BevelButton-right-unselected.tiff"]
				withTopBottom: [NSImage imageNamed: @"BevelButton/BevelButton-topbottom-unselected.tiff"]
				filledWith: [NSImage imageNamed: @"BevelButton/BevelButton-fill-unselected.tiff"]
				flipped: isFlipped
			];
		}
	}
		[img unlockFocus];
		[[CLCache cache] setImage: img named: key];
		[img autorelease];
	}

	if (isFlipped)
	{
		[img compositeToPoint: NSMakePoint (border.origin.x, border.origin.y + border.size.height) operation: NSCompositeSourceOver];
	}
	else
	{
		[img compositeToPoint: NSMakePoint (border.origin.x, border.origin.y) operation: NSCompositeSourceOver];
	}
}

+ (void) drawProgressIndicator: (NSRect) rect
{
	[GraphicToolbox drawButton: rect
		withCaps: [NSImage 
			imageNamed: @"ProgressBar/ProgressBar-horizontal-background-caps.tiff"]
		filledWith: [NSImage
			imageNamed: @"ProgressBar/ProgressBar-horizontal-background-fill.tiff"]];
}

+ (void) drawTitleBox: (NSRect) rect on: (id) box
{
	[GraphicToolbox fillRect: rect withImage: [NSImage imageNamed: @"Window/Window-background.tiff"]];
}

+ (void) drawBox: (NSRect) rect on: (id) box
{
	NSRect frame = [box frame];
	NSSize windowSize = frame.size;
	NSString* key = [NSString stringWithFormat: @"boxBackground-%.0fx%.0f", windowSize.width, windowSize.height];
	NSImage* img = [[CLCache cache] imageNamed: key];
	
	if (img == nil)
	{
		img = [[NSImage alloc] initWithSize: rect.size];
		[img lockFocus];
		  NSRect rect2 = [GraphicToolbox drawFrame: rect withTopLeft: [NSImage imageNamed: @"GroupBox/GroupBox-top-left.tiff"]
					withTopRight: [NSImage imageNamed: @"GroupBox/GroupBox-top-right.tiff"]
					withBottomLeft: [NSImage imageNamed: @"GroupBox/GroupBox-bottom-left.tiff"]
					withBottomRight: [NSImage imageNamed: @"GroupBox/GroupBox-bottom-right.tiff"]
					withTop: [NSImage imageNamed: @"GroupBox/GroupBox-top.tiff"]
					withBottom: [NSImage imageNamed: @"GroupBox/GroupBox-bottom.tiff"]
					withLeft: [NSImage imageNamed: @"GroupBox/GroupBox-left.tiff"]
					withRight: [NSImage imageNamed: @"GroupBox/GroupBox-right.tiff"]]; 
		  // fill inside
		  [GraphicToolbox fillRect: rect2 withImage: [NSImage imageNamed: @"GroupBox/GroupBox-fill.tiff"]];
		[img unlockFocus];
		[[CLCache cache] setImage: img named: key];
		[img autorelease];
	}

	[img compositeToPoint: rect.origin fromRect: rect operation: NSCompositeSourceOver];
}

+ (void) drawWindowBackground: (NSRect) rect on: (id) window
{
	/*
	NSSize windowSize = [window frame].size;
	NSString* key = [NSString stringWithFormat: @"windowBackground-%.0fx%.0f", windowSize.width, windowSize.height];
	NSLog (@"drawWindowBackground, key cache: <%@> rect: %.0f,%.0f - %.0fx%.0f", key, rect.origin.x, rect.origin.y, rect.size.width,rect.size.height);
	NSImage* img = [[CLCache cache] imageNamed: key];
	
	if (img == nil)
	{
		img = [[NSImage alloc] initWithSize: rect.size];
		[img lockFocus];
		NSColor* start = [NSColor colorWithCalibratedRed: 0.7 green: 0.7 blue: 0.7 alpha: 1.0];
		NSColor* end   = [NSColor colorWithCalibratedRed: 0.9 green: 0.9 blue: 0.9 alpha: 1.0];

		NSRect rg1 = NSMakeRect (rect.origin.x, rect.origin.y, rect.size.width/2, rect.size.height);
		NSRect rg2 = NSMakeRect (rect.origin.x+(rect.size.width/2), rect.origin.y, rect.size.width/2, rect.size.height);

		[GSDrawFunctions drawHorizontalGradient: start to: end frame: rg1];
		[GSDrawFunctions drawHorizontalGradient: end to: start frame: rg2];

		[GraphicToolbox fillRect: rect withImage: [NSImage imageNamed: @"Window-background.tiff"]];
		[img unlockFocus];
		[[CLCache cache] setImage: img named: key];
		[img autorelease];
	}

	[img compositeToPoint: NSMakePoint (rect.origin.x, rect.origin.y) operation: NSCompositeSourceOver];
	*/
	/*
	NSColor* bgd   = [NSColor colorWithCalibratedRed: 0.7 green: 0.7 blue: 0.7 alpha: 1.0];
	[bgd set];
	NSRectFill (rect);
	*/
	[GraphicToolbox fillRect: rect withImage: [NSImage imageNamed: @"Window/Window-background.tiff"]];
}

+ (void) drawPopupButton: (NSRect) border inView: (NSView*) view 
{
	NSGraphicsContext* ctxt = GSCurrentContext ();
	DPSgsave (ctxt);
	//This is quite annoying :-/
	DPSinitclip (ctxt);
	//DPSrectclip (ctxt, border.origin.x, border.origin.y, border.size.width, border.size.height +2);
	[GraphicToolbox drawButton: border 
		withCaps: [NSImage imageNamed: @"PopupButton/PopupButton-endcap.tiff"]
		filledWith: [NSImage imageNamed: @"PopupButton/PopupButton-fill.tiff"]];
	NSImage* arrows = [NSImage imageNamed: @"PopupButton/PopupButton-ArrowEnds.tiff"];	
	float w = ([arrows size].width)/2;
	float h = [arrows size].height;
	NSImage* arrow = [[NSImage alloc] initWithSize: NSMakeSize (w,h)];

	float deltaY = (border.size.height - h)/2;
	
	[arrow lockFocus];
	[arrows compositeToPoint: NSMakePoint (-w,0) operation: NSCompositeSourceOver];
	[arrow unlockFocus];
	
	[arrow compositeToPoint: NSMakePoint (border.origin.x+border.size.width-w,border.origin.y+deltaY) operation: NSCompositeSourceOver];
	DPSgrestore (ctxt);
}

+ (void) drawHorizontalScrollerKnob: (NSRect) knob on: (NSView*) view
{
	[GraphicToolbox drawHorizontalButton: knob 
		withCaps: [NSImage imageNamed: @"Scrollbar/Scrollbar-horizontal-thumb-caps.tiff"]
		filledWith: [NSImage imageNamed: @"Scrollbar/Scrollbar-horizontal-thumb-fill.tiff"]
		withLeftMargin: 0 rightMargin: 0 topMargin: 0 bottomMargin: 0 flipped: [view isFlipped]];
}

+ (void) drawVerticalScrollerKnob: (NSRect) knob on: (NSView*) view
{
	[GraphicToolbox drawVerticalButton: knob 
		withCaps: [NSImage imageNamed: @"Scrollbar/Scrollbar-vertical-thumb-caps.tiff"]
		filledWith: [NSImage imageNamed: @"Scrollbar/Scrollbar-vertical-thumb-fill.tiff"]
		withLeftMargin: 0 rightMargin: 0 topMargin: 0 bottomMargin: 0 flipped: [view isFlipped]];
}

+ (void) drawHorizontalScrollerSlot: (NSRect) slot knobPresent: (BOOL) knob 
	buttonPressed: (int) buttonPressed on: (NSView*) view
{
	if (knob)
	{
		NSImage* leftCap = nil;
		switch (buttonPressed)
		{
			case 1:
				leftCap = [NSImage imageNamed: @"Scrollbar/Scrollbar-horizontal-slot-arrows-left.tiff"];
				break;
			case 2:
				leftCap = [NSImage imageNamed: @"Scrollbar/Scrollbar-horizontal-slot-arrows-right.tiff"];
				break;
			default:
				leftCap = [NSImage imageNamed: @"Scrollbar/Scrollbar-horizontal-slot-arrows-unselected.tiff"];
		}
		[GraphicToolbox drawHorizontalButton: slot
			withLeftCap: leftCap
			rightCap: [NSImage imageNamed: @"Scrollbar/Scrollbar-horizontal-slot-right.tiff"]
			filledWith: [NSImage imageNamed: @"Scrollbar/Scrollbar-horizontal-slot-fill.tiff"]
			flipped: [view isFlipped]];
	}
	else
	{
		[GraphicToolbox drawHorizontalButton: slot
			withLeftCap: [NSImage imageNamed: @"Scrollbar/Scrollbar-horizontal-slot-caps.tiff"]
			rightCap: [NSImage imageNamed: @"Scrollbar/Scrollbar-horizontal-slot-caps.tiff"]
			filledWith: [NSImage imageNamed: @"Scrollbar/Scrollbar-horizontal-slot-caps.tiff"]
			flipped: [view isFlipped]];
	}
}

+ (void) drawVerticalScrollerSlot: (NSRect) slot knobPresent: (BOOL) knob 
	buttonPressed: (int) buttonPressed on: (NSView*) view
{
	if (knob)
	{
		NSImage* downCap = nil;
		switch (buttonPressed)
		{
			case 1:
				downCap = [NSImage imageNamed: @"Scrollbar/Scrollbar-vertical-slot-arrows-bottom.tiff"];
				break;
			case 2:
				downCap = [NSImage imageNamed: @"Scrollbar/Scrollbar-vertical-slot-arrows-top.tiff"];
				break;
			default:
				downCap = [NSImage imageNamed: @"Scrollbar/Scrollbar-vertical-slot-arrows-unselected.tiff"];
		}
		
		[GraphicToolbox drawVerticalButton: slot
			withUpCap: [NSImage imageNamed: @"Scrollbar/Scrollbar-vertical-slot-up.tiff"]
			downCap: downCap
			filledWith: [NSImage imageNamed: @"Scrollbar/Scrollbar-vertical-slot-fill.tiff"]
			flipped: [view isFlipped]];
	}
	else
	{
		[GraphicToolbox drawVerticalButton: slot
			withUpCap: [NSImage imageNamed: @"Scrollbar/Scrollbar-vertical-slot-caps.tiff"]
			downCap: [NSImage imageNamed: @"Scrollbar/Scrollbar-vertical-slot-caps.tiff"]
			filledWith: [NSImage imageNamed: @"Scrollbar/Scrollbar-vertical-slot-caps.tiff"]
			flipped: [view isFlipped]];
	}
}

+ (void) drawTopTabFill: (NSRect) rect selected: (BOOL) selected on: (NSView*) view
{
	NSImage* fill = nil;
	if (selected) fill = [NSImage imageNamed: @"Tabs/Tabs-selected-fill.tiff"];
	else fill = [NSImage imageNamed: @"Tabs/Tabs-unselected-fill.tiff"];

	[GraphicToolbox fillHorizontalRect: rect withImage: fill];
}

+ (void) drawTabFrame: (NSRect) rect on: (NSView*) view
{
	/*
	NSBezierPath* path = [NSBezierPath bezierPathWithRect: rect];
	[[NSColor blackColor] set];
	[path setLineWidth: 0];
	[path stroke];
	*/
	/*
  	NSGraphicsContext     *ctxt = GSCurrentContext();
	DPSsetlinewidth (ctxt, 1);
	[[NSColor blackColor] set];
	DPSrectstroke (ctxt, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	*/
	[GraphicToolbox drawButton: rect
		withCorners: [NSImage imageNamed: @"Tabs/Tabs-pane-corners.tiff"]
		withLeft: [NSImage imageNamed: @"Tabs/Tabs-pane-left.tiff"]
		withRight: [NSImage imageNamed: @"Tabs/Tabs-pane-right.tiff"]
		withTop: [NSImage imageNamed: @"Tabs/Tabs-pane-top.tiff"]
		withBottom: [NSImage imageNamed: @"Tabs/Tabs-pane-bottom.tiff"]
		filledWith: [NSImage imageNamed: @"Tabs/Tabs-pane-fill.tiff"]
		repeatFill: YES
		flipped: [view isFlipped]
	];
	/*
	NSRect rectBar = NSMakeRect (rect.origin.x, rect.origin.y + rect.size.height - 9.0, rect.size.width, 9.0);
	[GraphicToolbox drawButton: rectBar
		withCaps: [NSImage 
			imageNamed: @"Tabs/Tabs-panebar-caps.tiff"]
		filledWith: [NSImage
			imageNamed: @"Tabs/Tabs-panebar-fill.tiff"]];
	*/
	
}

+ (void) drawScrollViewFrame: (NSRect) rect on: (NSView*) view
{
	/*
	NSBezierPath* path = [NSBezierPath bezierPathWithRect: rect];
	[[NSColor blackColor] set];
	[path setLineWidth: 0];
	[path stroke];
	*/
	/*
  	NSGraphicsContext     *ctxt = GSCurrentContext();
	DPSsetlinewidth (ctxt, 1);
	[[NSColor colorWithCalibratedRed: 0.6 green: 0.6 blue: 0.6 alpha: 1.0] set];
	DPSrectstroke (ctxt, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	*/
}

+ (void) drawFocusFrame: (NSRect) cellFrame
{
/*
	NSRect rect = NSMakeRect (cellFrame.origin.x + 1, cellFrame.origin.y + 1, cellFrame.size.width - 2, cellFrame.size.height - 2);
	NSDottedFrameRect (rect);
*/
	NSBezierPath* path = [NSBezierPath bezierPath];
	//NSRect rect = cellFrame;
	NSRect rect = NSMakeRect (cellFrame.origin.x + 1, cellFrame.origin.y + 1, cellFrame.size.width - 2, cellFrame.size.height - 2);
	[path appendBezierPathWithRoundedRectangle: rect withRadius: 8.0];
	//[path appendBezierPathWithRect: rect];
	[[NSColor colorWithCalibratedRed: 0.5 green: 0.5 blue: 1.0 alpha: 0.3] set];
	[path setLineWidth: 5];
	[path stroke];
	[[NSColor colorWithCalibratedRed: 0.5 green: 0.5 blue: 1.0 alpha: 0.5] set];
	[path setLineWidth: 3];
	[path stroke];
	[[NSColor colorWithCalibratedRed: 0.4 green: 0.4 blue: 1.0 alpha: 1.0] set];
	[path setLineWidth: 1];
	[path stroke];
}
@end
