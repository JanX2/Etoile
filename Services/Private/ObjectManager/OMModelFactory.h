/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  March 2013
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileFoundation/EtoileFoundation.h>
#ifndef GNUSTEP
#import <EtoileFoundation/GNUstep.h>
#endif
#import <CoreObject/CoreObject.h>
#import <EtoileUI/EtoileUI.h>

@interface OMModelFactory : NSObject
{

}

- (NSArray *) sourceListGroups;

- (void) buildCoreObjectGraphDemo;

@end

// TODO: Allow icon customization without subclassing... For COCollection at least.
@interface OMGroup : COGroup
- (NSImage *) icon;
@end

@interface OMSmartGroup : COSmartGroup
- (NSImage *) icon;
@end

@interface COContainer (OMNote)
+ (NSArray *) menuItems;
@end
