#include "ImageProvider.h"

@implementation ImageProvider

+ (NSImage*) leftPartOfImage: (NSImage*) base
{
	NSSize size = NSMakeSize ([base size].width/2.0, [base size].height);
	NSImage* ret = [[[NSImage alloc] initWithSize: size] autorelease];
	
	[ret lockFocus];
	[base compositeToPoint: NSMakePoint (0,0) operation: NSCompositeSourceOver];
	[ret unlockFocus];

	return ret;
}

+ (NSImage*) rightPartOfImage: (NSImage*) base
{
	NSSize size = NSMakeSize ([base size].width/2.0, [base size].height);
	NSImage* ret = [[[NSImage alloc] initWithSize: size] autorelease];
	
	[ret lockFocus];
	[base compositeToPoint: NSMakePoint (-[base size].width/2.0,0) operation: NSCompositeSourceOver];
	[ret unlockFocus];

	return ret;
}

+ (NSImage*) TabsSelectedLeft
{
	NSImage* ret = nil;
	NSString* key = @"TabsSelectedLeft"; 
	ret = [[CLCache cache] imageNamed: key];
	if (ret == nil)
	{
		ret = [NSImage imageNamed: @"Tabs/Tabs-junction-selected-left.tiff"];
		if (ret == nil)
		{
			ret = [ImageProvider leftPartOfImage: [NSImage imageNamed: @"Tabs/Tabs-selected-caps.tiff"]];
		}
		[[CLCache cache] setImage: ret named: key];
	}
	return ret;
}

+ (NSImage*) TabsSelectedRight
{
	NSImage* ret = nil;
	NSString* key = @"TabsSelectedRight";
	ret = [[CLCache cache] imageNamed: key];
	if (ret == nil)
	{
		ret = [NSImage imageNamed: @"Tabs/Tabs-junction-selected-right.tiff"];
		if (ret == nil)
		{
			ret = [ImageProvider rightPartOfImage: [NSImage imageNamed: @"Tabs/Tabs-selected-caps.tiff"]];
		}
		[[CLCache cache] setImage: ret named: key];
	}
	return ret;
}

+ (NSImage*) TabsUnselectedLeft
{
	NSImage* ret = nil;
	NSString* key = @"TabsUnselectedLeft";
	ret = [[CLCache cache] imageNamed: key];
	if (ret == nil)
	{
		ret = [NSImage imageNamed: @"Tabs/Tabs-junction-unselected-left.tiff"];
		if (ret == nil)
		{
			ret = [ImageProvider leftPartOfImage: [NSImage imageNamed: @"Tabs/Tabs-unselected-caps.tiff"]];
		}
		[[CLCache cache] setImage: ret named: key];
	}
	return ret;
}

+ (NSImage*) TabsUnselectedRight
{
	NSImage* ret = nil;
	NSString* key = @"TabsUnselectedRight";
	ret = [[CLCache cache] imageNamed: key];
	if (ret == nil)
	{
		ret = [NSImage imageNamed: @"Tabs/Tabs-junction-unselected-right.tiff"];
		if (ret == nil)
		{
			ret = [ImageProvider rightPartOfImage: [NSImage imageNamed: @"Tabs/Tabs-unselected-caps.tiff"]];
		}
		[[CLCache cache] setImage: ret named: key];
	}
	return ret;
}

+ (NSImage*) TabsUnselectedJunction
{
	NSString* key = @"TabsUnselectedJunction";
	NSImage* ret = [[CLCache cache] imageNamed: key];
	if (ret == nil)
	{
		NSImage* left = [ImageProvider TabsUnselectedRight];
		NSImage* right = [ImageProvider TabsUnselectedLeft];
		NSSize size = NSMakeSize ([left size].width+[right size].width,[left size].height);
		ret = [[[NSImage alloc] initWithSize: size] autorelease];

		[ret lockFocus];
			[left compositeToPoint: NSMakePoint (0,0) 
				operation: NSCompositeSourceOver];
			[right compositeToPoint: NSMakePoint ([left size].width,0) 
				operation: NSCompositeSourceOver];
		[ret unlockFocus];
		[[CLCache cache] setImage: ret named: key];
	}
	return ret;
}

+ (NSImage*) TabsUnselectedToSelectedJunction
{
	NSString* key = @"TabsUnselectedToSelectedJunction";
	NSImage* ret = [[CLCache cache] imageNamed: key];
	if (ret == nil)
	{
		ret = [NSImage imageNamed: @"Tabs/Tabs-junction-unselected-selected.tiff"];
		if (ret == nil)
		{
			NSImage* left = [ImageProvider TabsUnselectedRight];
			NSImage* right = [ImageProvider TabsSelectedLeft];
			NSSize size = NSMakeSize ([left size].width+[right size].width,[left size].height);
			ret = [[[NSImage alloc] initWithSize: size] autorelease];

			[ret lockFocus];
				[left compositeToPoint: NSMakePoint (0,0) 
					operation: NSCompositeSourceOver];
				[right compositeToPoint: NSMakePoint ([left size].width,0) 
					operation: NSCompositeSourceOver];
			[ret unlockFocus];
		}
		[[CLCache cache] setImage: ret named: key];
	}
	return ret;
}

+ (NSImage*) TabsSelectedToUnselectedJunction
{
	NSString* key = @"TabsSelectedToUnselectedJunction";
	NSImage* ret = [[CLCache cache] imageNamed: key];
	if (ret == nil)
	{
		ret = [NSImage imageNamed: @"Tabs/Tabs-junction-selected-unselected.tiff"];
		if (ret == nil)
		{
			NSImage* left = [ImageProvider TabsSelectedRight];
			NSImage* right = [ImageProvider TabsUnselectedLeft];
			NSSize size = NSMakeSize ([left size].width+[right size].width,[left size].height);
			ret = [[[NSImage alloc] initWithSize: size] autorelease];

			[ret lockFocus];
				[left compositeToPoint: NSMakePoint (0,0) 
					operation: NSCompositeSourceOver];
				[right compositeToPoint: NSMakePoint ([left size].width,0) 
					operation: NSCompositeSourceOver];
			[ret unlockFocus];
		}
		[[CLCache cache] setImage: ret named: key];
	}
	return ret;
}

@end
