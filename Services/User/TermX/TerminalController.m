/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "TerminalController.h"
#import "TXTextView.h"
#import "GNUstep.h"

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
	[terminalView awakeFromNib];
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
		NSRect rect = NSMakeRect(200, 200, 500, 400);
		window = [[NSWindow alloc] initWithContentRect: rect
		                           styleMask: NSTitledWindowMask |
		                                      NSClosableWindowMask |
		                                      NSResizableWindowMask
		                           backing: NSBackingStoreBuffered
		                           defer: NO];
		rect = [[window contentView] bounds];
		NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame: rect];
		[scrollView setBorderType: NSNoBorder];
		[scrollView setHasVerticalScroller: YES];
		[scrollView setHasHorizontalScroller: NO];
		[scrollView setAutoresizesSubviews: YES];
		[scrollView setAutoresizingMask: NSViewWidthSizable |
		                                 NSViewHeightSizable];
		rect.size = [NSScrollView contentSizeForFrameSize: rect.size
					  hasHorizontalScroller: [scrollView hasHorizontalScroller]
					  hasVerticalScroller: [scrollView hasVerticalScroller] 
		              borderType: [scrollView borderType]];
		terminalView = [[TXTextView alloc] initWithFrame: rect];
		[terminalView setDelegate: self];
		[terminalView setEditable: NO];
		[terminalView setSelectable: YES];
		[terminalView setAutoresizingMask: NSViewWidthSizable |
		                                   NSViewHeightSizable];
		[scrollView setDocumentView: terminalView];
		[window setContentView: scrollView];
		DESTROY(scrollView);
		RELEASE(terminalView);
		[window setDelegate: self];
		[self awakeFromNib];
	}
	if (window == nil)
	{
		NSLog(@"Internal Error: Cannot load TerminalWindow nib");
	}
	[window makeKeyAndOrderFront: self];
}

- (void) dealloc
{
	DESTROY(window);
	/* terminalView is automreleased */
	[super dealloc];
}

@end

