#import <AppKit/AppKit.h>
#include "GraphicToolbox.h"

@implementation NSColor (rows)

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
