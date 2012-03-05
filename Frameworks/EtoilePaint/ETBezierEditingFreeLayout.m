// Temporary testing class

#import <EtoileFoundation/Macros.h>
#import <EtoileUI/ETFreeLayout.h>
#import <EtoileUI/ETComputedLayout.h>
#import <EtoileUI/ETGeometry.h>
#import <EtoileUI/ETHandle.h>
#import <EtoileUI/ETLayoutItemFactory.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/EtoileUIProperties.h>
#import <EtoileUI/ETSelectTool.h>
#import <EtoileUI/NSView+Etoile.h>
#import <EtoileUI/ETCompatibility.h>

#import "ETBezierHandle.h"

@interface ETBezierFreeLayout : ETFreeLayout
{
}
@end

@implementation ETBezierFreeLayout

- (void) showHandlesForItem: (ETLayoutItem *)item
{
	ETHandleGroup *handleGroup = AUTORELEASE([[ETBezierHandleGroup alloc] initWithManipulatedObject: item]);
		
	[[self layerItem] addItem: handleGroup];
	// FIXME: Should [handleGroup display]; and display should retrieve the 
	// bounding box of the handleGroup. This bouding box would include the 
	// handles unlike the frame.
	// Finally we should use -setNeedsDisplay:
	//[[self layerItem] display];
	[handleGroup setNeedsDisplay: YES];
	[item setNeedsDisplay: YES];
}

- (void) hideHandlesForItem: (ETLayoutItem *)item
{
	FOREACHI([[self layerItem] items], utilityItem)
	{
		if ([utilityItem isKindOfClass: [ETBezierHandleGroup class]] == NO)
			continue;

		if ([[utilityItem manipulatedObject] isEqual: item])
		{
			[utilityItem setNeedsDisplay: YES]; /* Propagate the damaged area upwards */
			[item setNeedsDisplay: YES];
			[[self layerItem] removeItem: utilityItem];
			break;
		}
	}
	// FIXME: Should [handleGroup display]; and -display should retrieve the 
	// bounding box of the handleGroup. This bouding box would include the 
	// handles unlike the frame. 
	// Finally we should use -setNeedsDisplay:
	//[[self layerItem] display];
}

- (void) buildHandlesForItems: (NSArray *)manipulatedItems
{
	[[self layerItem] removeAllItems];

	FOREACH(manipulatedItems, item, ETLayoutItem *)
	{
		if ([item isSelected])
		{
			ETHandleGroup *handleGroup = AUTORELEASE([[ETBezierHandleGroup alloc] initWithManipulatedObject: item]);
			[[self layerItem] addItem: handleGroup];
		}
	}
}

@end
