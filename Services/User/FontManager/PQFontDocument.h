/*
 * PQFontDocument.h - Font Manager
 *
 * Class which represents a font document.
 *
 * Copyright 2007 Isaiah Beerbower.
 *
 * Author: Isaiah Beerbower
 * Created: 11/30/07
 * License: 3-Clause BSD license (see file COPYING)
 */

#import <AppKit/AppKit.h>
#import <GNUstepGUI/GSFontInfo.h>
#import "PQSampleController.h"

@interface PQFontDocument : NSDocument
{
  NSButton *installButton;
  NSButton *installAllButton;
	NSPopUpButton *facePopUpButton;
  NSTableView *infoView;
  NSTabView *tabView;
	NSFont *font;
	
	PQSampleController *sampleController;
	
	NSMutableDictionary *fontInfo;
	NSMutableArray *fontInfoIndex;
}
- (void) install: (id)sender;
- (void) installAll: (id)sender;
- (void) selectFace: (id)sender;
@end
