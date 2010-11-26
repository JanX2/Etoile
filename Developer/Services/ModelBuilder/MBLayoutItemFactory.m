/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2010
	License:  Modified BSD  (see COPYING)
 */

#import <IconKit/IconKit.h>
#import "MBLayoutItemFactory.h"
#import "ETModelRepository.h"
#import "MBPackageEditorController.h" 
#import "MBRepositoryController.h"

@implementation MBLayoutItemFactory

- (ETOutlineLayout *) outlineLayoutForBrowser
{
	ETOutlineLayout *layout = [ETOutlineLayout layout];

	[layout setDisplayedProperties: A(@"displayName", @"typeDescription")];
	[layout setDisplayName: @"Type" forProperty: @"typeDescription"];
	[[layout columnForProperty: @"typeDescription"] setWidth: 100];
	[[layout columnForProperty: @"displayName"] setWidth: 400];

	return layout;
}

- (ETLayoutItem *) buttonWithIconNamed: (NSString *)aName target: (id)aTarget action: (SEL)anAction
{
		return [self buttonWithImage: [[IKIcon iconWithIdentifier: aName] image] target: aTarget action: anAction];
}

- (NSSize) defaultEditorSize
{
	return NSMakeSize(800, 500);
}

- (NSSize) defaultEditorBodySize
{
	NSSize size = [self defaultEditorSize];
	size.height -= [self defaultIconAndLabelBarHeight];
	return size;
}

- (ETLayoutItemGroup *) editorWithPackageDescription: (ETPackageDescription *)aPackageDesc
{
	MBPackageEditorController *controller = AUTORELEASE([[MBPackageEditorController alloc] init]);
	ETLayoutItemGroup *topbar = [self editorTopbarWithController: controller];
	ETLayoutItemGroup *body = [self editorBodyWithPackageDescription: aPackageDesc controller: controller];
	ETLayoutItemGroup *editor = [self itemGroupWithItems: A(topbar, body)];
	
	[editor setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[editor setController: controller];
	[editor setRepresentedObject: aPackageDesc]; /* For MBAppController template lookup needs */
	[editor setShouldMutateRepresentedObject: NO];
	[editor setLayout: [ETColumnLayout layout]];
	[editor setSize: [self defaultEditorSize]];

	return editor;
}

- (ETLayoutItemGroup *) editorBodyWithPackageDescription: (ETPackageDescription *)aPackageDesc controller: (id)aController
{
	ETLayoutItemGroup *sourceList = [self sourceListWithPackageDescription: aPackageDesc controller: aController];
	ETLayoutItemGroup *entityView = [self entityViewWithEntityDescription: [[aPackageDesc contentArray] firstObject]
                                                               controller: aController];
	ETLayoutItemGroup *body = [self itemGroupWithRepresentedObject: aPackageDesc];

	NSLog(@"Entities %@", [aPackageDesc contentArray]);

	[body setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[body setSize: [self defaultEditorBodySize]]; // FIXME: Avoid negative size if -setSize: is not called
	[body setLayout: [ETLineLayout layout]];
	[body addItems: A(sourceList, entityView)];

	return body;
}

- (ETLayoutItem *) viewPopUpWithController: (MBPackageEditorController *)aController
{
	NSArray *choices = A(_(@"Properties"), _(@"Operations"), _(@"Instances"));
	ETLayoutItem *popUpItem = [self popUpMenuWithItemTitles: choices
		                                 representedObjects: nil
		                                             target: aController 
		                                             action: @selector(changePresentedContent:)];

	[aController setViewPopUpItem: popUpItem];
	return popUpItem;
}

- (ETLayoutItem *) modelLayerPopUpWithController: (MBPackageEditorController *)aController
{
	NSArray *choices = A(_(@"Model (M1)"), _(@"Metamodel (M2)"), _(@"Meta-metamodel (M3)"));
	ETLayoutItem *popUpItem = [self popUpMenuWithItemTitles: choices
		                                 representedObjects: nil
		                                             target: aController 
		                                             action: @selector(changePresentedModelLayer:)];

	[(NSPopUpButton *)[popUpItem view] selectItemWithTitle: _(@"Metamodel (M2)")];
	[aController setModelLayerPopUpItem: popUpItem];
	return popUpItem;
}


- (ETLayoutItemGroup *) editorTopbarWithController: (id)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroup];
	ETLayoutItem *addPropertyItem = [self buttonWithIconNamed: @"list-add" 
	                                                   target: aController
	                                                   action: @selector(addProperty:)];
	ETLayoutItem *removeItem = [self buttonWithIconNamed: @"list-remove" 
	                                              target: aController
	                                              action: @selector(remove:)];
	ETLayoutItem *searchFieldItem = [self searchFieldWithTarget: aController 
	                                                     action: @selector(searchPackageDescription:)];
	//ETLayoutItemGroup *searchItemGroup = [self itemGroupWithItem: searchFieldItem];

	[itemGroup setWidth: [self defaultEditorSize].width];
	[itemGroup setHeight: [self defaultIconAndLabelBarHeight]];
	[itemGroup setLayout: [ETLineLayout layout]];
	[[itemGroup layout] setSeparatorTemplateItem: [self flexibleSpaceSeparator]];
	[itemGroup addItems: 
		A([self barElementFromItem: addPropertyItem withLabel: _(@"Add Property")],
		[self barElementFromItem: removeItem withLabel: _(@"Remove")],
		[self barElementFromItem: [self modelLayerPopUpWithController: aController] withLabel: _(@"Model Layer")],
		[self barElementFromItem: [self viewPopUpWithController: aController] withLabel: _(@"Entity View")],
		[self barElementFromItem: searchFieldItem withLabel: _(@"Filter")])];

	return itemGroup;
}

