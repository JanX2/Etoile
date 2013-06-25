/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2011
	License:  Modified BSD  (see COPYING)
 */

#import <IconKit/IconKit.h>
#import "OMLayoutItemFactory.h"
#import "OMBrowserController.h"
#import "OMBrowserContentController.h"

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
		@"typeDescription", @"revisionDescription", @"tagDescription")];

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

- (ETLayout *) noteLayoutForBrowser
{
	return nil;
}

- (ETLayoutItem *) buttonWithIconNamed: (NSString *)aName target: (id)aTarget action: (SEL)anAction
{
	NSImage *icon = [[IKIcon iconWithIdentifier: aName] image];
	return [self buttonWithImage: icon target: aTarget action: anAction];
}

- (NSSize) defaultBrowserSize
{
	return NSMakeSize(900, 500);
}

- (NSSize) defaultBrowserTopBarSize
{
	NSSize size = [self defaultBrowserSize];
	size.height= [self defaultIconAndLabelBarHeight];
	return size;
}

- (NSSize) defaultBrowserBodySize
{
	NSSize size = [self defaultBrowserSize];
	size.height -= [self defaultBrowserTopBarSize].height;
	return size;
}

- (CGFloat) defaultSourceListWidth
{
	return 180;
}

- (NSSize) defaultSourceListSize
{
	NSSize size = [self defaultBrowserSize];
	size.width = [self defaultSourceListWidth];
	return size;
}

- (CGFloat) defaultContentViewWidth
{
	return [self defaultBrowserBodySize].width - [self defaultSourceListWidth];
}

- (CGFloat) defaultTagFilterEditorHeight
{
	return 100;
}

- (CGFloat) defaultInspectorWidth
{
	return 400;
}

