#include "Image.h"

@interface NSImage (flags)
- (void) setArchiveByName: (BOOL) flag;
- (void) setNameForced: (NSString*) aName;
@end

@implementation NSImage (flags)
- (void) setArchiveByName: (BOOL) flag
{
	_flags.archiveByName = flag;
}
- (void) setNameForced: (NSString*) aName
{
	ASSIGN(_name,aName);
}
@end

@implementation Image

Class theNSImageClass;

+ (id) imageNamed: (NSString *)aName
{
	BOOL providedInTheme = YES;
    	NSBundle* bundle = [NSBundle bundleForClass: NSClassFromString(@"Camaelon")];
	NSImage* ret = nil;


	// Get the image in the cache

	ret = [GraphicToolbox imageNamed: aName];

	if (ret == nil)
	{
		if ([aName isEqualToString: @"common_Close"])
		{
			ret = [NSImage imageNamed: @"Window-titlebar-closebutton-unselected.tiff"];
		}
		else if ([aName isEqualToString: @"common_CloseH"])
		{
			ret = [NSImage imageNamed: @"Window-titlebar-closebutton.tiff"];
		}
		else if (([aName isEqualToString: @"common_3DArrowRightH"])
			|| ([aName isEqualToString: @"NSMenuArrowH"]))
		{	
			ret = [NSImage imageNamed: @"Arrows/hierarchical-arrows-selected.tiff"];
		}
		else if (([aName isEqualToString: @"common_3DArrowRight"])
			|| ([aName isEqualToString: @"NSMenuArrow"]))
		{
			ret = [NSImage imageNamed: @"Arrows/hierarchical-arrows-unselected.tiff"];
		}
		else if ([aName isEqualToString: @"common_Nibble"])
		{
			ret = [NSImage imageNamed: @"Arrows/popup-arrows.tiff"];
		}
		else if (([aName isEqualToString: @"common_2DCheckMark"])
			|| ([aName isEqualToString: @"NSMenuCheckmark"]))
		{
			ret = [NSImage imageNamed: @"Arrows/checkmark.tiff"];
		}
		else if ([aName isEqualToString: @"common_Miniaturize"])
		{
			ret = [NSImage imageNamed: @"Window-titlebar-minimizebutton-unselected.tiff"];
		}
		else if ([aName isEqualToString: @"common_MiniaturizeH"])
		{
			ret = [NSImage imageNamed: @"Window-titlebar-minimizebutton.tiff"];
		}
		else if ([aName isEqualToString: @"NSSwitch"]
			|| [aName isEqualToString: @"common_SwitchOff"])
		{
			ret = [NSImage imageNamed: @"Checkbox/Checkbox-unselected.tiff"];
		}
		else if ([aName isEqualToString: @"NSHighlightedSwitch"]
			|| [aName isEqualToString: @"common_SwitchOn"])
		{
			ret = [NSImage imageNamed: @"Checkbox/Checkbox-selected.tiff"];
		}
		else if ([aName isEqualToString: @"NSRadioButton"]
			|| [aName isEqualToString: @"common_RadioOff"])
		{
			ret = [NSImage imageNamed: @"RadioButton/RadioButton-unselected.tiff"];
		}
		else if ([aName isEqualToString: @"NSHighlightedRadioButton"]
			|| [aName isEqualToString: @"common_RadioOn"])
		{
			ret = [NSImage imageNamed: @"RadioButton/RadioButton-selected.tiff"];
		}
		else if ( [aName isEqualToString: @"common_TabSelectedLeft.tiff"] )
		{
			ret = [ImageProvider TabsSelectedLeft];
		}
		else if ( [aName isEqualToString: @"common_TabSelectedRight.tiff"] )
		{
			ret = [ImageProvider TabsSelectedRight];
		}
		else if ( [aName isEqualToString: @"common_TabUnSelectedLeft.tiff"] )
		{
			ret = [ImageProvider TabsUnselectedLeft];
		}
		else if ( [aName isEqualToString: @"common_TabUnSelectedRight.tiff"] )
		{
			ret = [ImageProvider TabsUnselectedRight];
		}
		else if ( [aName isEqualToString: @"common_TabSelectedToUnSelectedJunction.tiff"] )
		{
			ret = [ImageProvider TabsSelectedToUnselectedJunction];
		}
		else if ( [aName isEqualToString: @"common_TabUnSelectToSelectedJunction.tiff"] )
		{
			ret = [ImageProvider TabsUnselectedToSelectedJunction];
		}
		else if ( [aName isEqualToString: @"common_TabUnSelectedJunction.tiff"] )
		{
			ret = [ImageProvider TabsUnselectedJunction];
		}
		
		/*
		else if (
			   [aName isEqualToString: @"common_TabSelectedLeft.tiff"]
			|| [aName isEqualToString: @"common_TabSelectedRight.tiff"]
			|| [aName isEqualToString: @"common_TabSelectedToUnSelectedJunction.tiff"]
			|| [aName isEqualToString: @"common_TabUnSelectToSelectedJunction.tiff"]
			|| [aName isEqualToString: @"common_TabUnSelectedJunction.tiff"]
			|| [aName isEqualToString: @"common_TabUnSelectedLeft.tiff"]
			|| [aName isEqualToString: @"common_TabUnSelectedRight.tiff"]
			)
		{
			NSImage* image = [[NSImage alloc] initWithSize: NSMakeSize (14,17)];
			[image lockFocus];
			if (
			   [aName isEqualToString: @"common_TabSelectedLeft.tiff"]
			|| [aName isEqualToString: @"common_TabUnSelectedLeft.tiff"]
			|| [aName isEqualToString: @"common_TabSelectedToUnSelectedJunction.tiff"]
			|| [aName isEqualToString: @"common_TabUnSelectedJunction.tiff"]
			)
			{
				NSBezierPath* path = [NSBezierPath bezierPath];
				[path moveToPoint: NSMakePoint (0,0)];
				[path curveToPoint: NSMakePoint (14,17) 
				     controlPoint1: NSMakePoint (8, 2) 
				     controlPoint2: NSMakePoint (8, 14)];
				NSBezierPath* background = [NSBezierPath bezierPath];
				[background appendBezierPath: path];
				[background lineToPoint: NSMakePoint (14, 0)];
				[background closePath];
				[[NSColor windowBackgroundColor] set];
				[background fill];
				//[[NSColor blackColor] set];
				[[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.4 alpha: 0.8] set];
				[path setLineWidth: 1.5];
				[[NSColor controlLightHighlightColor] set];
				[path stroke];
			}
			if (
			   [aName isEqualToString: @"common_TabSelectedRight.tiff"]
			|| [aName isEqualToString: @"common_TabUnSelectedRight.tiff"]
			|| [aName isEqualToString: @"common_TabSelectedToUnSelectedJunction.tiff"]
			|| [aName isEqualToString: @"common_TabUnSelectedJunction.tiff"]
			|| [aName isEqualToString: @"common_TabUnSelectToSelectedJunction.tiff"]
			)
			{	
				NSBezierPath* path = [[NSBezierPath alloc] init];
				[path moveToPoint: NSMakePoint (0,17)];
				[path curveToPoint: NSMakePoint (14,0) 
				     controlPoint1: NSMakePoint (8, 14) 
				     controlPoint2: NSMakePoint (8, 2)];
				NSBezierPath* background = [NSBezierPath bezierPath];
				[background appendBezierPath: path];
				[background lineToPoint: NSMakePoint (0, 0)];
				[background closePath];
				[[NSColor windowBackgroundColor] set];
				[background fill];
				//[[NSColor blackColor] set];
				[[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.4 alpha: 0.8] set];
				[[NSColor controlShadowColor] set];
				[path setLineWidth: 1.5];
				[path stroke];
			}
			if ( [aName isEqualToString: @"common_TabUnSelectToSelectedJunction.tiff"] )
			{
				NSBezierPath* path = [NSBezierPath bezierPath];
				[path moveToPoint: NSMakePoint (0,0)];
				[path curveToPoint: NSMakePoint (14,17) 
				     controlPoint1: NSMakePoint (8, 2) 
				     controlPoint2: NSMakePoint (8, 14)];
				NSBezierPath* background = [NSBezierPath bezierPath];
				[background appendBezierPath: path];
				[background lineToPoint: NSMakePoint (14, 0)];
				[background closePath];
				[[NSColor windowBackgroundColor] set];
				[background fill];
				[[NSColor whiteColor] set];
				//[[NSColor blackColor] set];
				[[NSColor colorWithCalibratedRed: 0.3 green: 0.3 blue: 0.4 alpha: 0.8] set];
				[path setLineWidth: 1.5];
				[[NSColor whiteColor] set];
				[[NSColor controlLightHighlightColor] set];
				[path stroke];
			}
			[image unlockFocus];
			ret = [image autorelease];
		}
		*/
		else
		{
			providedInTheme = NO;
		}

		if (providedInTheme == NO)
		{
		//	NSLog (@"Camaelon could'nt provide %@", aName);
		//	ret = [[NSImage alloc] initWithContentsOfFile: [bundle pathForImageResource: aName]];

			NSString* imagePath = [NSString stringWithFormat: 
				@"%@/%@", [[Camaelon sharedTheme] themePath], aName];
			ret = nil;
			if ([[NSFileManager defaultManager]
				fileExistsAtPath: imagePath])
			{
				ret = [[NSImage alloc] initWithContentsOfFile: imagePath];
			}
			if (ret == nil) 
			{
				ret = [super imageNamed: [aName retain]];
			}
		}
		else
		{
			if (ret != nil)
			{
				if(![ret setName: aName])
				{
					[ret setNameForced: aName];
				}
				[ret setArchiveByName: YES];
			}
		}

		if (ret != nil) [GraphicToolbox setImage: ret named: aName];
	}
	return ret;
}

+ (void) setNSImageClass: (Class) aClass
{
	theNSImageClass = aClass;
}

- (Class) classForCoder
{
	return [theNSImageClass class];
}

@end
