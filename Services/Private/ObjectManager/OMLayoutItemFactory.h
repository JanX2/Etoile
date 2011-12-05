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
#import <ObjectMerging/COGroup.h>
#import <EtoileUI/EtoileUI.h>

@class OMBrowserController;

@interface OMLayoutItemFactory : ETLayoutItemFactory
{

}

- (ETLayoutItemGroup *) browserWithGroup: (COObject *)aGroup;
- (ETLayoutItemGroup *) browserBodyWithGroup: (id <ETCollection>)aGroup controller: (id)aController;
- (ETLayoutItem *) viewPopUpWithController: (OMBrowserController *)aController;
- (ETLayoutItemGroup *) browserTopBarWithController: (id)aController;
- (ETLayoutItemGroup *) sourceListWithGroup: (id <ETCollection>)aGroup controller: (id)aController;
- (ETLayoutItemGroup *) contentViewWithGroup: (id <ETCollection>)aGroup controller: (id)aController;

@end

@interface ETApplication (ObjectManager)
/** Returns the visible Object menu if there is one already inserted in the 
menu bar, otherwise builds a new instance and returns it. */
- (NSMenuItem *) objectMenuItem;
@end
