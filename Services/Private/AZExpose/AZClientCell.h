/*
 *  AZExpose - A window switcher for GNUstep
 *  Copyright (C) 2007 Yen-Ju Chen
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the MIT license. See COPYING.
 */

#import <AppKit/AppKit.h>

@class AZClient;

@interface AZClientCell: NSActionCell
{
	AZClient *client;
	NSSize textSize;
	NSAttributedString *title;
	NSImage *icon;
}

- (void) setClient: (AZClient *) client;
- (AZClient *) client;

@end

