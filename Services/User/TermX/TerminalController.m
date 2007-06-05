/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "TerminalController.h"
#import "TXWindow.h"
#import "TXTextView.h"
#import "GNUstep.h"

NSString *TXFontNameUserDefault = @"TXFontNameUserDefault";
NSString *TXFontSizeUserDefault = @"TXFontSizeUserDefault";

static NSPoint window_origin;

@implementation TerminalController

+ (void) initialize
{
	window_origin.x = 200;
	window_origin.y = 200;
}

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
		rect.origin = window_origin;
		window = [[TXWindow alloc] initWithContentRect: rect
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
		[window setController: self];
		[self awakeFromNib];

		/* Prepare to next window */
		if (window_origin.x < 500)
		{
			window_origin.x += 50;
		}
		else
		{
			window_origin.x = 0;
		}
		if (window_origin.y < 500)
		{
			window_origin.y += 50;
		}
		else
		{
			window_origin.y = 0;
		}
	}
	if (window == nil)
	{
		NSLog(@"Internal Error: Cannot load TerminalWindow nib");
	}
	[window makeKeyAndOrderFront: self];
}

- (void) dealloc
{
	/* window is autoreleased when closed */
	/* scrollView is released after been content view */
	/* terminalView is automreleased */
	[super dealloc];
}

- (NSWindow *) window
{
	return window;
}

@end

