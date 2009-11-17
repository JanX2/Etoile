/*
   Copyright (C) 2008 Quentin Mathe <qmathe@club-internet.fr>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <EtoileUI/EtoileUI.h>
#import <CoreObject/CoreObject.h>


@interface ObjectManagerController : NSObject 
{
	ETLayoutItemGroup *objectGraphViewItem;
	NSTextField *ctxtVersionField;
	NSTextField *restoredCtxtVersionField;
	NSTextField *selectionVersionField;
}

/* UI Factory */

- (ETLayoutItemGroup *) objectNavigatorItem;

/* Navigation */

- (COGroup *) startGroup;

- (void) updateUI;

@end