- (ETLayoutItemGroup *) browserWithGroup: (id <ETCollection>)aGroup editingContext: (COEditingContext *)aContext;
{
	OMBrowserController *controller = AUTORELEASE([[OMBrowserController alloc] init]);
	[controller setPersistentObjectContext: aContext];
	ETLayoutItemGroup *topBar = [self browserTopBarWithController: controller];
	ETLayoutItemGroup *body = [self browserBodyWithGroup: (id <ETCollection>)aGroup controller: controller];
	ETLayoutItemGroup *browser = [self itemGroupWithSize: [self defaultBrowserSize]];

	[browser setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[browser setController: controller];
	[browser setRepresentedObject: aGroup]; /* For OMBrowserController template lookup needs */
	[browser setShouldMutateRepresentedObject: NO];
	[browser setLayout: [ETColumnLayout layout]];
	[browser addItems: A(topBar, body)];
	

	ETLog(@"\n%@\n", [browser descriptionWithOptions: [NSMutableDictionary dictionaryWithObjectsAndKeys: 
		A(@"frame", @"autoresizingMask"), kETDescriptionOptionValuesForKeyPaths,
		@"items", kETDescriptionOptionTraversalKey, nil]]);

	return browser;
}

- (ETLayoutItemGroup *) browserBodyWithGroup: (id <ETCollection>)aGroup controller: (id)aController
{
	ETLayoutItemGroup *sourceList = [self sourceListWithGroup: aGroup controller: aController];
	ETLayoutItemGroup *contentViewWrapper = [self contentViewWrapperWithGroup: [[aGroup contentArray] firstObject]
	                                                               controller: aController];
	ETLayoutItemGroup *body = [self itemGroupWithSize: [self defaultBrowserBodySize]];

	NSLog(@"Groups in source list %@", [aGroup contentArray]);

	[body setIdentifier: @"browserBody"];
	[body setRepresentedObject: aGroup];
	[body setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[body setLayout: [ETLineLayout layout]];
	[body addItems: A(sourceList, contentViewWrapper)];

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
	ETLayoutItemGroup *itemGroup = [self itemGroupWithSize: [self defaultBrowserTopBarSize]];
	ETLayoutItem *newGroupItem = [self buttonWithIconNamed: @"list-add" 
	                                                   target: aController
	                                                   action: @selector(addNewTag:)];
	ETLayoutItem *newObjectItem = [self buttonWithIconNamed: @"list-add"
	                                                 target: aController
	                                                 action: @selector(add:)];
	ETLayoutItem *removeItem = [self buttonWithIconNamed: @"list-remove" 
	                                              target: aController
	                                              action: @selector(remove:)];
	ETLayoutItem *searchFieldItem = [self searchFieldWithTarget: aController 
	                                                     action: @selector(search:)];
	ETLayoutItem *filterFieldItem = [self searchFieldWithTarget: aController
	                                                     action: @selector(filter:)];
	ETLayoutItemGroup *leftItemGroup = [self itemGroup];
	ETLayoutItemGroup *rightItemGroup = [self itemGroup];

	[searchFieldItem setWidth: 140];
	[(NSSearchFieldCell *)[[searchFieldItem view] cell] setSendsSearchStringImmediately: YES];
	[searchFieldItem setIdentifier: @"searchField"];

	[filterFieldItem setWidth: 200];
	[[[[filterFieldItem view] cell] cancelButtonCell] setAction: @selector(resetTagFiltering:)];
	[[[[filterFieldItem view] cell] cancelButtonCell] setTarget: aController];
	[filterFieldItem setIdentifier: @"tagFilterField"];

	[itemGroup setIdentifier: @"browserTopBar"];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth];
	[itemGroup setLayout: [ETLineLayout layout]];
	[[itemGroup layout] setSeparatorTemplateItem: [self flexibleSpaceSeparator]];

	[leftItemGroup setLayout: [ETLineLayout layout]];
	[[leftItemGroup layout] setIsContentSizeLayout: YES];
	[leftItemGroup addItems:
	 	A([self barElementFromItem: newGroupItem withLabel: _(@"New Tag…")],
		  [self barElementFromItem: newObjectItem withLabel: _(@"New Object")],
		  [self barElementFromItem: removeItem withLabel: _(@"Remove")])];

	[rightItemGroup setLayout: [ETLineLayout layout]];
	[[rightItemGroup layout] setIsContentSizeLayout: YES];
	[rightItemGroup addItems:
		A([self barElementFromItem: [self viewPopUpWithController: aController] withLabel: _(@"View")],
		  [self barElementFromItem: filterFieldItem withLabel: _(@"Tag Filter")],
		  [self barElementFromItem: searchFieldItem withLabel: _(@"Search")])];
	
	[itemGroup addItems: A(leftItemGroup, rightItemGroup)];

	return itemGroup;
}

- (ETLayoutItemGroup *) sourceListWithGroup: (id <ETCollection>)aGroup controller: (id)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroupWithSize: [self defaultSourceListSize]];
	ETSelectTool *tool = [ETSelectTool tool];

	[tool setAllowsEmptySelection: NO];

	[itemGroup setIdentifier: @"browserSourceList"];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleHeight];
	[itemGroup setRepresentedObject: aGroup];
	[itemGroup setLayout: [ETOutlineLayout layout]];
	[[itemGroup layout] setContentFont: [NSFont controlContentFontOfSize: [NSFont smallSystemFontSize]]];
	[[itemGroup layout] setDisplayedProperties: A(@"icon", @"displayName")];
	[[[itemGroup layout] columnForProperty: @"displayName"] setWidth: [self defaultSourceListWidth]];
	[[[itemGroup layout] columnForProperty: @"icon"] setWidth: 32]; // 20 if not two levels deep
	[[itemGroup layout] setAttachedTool: tool];
	[[[itemGroup layout] tableView] setHeaderView: nil];
	//float indent = [[[itemGroup layout] outlineView] indentationPerLevel];
	//[[[itemGroup layout] outlineView] setIndentationPerLevel: 0];
#ifndef GNUSTEP
	[[[itemGroup layout] tableView] setSelectionHighlightStyle: NSTableViewSelectionHighlightStyleSourceList];
	NSSize cellSpacing = [[[itemGroup layout] tableView] intercellSpacing];
	cellSpacing.height += 3;
	[[[itemGroup layout] tableView] setIntercellSpacing: cellSpacing];
