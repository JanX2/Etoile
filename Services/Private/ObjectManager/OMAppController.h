/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2011
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#ifndef GNUSTEP
#import <EtoileFoundation/GNUstep.h>
#endif
#import <ObjectMerging/COEditingContext.h>
#import <ObjectMerging/COGroup.h>
#import <EtoileUI/EtoileUI.h>

@class OMLayoutItemFactory;

@interface OMAppController : ETDocumentController
{
	OMLayoutItemFactory *itemFactory;
	NSMutableSet *openedGroups;
}

- (NSArray *) sourceListGroups;

- (IBAction) browseMainGroup: (id)sender;

- (void) buildCoreObjectGraphDemo;

@end
