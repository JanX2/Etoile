#import <EtoileFoundation/EtoileFoundation.h>

#import "ItemReference.h"
#import "OutlineItem.h"
#import "Document.h"

@implementation ItemReference

+ (ETEntityDescription*)newEntityDescription
{
    ETEntityDescription *itemReference = [ETEntityDescription descriptionWithName: @"ItemReference"];
    [itemReference setParent: (id)@"DocumentItem"];
    
    // FIXME: Hack; we need a common superclass for OutlineItem and ItemReference, or make
    // ItemReference a subclass of OutlineItem
    
    ETPropertyDescription *parentProperty = [ETPropertyDescription descriptionWithName: @"parent"
                                                                                  type: (id)@"Anonymous.OutlineItem"];
    [parentProperty setIsContainer: YES];
    
    ETPropertyDescription *referencedItemProperty = [ETPropertyDescription descriptionWithName: @"referencedItem"
                                                                                          type: (id)@"Anonymous.OutlineItem"];
    [referencedItemProperty setPersistent: YES];
    
    [itemReference setPropertyDescriptions: A(parentProperty, referencedItemProperty)];
    return itemReference;
}

- (id)initWithParent: (OutlineItem*)p referencedItem: (OutlineItem*)ref context: (COObjectGraphContext*)ctx
{
	self = [super initWithObjectGraphContext: ctx];
	[self setParent: p];
    [self setReferencedItem: ref];
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

/* Accessor Methods */

@dynamic parent;
@dynamic referencedItem;

- (OutlineItem*)root
{
	id root = self;
	while ([root parent] != nil)
	{
		root = [root parent];
	}
	return root;
}

- (NSString*)label
{
	return [NSString stringWithFormat: @"Link to %@", [[self referencedItem] UUID]];
}

@end