#endif
	[itemGroup setHasVerticalScroller: YES];

	//[itemGroup setSource: itemGroup];
	//[itemGroup reload];

	for (id listObject in aGroup)
	{
		ETLayoutItemGroup *listItem = [self itemGroupWithRepresentedObject: listObject];

		[listItem setSelectable: NO];
		[listItem setSource: listItem];
		// TODO: Could be better to change -lookUpTemplateProvider to look up 
		// controllers recursively upwards rather than just on the base item
		// then we wouldn't have to set a controller on each list item (one on 
		// the source list would be ok).
		[listItem setController: AUTORELEASE([[ETController alloc] init])];
		[[listItem controller] setTemplate: [ETItemTemplate templateWithItem: [self item] objectClass: Nil]
		                           forType: [[listItem controller] currentGroupType]];
		if ([[listObject name] isEqual: @"WHAT"])
		{
			[[listItem controller] setTemplate: [ETItemTemplate templateWithItem: [self itemGroup] objectClass: Nil]
		                           forType: [ETUTI typeWithClass: [COTagGroup class]]];	
		}
		[listItem reload];

		[itemGroup addItem: listItem];
	}

	[aController setSourceListItem: itemGroup];
	[aController startObserveObject: itemGroup
	            forNotificationName: ETItemGroupSelectionDidChangeNotification
                           selector: @selector(sourceListSelectionDidChange:)];

	NSOutlineView *ov = (NSOutlineView *)[[itemGroup layout] tableView];
	[ov reloadData];
	[ov expandItem: [itemGroup firstItem]];
	[ov expandItem: [itemGroup itemAtIndex: 1]];

	return itemGroup;
}

- (ETLayoutItemGroup *) contentViewWrapperWithGroup: (id <ETCollection>)aGroup controller: (id)aController
{
	ETLayoutItemGroup *contentView = [self contentViewWithGroup: [[aGroup contentArray] firstObject]
													 controller: aController];
	// TODO: The width should be computed by the body layout
	NSSize size = NSMakeSize([self defaultContentViewWidth], [self defaultBrowserBodySize].height);
	ETLayoutItemGroup *itemGroup = [self itemGroupWithSize: size];

	[itemGroup setIdentifier: @"contentViewWrapper"];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[itemGroup setLayout: [ETColumnLayout layout]];
	[itemGroup addItem: contentView];

	return itemGroup;
}

- (ETLayoutItemGroup *) contentViewWithGroup: (id <ETCollection>)aGroup controller: (id)aController
{
	// TODO: The width should be computed by the body layout
	NSSize size = NSMakeSize([self defaultContentViewWidth], [self defaultBrowserBodySize].height);
	ETLayoutItemGroup *itemGroup = [self itemGroupWithSize: size];

	[itemGroup setIdentifier: @"contentView"];
	[itemGroup setRepresentedObject: aGroup];
	/* The controller templates are set up in -[MBEntityViewController init] */
	//[itemGroup setController: AUTORELEASE([[MBEntityViewController alloc] init])];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[itemGroup setHasVerticalScroller: YES];
	[itemGroup setSource: itemGroup];
	[itemGroup setLayout: [self listLayoutForBrowser]];	
	[itemGroup setController: AUTORELEASE([[OMBrowserContentController alloc] init])];
	[[itemGroup controller] setPersistentObjectContext: [aController persistentObjectContext]];
	[itemGroup reload];

	[aController setContentViewItem: itemGroup];

	return itemGroup;
}

- (ETTokenLayout *) tokenLayoutForTagFilterEditor
{
	ETTokenLayout *layout = [ETTokenLayout layout];
	[layout setEditedProperty: @"name"];
	return layout;
}

