/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2011
	License:  Modified BSD  (see COPYING)
 */

#import <IconKit/IconKit.h>
#import "OMLayoutItemFactory.h"
#import "OMBrowserController.h"

@implementation OMLayoutItemFactory

- (NSDateFormatter *) dateFormatter
{
	NSDateFormatter *formatter = AUTORELEASE([[NSDateFormatter alloc] 
		initWithDateFormat: @"%1m %B %Y %H:%M" allowNaturalLanguage: YES]);
	[formatter setFormatterBehavior: NSDateFormatterBehavior10_0];
	return formatter;
}

- (ETOutlineLayout *) listLayoutForBrowser
{
	ETOutlineLayout *layout = [ETOutlineLayout layout];
	// TODO: Show the size once we know how to compute the core object sizes 
	// (see TODO in +[COObject newEntityDescription])
	NSArray *headerNames = A(@"", @"Name", @"Modification Date", @"Creation Date", 
		@"Type", @"Version", @"Tags");

	[layout setDisplayedProperties: A(@"icon", @"name", @"modificationDate", @"creationDate", 
		@"typeDescription", @"lastVersionDescription", @"tagDescription")];

	[layout setFormatter: [self dateFormatter] forProperty: @"modificationDate"];
	[layout setFormatter: [self dateFormatter] forProperty: @"creationDate"];
	[layout setEditable: YES forProperty: @"name"];

	[layout setContentFont: [NSFont controlContentFontOfSize: 12]];
	[[layout tableView] setUsesAlternatingRowBackgroundColors: YES];

	[[layout columnForProperty: @"name"] setWidth: 180];
	[[layout columnForProperty: @"modificationDate"] setWidth: 180];
	[[layout columnForProperty: @"creationDate"] setWidth: 180];

	[layout setSortable: YES];

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

	return layout;
}

- (ETOutlineLayout *) iconLayoutForBrowser
{
	return [ETIconLayout layout];
}

- (ETOutlineLayout *) columnLayoutForBrowser
{
	return [ETBrowserLayout layout];
}

- (ETLayoutItem *) buttonWithIconNamed: (NSString *)aName target: (id)aTarget action: (SEL)anAction
{
	NSImage *icon = [[IKIcon iconWithIdentifier: aName] image];
	return [self buttonWithImage: icon target: aTarget action: anAction];
}

- (NSSize) defaultBrowserSize
{
	return NSMakeSize(800, 400);
}

- (NSSize) defaultBrowserBodySize
{
	NSSize size = [self defaultBrowserSize];
	size.height -= [self defaultIconAndLabelBarHeight];
	return size;
}

- (ETLayoutItemGroup *) browserWithGroup: (id <ETCollection>)aGroup
{
	OMBrowserController *controller = AUTORELEASE([[OMBrowserController alloc] init]);
	ETLayoutItemGroup *topBar = [self browserTopBarWithController: controller];
	ETLayoutItemGroup *body = [self browserBodyWithGroup: (id <ETCollection>)aGroup controller: controller];
	ETLayoutItemGroup *browser = [self itemGroupWithItems: A(topBar, body)];

	[browser setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[browser setController: controller];
	[browser setRepresentedObject: aGroup]; /* For OMBrowserController template lookup needs */
	[browser setShouldMutateRepresentedObject: NO];
	[browser setLayout: [ETColumnLayout layout]];
	[browser setSize: [self defaultBrowserSize]];

	ETLog(@"\n%@\n", [browser descriptionWithOptions: [NSMutableDictionary dictionaryWithObjectsAndKeys: 
		A(@"frame", @"autoresizingMask"), kETDescriptionOptionValuesForKeyPaths,
		@"items", kETDescriptionOptionTraversalKey, nil]]);

	return browser;
}

- (ETLayoutItemGroup *) browserBodyWithGroup: (id <ETCollection>)aGroup controller: (id)aController
{
	ETLayoutItemGroup *sourceList = [self sourceListWithGroup: aGroup controller: aController];
	ETLayoutItemGroup *contentView = [self contentViewWithGroup: [[aGroup contentArray] firstObject]
	                                                controller: aController];
	ETLayoutItemGroup *body = [self itemGroupWithRepresentedObject: aGroup];

	NSLog(@"Groups in source list %@", [aGroup contentArray]);

	[body setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[body setSize: [self defaultBrowserBodySize]]; // FIXME: Avoid negative size if -setSize: is not called
	[body setLayout: [ETLineLayout layout]];
	[body addItems: A(sourceList, contentView)];

	return body;
}

- (ETLayoutItem *) viewPopUpWithController: (OMBrowserController *)aController
{
	// TODO: The Column View doesn't seem like a good fit for an Object Manager 
	// unlike a File Manager
	NSArray *choices = A(_(@"Icon"), _(@"List"), _(@"Column"));
	NSArray *templateLayouts = 
		A([self iconLayoutForBrowser], [self listLayoutForBrowser], [self columnLayoutForBrowser]);
	ETLayoutItem *popUpItem = [self popUpMenuWithItemTitles: choices
		                                 representedObjects: templateLayouts
		                                             target: aController 
		                                             action: @selector(changePresentationViewFromPopUp:)];

	[aController setViewPopUpItem: popUpItem];
	[[popUpItem view] selectItemAtIndex: 1];
	return popUpItem;
}

- (ETLayoutItemGroup *) browserTopBarWithController: (id)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroup];
	ETLayoutItem *newGroupItem = [self buttonWithIconNamed: @"list-add" 
	                                                   target: aController
	                                                   action: @selector(addNewGroup:)];
	ETLayoutItem *removeItem = [self buttonWithIconNamed: @"list-remove" 
	                                              target: aController
	                                              action: @selector(remove:)];
	ETLayoutItem *searchFieldItem = [self searchFieldWithTarget: aController 
	                                                     action: @selector(search:)];
	//ETLayoutItemGroup *searchItemGroup = [self itemGroupWithItem: searchFieldItem];

	[itemGroup setWidth: [self defaultBrowserSize].width];
	[itemGroup setHeight: [self defaultIconAndLabelBarHeight]];
	[itemGroup setLayout: [ETLineLayout layout]];
	// FIXME: [[itemGroup layout] setSeparatorTemplateItem: [self flexibleSpaceSeparator]];
	[itemGroup addItems: 
		A([self barElementFromItem: newGroupItem withLabel: _(@"New Tag…")],
		[self barElementFromItem: removeItem withLabel: _(@"Remove")],
		[self barElementFromItem: [self viewPopUpWithController: aController] withLabel: _(@"View")],
		[self barElementFromItem: searchFieldItem withLabel: _(@"Filter")])];
	[itemGroup updateLayout];

	return itemGroup;
}

