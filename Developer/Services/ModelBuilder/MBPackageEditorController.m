/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2010
	License:  Modified BSD  (see COPYING)
 */

#import "MBPackageEditorController.h" 

@implementation MBPackageEditorController

@synthesize entityViewItem, sourceListItem, viewPopUpItem, modelLayerPopUpItem, editedEntityDescription, repository;

- (id) retain
{
	NSLog(@"Retain %@ %d", self, [self retainCount]);
	return [super retain];
}

- (void) release
{
	NSLog(@"Release %@ %d", self, [self retainCount]);
	[super release];
}

- (id) autorelease
{
	NSLog(@"Autorelease %@ %d", self, [self retainCount]);
	return [super autorelease];
}

- (id) init
{
	SUPERINIT;
	ASSIGN(repository, [ETModelRepository mainRepository]);
	[self setCurrentObjectType: nil];
	return self;
}

- (void) dealloc
{
	DESTROY(entityViewItem);
	DESTROY(sourceListItem);
	DESTROY(viewPopUpItem);
	DESTROY(modelLayerPopUpItem);
	DESTROY(editedEntityDescription);
	DESTROY(repository);
	[super dealloc];
}

- (void) setEditedEntityDescription: (ETEntityDescription *)entityDesc
{
	ETAssert(entityViewItem != nil);

	ETLog(@"Edit entity %@ named %@", entityDesc, [entityDesc name]);

	ASSIGN(editedEntityDescription, entityDesc);
	[self updatePresentedContent];
}

- (NSArray *) instancesForEntityDescription: (ETEntityDescription *)entityDesc
{
	if (entityDesc == nil) return [NSArray array]; 

	NSMutableArray *instances = [NSMutableArray array];
	ETModelDescriptionRepository *metaRepo = [[self repository] metaRepository];

	FOREACHI([[self repository] objects], obj)
	{
		if ([entityDesc isEqual: [metaRepo entityDescriptionForClass: [obj class]]])
			[instances addObject: obj];
	}

	return instances;
}

- (void) updatePresentedModelLayer
{
	ETAssert(modelLayerPopUpItem != nil);
	NSString *viewName = [[(NSPopUpButton *)[modelLayerPopUpItem view] selectedItem] title];
	id oldRepresentedObject = AUTORELEASE(RETAIN([sourceListItem representedObject]));

	if ([viewName isEqual: _(@"Model (M1)")])
	{
		// FIXME: Should only display the instances that correspond to entities 
		// that belong to the edited package
		[sourceListItem setRepresentedObject: [self repository]];
		[[sourceListItem controller] setCurrentObjectType: [ETUTI typeWithClass: [ETAdaptiveModelObject class]]];
	}
	else if ([viewName isEqual: _(@"Metamodel (M2)")])
	{
		[sourceListItem setRepresentedObject: [[self content] representedObject]];
		[[sourceListItem controller] setCurrentObjectType: [ETUTI typeWithClass: [ETEntityDescription class]]];
	}
	else if ([viewName isEqual: _(@"Meta-metamodel (M3)")])
	{
		NSArray *metamodelDescriptions = [[[self repository] metaRepository] entityDescriptions];

		[[[NSMutableArray arrayWithArray: metamodelDescriptions] filter] 
			isKindOfClass: [ETModelElementDescription class]];

		[sourceListItem setRepresentedObject: [metamodelDescriptions contentArray]];
		[[sourceListItem controller] setCurrentObjectType: [ETUTI typeWithClass: [ETEntityDescription class]]];
	}
	else
	{
		ETAssertUnreachable();
	}

	// NOTE: We don't use -isEqual: to handle nil cases transparently
	if ([sourceListItem representedObject] == oldRepresentedObject) 
		return;

	[sourceListItem reloadAndUpdateLayout];
	/* Will trigger -sourceListSelectionDidChange: to update the other UI parts */
	[sourceListItem setSelectionIndex: 0];
}

