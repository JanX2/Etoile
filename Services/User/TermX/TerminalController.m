/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "TerminalController.h"
#import "TerminalView.h"

NSString *TXFontNameUserDefault = @"TXFontNameUserDefault";
NSString *TXFontSizeUserDefault = @"TXFontSizeUserDefault";

@implementation TerminalController

- (IBAction) changeFont: (id) sender
{
	NSFont *font = [sender convertFont: [terminalView font]];
	[terminalView setFont: font];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject: [font fontName] forKey: TXFontNameUserDefault];
	[defaults setFloat: [font pointSize] forKey: TXFontSizeUserDefault];
	[terminalView resizeWindowForTerminal];
}

- (IBAction) closeTerminal: (id) sender
{
	[window performClose: self];
}

- (void) windowDidResize: (NSNotification *) not
{
	[terminalView resizeBuffer];
}

- (void) windowWillClose: (NSNotification *) not
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void) awakeFromNib
{
	[window setReleasedWhenClosed: YES];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *name = [defaults stringForKey: TXFontNameUserDefault];
	if (name)
	{
		float size = [defaults floatForKey: TXFontSizeUserDefault];
		if (size > 5)
		{
			NSFont *font = [NSFont fontWithName: name size: size];
			[terminalView setFont: font];
			[terminalView resizeWindowForTerminal];
		}
	}
}

- (IBAction) showWindow: (id) sender
{
	if (window == nil)
	{
		[NSBundle loadNibNamed: @"TerminalWindow" owner: self];
	}
	if (window == nil)
	{
		NSLog(@"Internal Error: Cannot load TerminalWindow nib");
	}
	[window makeKeyAndOrderFront: self];
}

@end