- (ETLayoutItemGroup *) sourceListWithGroup: (id <ETCollection>)aGroup controller: (id)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroupWithRepresentedObject: aGroup];
	ETSelectTool *tool = [ETSelectTool tool];

	[tool setAllowsEmptySelection: NO];

	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleHeight];
	[itemGroup setHeight: [self defaultBrowserBodySize].height];
	[itemGroup setWidth: 250];
	[itemGroup setSource: itemGroup];
	[itemGroup setLayout: [ETTableLayout layout]];
	[[itemGroup layout] setDisplayedProperties: A(@"displayName")];
	[[[itemGroup layout] columnForProperty: @"displayName"] setWidth: 250];
	[[itemGroup layout] setAttachedTool: tool];
	[itemGroup setHasVerticalScroller: YES];
	[itemGroup reload];

	[aController setSourceListItem: itemGroup];
	[aController startObserveObject: itemGroup
	            forNotificationName: ETItemGroupSelectionDidChangeNotification
                           selector: @selector(sourceListSelectionDidChange:)];

	return itemGroup;
}

- (ETLayoutItemGroup *) contentViewWithGroup: (id <ETCollection>)aGroup controller: (id)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroupWithRepresentedObject: aGroup];

	/* The controller templates are set up in -[MBEntityViewController init] */
	//[itemGroup setController: AUTORELEASE([[MBEntityViewController alloc] init])];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[itemGroup setHeight: [self defaultBrowserBodySize].height];
	// TODO: The width should be computed by the body layout
	[itemGroup setWidth: 550];
	[itemGroup setHasVerticalScroller: YES];
	[itemGroup setSource: itemGroup];
	[itemGroup setLayout: [self listLayoutForBrowser]];	
	[itemGroup setController: AUTORELEASE([[OMBrowserContentController alloc] init])];
	[itemGroup reload];

	[aController setContentViewItem: itemGroup];

	return itemGroup;
}

@end


@implementation ETApplication (ObjectManager)

/** Returns the visible Object menu if there is one already inserted in the 
menu bar, otherwise builds a new instance and returns it. */
- (NSMenuItem *) objectMenuItem
{
	NSMenuItem *menuItem = (id)[[self mainMenu] itemWithTag: ETObjectMenuTag];

	if (menuItem != nil)
		return menuItem;

	menuItem = [NSMenuItem menuItemWithTitle: _(@"Object")
	                                     tag: ETObjectMenuTag
	                                  action: NULL];
	NSMenu *menu = [menuItem submenu];


	[menu addItemWithTitle: _(@"New Object From Template…")
	                action: @selector(add:)
	         keyEquivalent: @""];

	[menu addItemWithTitle:  _(@"New Group")
	                action: @selector(addNewGroup:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Open")
	                action: @selector(open:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Open Selection")
	                action: @selector(openSelection:)
	         keyEquivalent: @""];

	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Close")
	                action: @selector(performClose:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Mark Current Version as…")
	                action: @selector(markVersion:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Revert to…")
	                action: @selector(revertTo:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Browse History…")
	                action: @selector(browseHistory:)
	         keyEquivalent: @""];
			
	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Export…")
	                action: @selector(export:)
	         keyEquivalent: @""];
			
	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Show Infos")
	                action: @selector(showInfos:)
	         keyEquivalent: @""];

	return menuItem;
}

@end
