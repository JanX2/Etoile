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
	@private
	COEditingContext *_editingContext;
}

/** @taskunit Initialization */

- (id) initWithEditingContext: (COEditingContext *)aContext;

/** @taskunit CoreObject Store Access */

@property (nonatomic, readonly) COEditingContext *editingContext;

/** @taskunit Provided Objects */

@property (nonatomic, readonly) NSArray *sourceListGroups;
@property (nonatomic, readonly) COSmartGroup *allObjectGroup;

/** @taskunit Demo Content */

- (void) registerEntityDescriptionsOfCoreObjectGraphDemo;
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
