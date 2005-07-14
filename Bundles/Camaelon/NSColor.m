#include "NSColor.h"

@implementation NSColor (theme)

static NSColor* titlebarTextColor;

+ (void) setSystemColorList
{
	NSColorList* systemColors = [NSColorList colorListNamed: @"System"];

	if (systemColors == nil)
	{
		systemColors = [[NSColorList alloc] initWithName: @"System"];
	}

	[systemColors setColor: [NSColor titlebarTextColor] 
		forKey: @"titlebarTextColor"];
	[systemColors setColor: [NSColor selectedTitlebarTextColor] 
		forKey: @"selectedTitlebarTextColor"];
	[systemColors setColor: [NSColor rowBackgroundColor]
		forKey: @"rowBackgroundColor"];
	[systemColors setColor: [NSColor alternateRowBackgroundColor]
		forKey: @"alternateRowBackgroundColor"];
	[systemColors setColor: [NSColor rowTextColor]
		forKey: @"rowTextColor"];
	[systemColors setColor: [NSColor selectedRowBackgroundColor]
		forKey: @"selectedRowBackgroundColor"];
	[systemColors setColor: [NSColor selectedRowTextColor]
		forKey: @"selectedRowTextColor"];
	[systemColors setColor: [NSColor selectedControlColor]
		forKey: @"selectedControlColor"];
	[systemColors setColor: [NSColor selectedTextColor]
		forKey: @"selectedTextColor"];
	[systemColors setColor: [NSColor selectedTextBackgroundColor]
		forKey: @"selectedTextBackgroundColor"];
	[systemColors setColor: [NSColor selectedMenuItemColor]
		forKey: @"selectedMenuItemColor"];
	[systemColors setColor: [NSColor windowBackgroundColor]
		forKey: @"windowBackgroundColor"];
	[systemColors setColor: [NSColor controlBackgroundColor]
		forKey: @"controlBackgroundColor"];


	//[systemColors writeToFile: nil];
}

+ (NSColor*) titlebarTextColor
{
	if (titlebarTextColor == nil)
	{
		titlebarTextColor = [GraphicToolbox readColorFromImage:
			[NSImage imageNamed: @"Colors/Colors-titlebar-text.tiff"]];
		[titlebarTextColor retain];
	}
	return titlebarTextColor;
}

static NSColor* selectedTitlebarTextColor;

+ (NSColor*) selectedTitlebarTextColor
{
	if (selectedTitlebarTextColor == nil)
	{
		selectedTitlebarTextColor = [GraphicToolbox readColorFromImage:
			[NSImage imageNamed: @"Colors/Colors-selected-titlebar-text.tiff"]];
		[selectedTitlebarTextColor retain];
	}
	return selectedTitlebarTextColor;
}

static NSColor* rowBackgroundColor;

+ (NSColor*) rowBackgroundColor
{
	if (rowBackgroundColor == nil)
	{
		rowBackgroundColor = [GraphicToolbox readColorFromImage:
			[NSImage imageNamed: @"Colors/Colors-row-background.tiff"]];
		[rowBackgroundColor retain];
	}
	return rowBackgroundColor;
}

static NSColor* alternateRowBackgroundColor;

+ (NSColor*) alternateRowBackgroundColor
{
	if (alternateRowBackgroundColor == nil)
	{
		alternateRowBackgroundColor = [GraphicToolbox readColorFromImage:
			[NSImage imageNamed: @"Colors/Colors-alternate-row-background.tiff"]];
		[alternateRowBackgroundColor retain];
	}
	return alternateRowBackgroundColor;
}

static NSColor* rowTextColor;

+ (NSColor*) rowTextColor
{
	if (rowTextColor == nil)
	{
		rowTextColor = [GraphicToolbox readColorFromImage:
			[NSImage imageNamed: @"Colors/Colors-row-text.tiff"]];
		[rowTextColor retain];
	}
	return rowTextColor;
}

static NSColor* selectedRowBackgroundColor;

+ (NSColor*) selectedRowBackgroundColor
{
	if (selectedRowBackgroundColor == nil)
	{
		selectedRowBackgroundColor = [GraphicToolbox readColorFromImage: 
		[NSImage imageNamed: @"Colors/Colors-selected-row-background.tiff"]];
		[selectedRowBackgroundColor retain];
	}
	return selectedRowBackgroundColor;
}

static NSColor* selectedRowTextColor;

+ (NSColor*) selectedRowTextColor
{
	if (selectedRowTextColor == nil)
	{
		selectedRowTextColor = [GraphicToolbox readColorFromImage:
			[NSImage imageNamed: @"Colors/Colors-selected-row-text.tiff"]];
		[selectedRowTextColor retain];
	}
	return selectedRowTextColor;
}

static NSColor* selectedControlColor;

+ (NSColor*) selectedControlColor 
{
	if (selectedControlColor == nil)
	{
		selectedControlColor = [GraphicToolbox readColorFromImage:
		[NSImage imageNamed: @"Colors/Colors-selected-control.tiff"]];
		[selectedControlColor retain];
	}
	return selectedControlColor;
}

static NSColor* selectedTextColor;

+ (NSColor*) selectedTextColor 
{
	if (selectedTextColor == nil)
	{
		selectedTextColor = [GraphicToolbox readColorFromImage:
		[NSImage imageNamed: @"Colors/Colors-selected-text.tiff"]];
		[selectedTextColor retain];
	}
	return selectedTextColor;
}

static NSColor* selectedTextBackgroundColor;

+ (NSColor*) selectedTextBackgroundColor 
{
	if (selectedTextBackgroundColor == nil)
	{
		selectedTextBackgroundColor = [GraphicToolbox readColorFromImage:
		[NSImage imageNamed: @"Colors/Colors-selected-text-background.tiff"]];
		[selectedTextBackgroundColor retain];
	}
	return selectedTextBackgroundColor;
}

static NSColor* selectedMenuItemColor;

+ (NSColor*) selectedMenuItemColor 
{
	if (selectedMenuItemColor == nil)
	{
		selectedMenuItemColor = [GraphicToolbox readColorFromImage:
		[NSImage imageNamed: @"Colors/Colors-selected-text-background.tiff"]];
		[selectedMenuItemColor retain];
	}
	return selectedMenuItemColor;
}

static NSColor* windowBackgroundColor;

+ (NSColor*) windowBackgroundColor 
{
	if (windowBackgroundColor == nil)
	{
		windowBackgroundColor = [GraphicToolbox readColorFromImage:
		[NSImage imageNamed: @"Colors/Colors-window-background.tiff"]];
		[windowBackgroundColor retain];
	}
	return windowBackgroundColor;
}

static NSColor* controlBackgroundColor;

+ (NSColor*) controlBackgroundColor 
{
	if (controlBackgroundColor == nil)
	{
		controlBackgroundColor = [GraphicToolbox readColorFromImage:
		[NSImage imageNamed: @"Colors/Colors-control-background.tiff"]];
		[controlBackgroundColor retain];
	}
	return controlBackgroundColor;
}

@end