- (ETLayoutItemGroup *) sourceListWithPackageDescription: (ETPackageDescription *)aPackageDesc controller: (id)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroupWithRepresentedObject: aPackageDesc];
	ETController *controller = AUTORELEASE([[ETController alloc] init]);
	ETUTI *entityDescType = [ETUTI typeWithClass: [ETEntityDescription class]];

	/* The current object type is controlled by -[MBPackageEditorController updatePresentedModelLayer] */
	[controller setTemplate: [ETItemTemplate templateWithItem: [self item] objectClass: [ETEntityDescription class]]
	                forType: entityDescType];
	[controller setTemplate: [ETItemTemplate templateWithItem: [self item] objectClass: [ETAdaptiveModelObject class]]
	                forType: [ETUTI typeWithClass: [ETAdaptiveModelObject class]]];
	[controller setCurrentObjectType: entityDescType];

	[itemGroup setController: controller];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleHeight];
	[itemGroup setHeight: [self defaultEditorBodySize].height];
	[itemGroup setWidth: 250];
	[itemGroup setSource: itemGroup];
	[itemGroup setLayout: [ETTableLayout layout]];
	[[itemGroup layout] setDisplayedProperties: A(@"name")];
	[[[itemGroup layout] columnForProperty: @"name"] setWidth: 250];
	[itemGroup setHasVerticalScroller: YES];
	[itemGroup reload];

	[aController setSourceListItem: itemGroup];
	[aController startObserveObject: itemGroup
	            forNotificationName: ETItemGroupSelectionDidChangeNotification
                           selector: @selector(sourceListSelectionDidChange:)];

	return itemGroup;
}

- (ETLayoutItemGroup *) entityViewWithEntityDescription: (ETEntityDescription *)anEntityDesc controller: (id)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroupWithRepresentedObject: anEntityDesc];
	ETTableLayout *layout = [ETTableLayout layout];
	NSArray *headerNames = A(@"Name", @"Item Identifier", @"Derived", 
		@"Container", @"Multivalued", @"Ordered", @"Opposite", @"Type", @"Role");

	[layout setDisplayedProperties: A(@"name", @"itemIdentifier", @"derived", 
		@"container", @"multivalued", @"ordered", @"opposite", @"type", @"role")];

	// FIXME: Assertion at ETCollection+HOM.m:885
	/*[[layout displayedProperties] zipWithCollection: headerNames andBlock: 
	^ void (NSString *property, NSString *headerName)
	{
		[layout setDisplayName: headerName forProperty: property];
	}];

	or
	
	[[layout displayedProperties] enumerateObjectsUsingBlock: 
	^ void (id obj, NSUInteger i, BOOL stop*)
	{
		[layout setDisplayName: [headerNames objectAtIndex: i] forProperty: obj];
	}*/

	NSUInteger n = [[layout displayedProperties] count];
	for (NSUInteger i = 0; i < n; i++)
	{
		[layout setDisplayName: [headerNames objectAtIndex: i] 
		           forProperty: [[layout displayedProperties] objectAtIndex: i]];
	}

	/* The controller templates are set up in -[MBEntityViewController init] */
	[itemGroup setController: AUTORELEASE([[MBEntityViewController alloc] init])];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[itemGroup setHeight: [self defaultEditorBodySize].height];
	[itemGroup setWidth: 550];
	[itemGroup setHasVerticalScroller: YES];
	[itemGroup setSource: itemGroup];
	[itemGroup setLayout: layout];	
	[itemGroup reload];

	[aController setEntityViewItem: itemGroup];

	return itemGroup;
}

- (NSSize) defaultBrowserSize
{
	return NSMakeSize(600, 300);
}