- (ETLayoutItemGroup *) tagFilterEditorWithTagLibrary: (COTagLibrary *)aTagLibrary
                                                 size: (NSSize)aSize
                                           controller: (id)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroupWithSize: aSize];
	ETController *tagController = AUTORELEASE([ETController new]);
	[tagController setPersistentObjectContext: [aController persistentObjectContext]];
	ETItemTemplate *tagTemplate = [ETItemTemplate templateWithItem: [self item] entityName: @"COTag"];

	[tagController setTemplate: tagTemplate forType: [tagController currentObjectType]];

	[itemGroup setIdentifier: @"tagFilterEditor"];
	[itemGroup setController: tagController];
	[itemGroup setRepresentedObject: aTagLibrary];
	[itemGroup setShouldMutateRepresentedObject: YES];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[itemGroup setSize: aSize];
	[itemGroup setSource: itemGroup];
	[itemGroup setLayout: [self tokenLayoutForTagFilterEditor]];
	[itemGroup reload];
	
	return itemGroup;
}

- (ETLayoutItemGroup *) inspectorWithObject: (id)anObject
                                       size: (NSSize)aSize
                                 controller: (id)aController
{
	ETModelDescriptionRenderer *renderer = [ETModelDescriptionRenderer renderer];
	
	// NOTE: Could add back later 'icon' and 'content'
	[renderer setRenderedPropertyNames: A(@"displayName", @"typeDescription",
		@"modificationDate", @"creationDate", @"lastVersionDescription", @"tags")];
	[(ETLayoutItem *)[[renderer templateItems] mappedCollection] setWidth: 200];

	//[[[renderer entityLayout] positionalLayout] setIsContentSizeLayout: YES];

	ETLayoutItemGroup *itemGroup = [renderer renderObject: anObject];
	
	[itemGroup setIdentifier: @"inspector"];
	// FIXME: Remove ETAutoresizingFlexibleLeftMargin
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleHeight | ETAutoresizingFlexibleLeftMargin];
	[itemGroup setSize: aSize];
	
	return itemGroup;
}

@end


@implementation ETApplication (ObjectManager)

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
	                action: @selector(addNewObjectFromTemplate:)
	         keyEquivalent: @""];

	[menu addItemWithTitle:  _(@"New Object")
	                action: @selector(add:)
	         keyEquivalent: @""];

	[menu addItemWithTitle:  _(@"New Tag")
	                action: @selector(addNewTag:)
	         keyEquivalent: @""];

	[menu addItemWithTitle:  _(@"New Smart Group")
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

- (NSMenuItem *) viewMenuItem
{
	OMLayoutItemFactory *itemFactory = [OMLayoutItemFactory factory];
	NSMenuItem *menuItem = (id)[[self mainMenu] itemWithTitle: _(@"View")];

	if (menuItem != nil)
		return menuItem;

	menuItem = [NSMenuItem menuItemWithTitle: _(@"View")
	                                     tag: 0
	                                  action: NULL];
	NSMenu *menu = [menuItem submenu];


	[menu addItemWithTitle: _(@"Icon")
	                action: @selector(changePresentationViewFromMenuItem:)
	         keyEquivalent: @""];
	[[menu lastItem] setRepresentedObject: [itemFactory iconLayoutForBrowser]];

	[menu addItemWithTitle:  _(@"List")
	                action: @selector(changePresentationViewFromMenuItem:)
	         keyEquivalent: @""];
	[[menu lastItem] setRepresentedObject: [itemFactory listLayoutForBrowser]];

	[menu addItemWithTitle: _(@"Note")
	                action: @selector(changePresentationViewFromMenuItem:)
	         keyEquivalent: @""];
	[[menu lastItem] setRepresentedObject: [itemFactory noteLayoutForBrowser]];

	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Show Inspector")
	                action: @selector(toggleInspector:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"New Inspector")
	                action: @selector(showInspectorInStandaloneWindow:)
	         keyEquivalent: @""];
			
	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Infos")
	                action: @selector(changeInspectorFromMenuItem:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"Tags")
	                action: @selector(changeInspectorFromMenuItem:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"History")
	                action: @selector(changeInspectorFromMenuItem:)
	         keyEquivalent: @""];

	return menuItem;
}

@end
