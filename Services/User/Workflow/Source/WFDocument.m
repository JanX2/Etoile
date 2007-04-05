/*
 * WFDocument.m - Workflow
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 03/27/07
 * License: Modified BSD license (see file COPYING)
 */


#import <AppKit/AppKit.h>
#import "WFDocument.h"


@implementation WFDocument

/* NSDocument Methods */

- (NSString *) windowNibName
{
	return @"Document";
}

- (void) windowControllerDidLoadNib: (NSWindowController *)aController
{
	[super windowControllerDidLoadNib: aController];

	// FIXME: This should be set in the interface file (Document.gorm), I'm not
	//        sure how though. (Maybe in a later version of Gorm?)
	[scrollView setDrawsBackground: NO];
}

@end

