/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <AppKit/AppKit.h>

extern NSString *TXFontNameUserDefault;
extern NSString *TXFontSizeUserDefault;

@class TXTextView;
@class TXWindow;

@interface TerminalController: NSObject
{
	TXTextView *terminalView;
	TXWindow *window;
}

- (IBAction) showWindow: (id) sender;
- (IBAction) closeTerminal: (id) sender;

- (NSWindow *) window;

@end