- (ETLayoutItemGroup *) browserWithCollection: (id <ETCollection>)elements
{
	NSParameterAssert(elements != nil);

	ETLayoutItemGroup *browser = [self itemGroupWithRepresentedObject: elements];

	[browser setSource: browser];
	[browser setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[browser setWidth: [self defaultBrowserSize].width]; // FIXME: Avoid negative size if -setSize: is not called
	[browser setHeight: [self defaultBrowserSize].height - [self defaultIconAndLabelBarHeight]];
	[browser setLayout: [self outlineLayoutForBrowser]];
	[browser setHasVerticalScroller: YES];
	[browser reload];

	return browser;
}

- (ETLayoutItemGroup *) browserWithDescriptionCollection: (id <ETCollection>)descriptions
{
	ETLayoutItemGroup *browser = [self browserWithCollection: descriptions];
	ETLog(@"Description collection %@", [descriptions contentArray]);
	return browser;
}

- (ETLayoutItemGroup *) browserBottomBarWithController: (MBRepositoryController *)aController
{
	ETLayoutItem *popUpItem = [self popUpMenuWithItemTitles: A(@"Metamodel | List", @"Metamodel", @"Model", @"", @"List", @"Column")
		                                 representedObjects: nil
		                                             target: aController 
		                                             action: @selector(changeRepositoryPresentation:)];
	NSPopUpButton *popUp = (NSPopUpButton *)[popUpItem view];

	// TODO: Support that in ETLayoutItemFactory
	[popUp setPullsDown: YES];
	[[popUp itemWithTitle: _(@"List")] setState: NSOnState];
	[[popUp itemWithTitle: _(@"Column")] setState: NSOffState];
	[popUpItem sizeToFit];

	ETLayoutItem *saveButtonItem = [self buttonWithIconNamed: @"drive-harddisk" 
	                                                  target: aController 
	                                                  action: @selector(save:)];
	ETLayoutItem *checkButtonItem = [self buttonWithIconNamed: @"system-restart"
	                                                   target: aController 
	                                                   action: @selector(checkRepositoryValidity:)];
	ETLayoutItem *searchFieldItem = [self searchFieldWithTarget: aController 
	                                                     action: @selector(searchRepository:)];
	ETLayoutItemGroup *itemGroup = [self itemGroupWithItems: 
		A([self barElementFromItem: popUpItem withLabel: _(@"View")],
		[self flexibleSpaceSeparator], 
		[self barElementFromItem: saveButtonItem withLabel: _(@"Save")], 
		[self barElementFromItem: checkButtonItem withLabel: _(@"Check")],
		[self flexibleSpaceSeparator],
		[self barElementFromItem: searchFieldItem withLabel: _(@"Filter")])];

	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[itemGroup setWidth: [self defaultBrowserSize].width];
	[itemGroup setHeight: [self defaultIconAndLabelBarHeight]];
	[itemGroup setLayout: [ETLineLayout layout]];

	return itemGroup;
}

- (ETLayoutItemGroup *) browserWithRepository: (ETModelRepository *)aRepo
{
	ETLayoutItemGroup *repositoryViewItem = [self browserWithCollection: [aRepo metaRepository]];
	MBRepositoryController *controller = AUTORELEASE([[MBRepositoryController alloc] init]);
	ETLayoutItemGroup *bottomBar = [self browserBottomBarWithController: controller];
	ETLayoutItemGroup *browser = [self itemGroupWithFrame: ETMakeRect(NSZeroPoint, [self defaultBrowserSize])];

	[repositoryViewItem setController: AUTORELEASE([[ETController alloc] init])];	
	[controller setRepositoryViewItem: repositoryViewItem];

	[browser setController: controller];
	[browser setRepresentedObject: aRepo]; /* For MBRepositoryController needs */
	[browser setShouldMutateRepresentedObject: NO];
	[browser setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[browser setLayout: [ETColumnLayout layout]];
	[browser addItems: A(bottomBar, repositoryViewItem)];

	ETLog(@"\n%@\n", [browser descriptionWithOptions: [NSMutableDictionary dictionaryWithObjectsAndKeys: 
		A(@"frame", @"autoresizingMask"), kETDescriptionOptionValuesForKeyPaths,
		@"items", kETDescriptionOptionTraversalKey, nil]]);

	return browser;
}

- (ETLayoutItemGroup *) checkReportWithWarnings: (NSArray *)warnings
{
	ETLayoutItemGroup *itemGroup = [self itemGroupWithRepresentedObject: warnings];

	[itemGroup setName: _(@"Repository Check Warnings")];
	[itemGroup setSource: itemGroup];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[itemGroup setSize: [self defaultBrowserSize]]; // FIXME: Avoid negative size if -setSize: is not called
	[itemGroup setLayout: [ETTableLayout layout]];

	return itemGroup;
}

@end