- (void) updatePresentedContent
{
	ETAssert(viewPopUpItem != nil);
	NSString *viewName = [[(NSPopUpButton *)[viewPopUpItem view] selectedItem] title];
	id oldRepresentedObject = AUTORELEASE(RETAIN([sourceListItem representedObject]));

	if ([viewName isEqual: _(@"Properties")])
	{
		[entityViewItem setRepresentedObject: editedEntityDescription]; 
		[[entityViewItem controller] setCurrentObjectType: [ETUTI typeWithClass: [ETPropertyDescription class]]];
	}
	else if ([viewName isEqual: _(@"Operations")])
	{
		// TODO: Implement...
		ETLog(@"WARNING: Operations view is not implemented.");
	}
	else if ([viewName isEqual: _(@"Instances")])
	{
		[entityViewItem setRepresentedObject: [self instancesForEntityDescription: editedEntityDescription]];
		[[entityViewItem controller] setCurrentObjectType: [ETUTI typeWithClass: [ETAdaptiveModelObject class]]];
	}
	else
	{
		ETAssertUnreachable();
	}

	// NOTE: We don't use -isEqual: to handle nil cases transparently
	if ([entityViewItem representedObject] == oldRepresentedObject) 
		return;

	[entityViewItem reloadAndUpdateLayout];
	[entityViewItem setSelectionIndex: NSNotFound];
}

- (void) sourceListSelectionDidChange: (NSNotification *)aNotif
{
	ETLog(@"Did change selection in %@", [aNotif object]);
	NSArray *selectedItems = [[aNotif object] selectedItemsInLayout];
	[self setEditedEntityDescription: [[selectedItems firstObject] representedObject]];
}

- (IBAction) browseRepository: (id)sender
{
	// FIXME: Implement -repository
	//ETModelDescriptionRepository *repo = [[entityViewItem representedObject] repository];
	//[[itemFactory windowGroup] addItem: [itemFactory browserWithRepository: repo]];
}

- (IBAction) applyChanges: (id)sender
{
	ETLog(@"WARNING: Apply Changes is not implemented.");
}

- (IBAction) changePresentedModelLayer: (id)sender
{
	[self updatePresentedModelLayer];
}

- (IBAction) changePresentedContent: (id)sender
{
	[self updatePresentedContent];
}

- (IBAction) add: (id)sender
{
	id firstResponder = [[ETTool activeTool] firstKeyResponder];
	ETLayoutItem *activeItem = nil;

	NSLog(@"First responder %@", firstResponder);

	if ([firstResponder isView])
	{
		activeItem = [firstResponder owningItem];
	}
	else if ([firstResponder isLayoutItem])
	{
		activeItem = firstResponder;
	}
	NSLog(@"Active item %@", activeItem);

	if ([activeItem isEqual: sourceListItem]
	 || [activeItem isEqual: entityViewItem])
	{
		[[(ETLayoutItemGroup *)activeItem controller] add: sender];
	}
}

// NOTE: Could be cleaner to move it in a MBSourceListController class. For now 
// we use a generic ETController on the source list item.
- (IBAction) addNewEntityDescription: (id)sender
{
	[[[self sourceListItem] controller] add: sender];
}

- (IBAction) addNewPropertyDescription: (id)sender
{
	[[[self entityViewItem] controller] add: sender];
}

- (IBAction) addNewOperation: (id)sender
{
	ETLog(@"WARNING: Add new operation is not implemented.");
	// TODO: [self add: sender];
}

- (IBAction) addNewInstance: (id)sender
{
	ETLog(@"WARNING: Add new instance is not implemented.");
	[[[self entityViewItem] controller] add: sender];
}

- (IBAction) checkPackageDescriptionValidity: (id)sender
{

}

@end


@implementation MBEntityViewController

- (id) init
{
	SUPERINIT;

	ETLayoutItem *item = [[ETLayoutItemFactory factory] item]; 
	ETUTI *propertyDescType = [ETUTI typeWithClass: [ETPropertyDescription class]];

	/* The current object type is controlled by -[MBPackageEditorController updatePresentedContent] */
	[self setCurrentObjectType: propertyDescType];
	[self setTemplate: [ETItemTemplate templateWithItem: item objectClass: [ETPropertyDescription class]]
	          forType: propertyDescType];
	[self setTemplate: [ETItemTemplate templateWithItem: item objectClass: [ETAdaptiveModelObject class]]
	  forType: [ETUTI typeWithClass: [ETAdaptiveModelObject class]]];

	return self;
}

- (IBAction) changePresentedContent: (id)sender
{
	
}

@end
