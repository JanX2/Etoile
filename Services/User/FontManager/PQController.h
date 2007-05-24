/*
 * PQController.h - Font Manager
 *
 * Controller for installed font list & main window.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 05/24/07
 * License: Modified BSD license (see file COPYING)
 */

#import <Cocoa/Cocoa.h>
#import "PQSampleController.h"
#import "PQFontFamily.h"

@interface PQController : NSObject
{
  IBOutlet NSOutlineView *fontList;
	IBOutlet NSTableView *groupList;
	IBOutlet PQSampleController *sampleController;
	
	NSMutableArray *fontFamilies; // All font families
}
@end