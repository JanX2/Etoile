/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD  (see COPYING)
 */
#import <IconKit/IconKit.h>
#import "TWLayoutItemFactory.h"
#import "TWEditorController.h"
#import "TWEditorContentController.h"

@implementation TWLayoutItemFactory

- (ETTextEditorLayout *) textLayout
{
	return [ETTextEditorLayout layout];
}

- (ETOutlineLayout *) listLayout
{
	ETOutlineLayout *layout = [ETOutlineLayout layout];
	NSArray *headerNames = A(@"", @"Name", @"Content");

	[layout setDisplayedProperties: A(@"icon", @"outlineValue")];

	[layout setEditable: YES forProperty: @"name"];
	[layout setEditable: YES forProperty: @"outlineValue"];

	[layout setContentFont: [NSFont controlContentFontOfSize: 12]];
	[[layout tableView] setUsesAlternatingRowBackgroundColors: YES];

	[[layout columnForProperty: @"name"] setWidth: 180];
	[[layout columnForProperty: @"outlineValue"] setWidth: 500];

	[layout setSortable: YES];

	NSUInteger n = [headerNames count];
	for (NSUInteger i = 0; i < n; i++)
	{
		[layout setDisplayName: [headerNames objectAtIndex: i] 
		           forProperty: [A(@"icon", @"name", @"outlineValue") objectAtIndex: i]];
	}

	return layout;
}

- (ETOutlineLayout *) columnLayout
{
	return [ETBrowserLayout layout];
}

- (ETLayoutItem *) buttonWithIconNamed: (NSString *)aName target: (id)aTarget action: (SEL)anAction
{
	NSImage *icon = [[IKIcon iconWithIdentifier: aName] image];
	return [self buttonWithImage: icon target: aTarget action: anAction];
}

- (NSSize) defaultEditorSize
{
	return NSMakeSize(900, 500);
}

- (NSSize) defaultBodySize
{
	NSSize size = [self defaultEditorSize];
	size.height -= [self defaultIconAndLabelBarHeight];
	return size;
}

- (CGFloat) defaultSourceListWidth
{
	return 0;
}

- (CGFloat) defaultContentViewWidth
{
	return [self defaultBodySize].width - [self defaultSourceListWidth];
}

- (CGFloat) defaultInspectorWidth
{
	return 400;
}

- (ETLayoutItemGroup *) editorWithRepresentedObject: (id)anObject editingContext: (COEditingContext *)aContext;
{
	TWEditorController *controller = AUTORELEASE([TWEditorController new]);
	[controller setPersistentObjectContext: aContext];
	ETLayoutItemGroup *topBar = [self topBarWithController: controller];
	ETLayoutItemGroup *body = [self bodyWithRepresentedObject: anObject controller: controller];
	ETLayoutItemGroup *browser = [self itemGroupWithItems: A(topBar, body)];

	[browser setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[browser setController: controller];
	 /* For TWEditorController template lookup needs */
	[browser setRepresentedObject: anObject];
	[browser setShouldMutateRepresentedObject: NO];
	[browser setLayout: [ETColumnLayout layout]];
	[browser setSize: [self defaultEditorSize]];

	return browser;
}

- (ETLayoutItemGroup *) bodyWithRepresentedObject: (id)anObject controller: (id)aController
{
	ETLayoutItemGroup *contentView = [self contentViewWithRepresentedObject: anObject
	                                                             controller: aController];
	ETLayoutItemGroup *body = [self itemGroup];

	[body setIdentifier: @"body"];
	[body setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[body setSize: [self defaultBodySize]]; // FIXME: Avoid negative size if -setSize: is not called
	[body setLayout: [ETLineLayout layout]];
	[body addItems: A(contentView)];

	[aController setContentViewItem: contentView];

	return body;
}

- (ETLayoutItem *) viewPopUpWithController: (id)aController
{
	NSArray *choices = A(_(@"Text"), _(@"Outline"), _(@"Outline and Text"));
	NSArray *templateLayouts = 
		A([self textLayout], [self listLayout], [NSNull null]);
	ETLayoutItem *popUpItem = [self popUpMenuWithItemTitles: choices
		                                 representedObjects: templateLayouts
		                                             target: aController 
		                                             action: @selector(changePresentationViewFromPopUp:)];

	[aController setViewPopUpItem: popUpItem];
	[[popUpItem view] selectItemAtIndex: 1];
	return popUpItem;
}

- (ETLayoutItemGroup *) topBarWithController: (ETController *)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroup];
	ETLayoutItem *newItem = [self buttonWithIconNamed: @"list-add"
	                                           target: aController
	                                           action: @selector(insert:)];
	ETLayoutItem *newChildItem = [self buttonWithIconNamed: @"list-add"
	                                                target: aController
	                                                action: @selector(add:)];
	ETLayoutItem *removeItem = [self buttonWithIconNamed: @"list-remove" 
	                                              target: aController
	                                              action: @selector(remove:)];
	ETLayoutItem *searchFieldItem = [self searchFieldWithTarget: aController 
	                                                     action: @selector(search:)];

	[itemGroup setIdentifier: @"topBar"];
	[itemGroup setWidth: [self defaultEditorSize].width];
	[itemGroup setHeight: [self defaultIconAndLabelBarHeight]];
	[itemGroup setLayout: [ETLineLayout layout]];
	// FIXME: [[itemGroup layout] setSeparatorTemplateItem: [self flexibleSpaceSeparator]];
	[itemGroup addItems:
		A([self barElementFromItem: newItem withLabel: _(@"New Item")],
		[self barElementFromItem: newChildItem withLabel: _(@"New Child")],
		[self barElementFromItem: removeItem withLabel: _(@"Remove")],
		[self barElementFromItem: [self viewPopUpWithController: aController] withLabel: _(@"View")],
		[self barElementFromItem: searchFieldItem withLabel: _(@"Search")])];
	[itemGroup updateLayout];
	
	return itemGroup;
}

- (ETLayoutItemGroup *) contentViewWithRepresentedObject: (id)anObject controller: (id)aController
{
	ETLayoutItemGroup *itemGroup = [self itemGroupWithRepresentedObject: anObject];

	[itemGroup setIdentifier: @"contentView"];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[itemGroup setHeight: [self defaultBodySize].height];
	// TODO: The width should be computed by the body layout
	[itemGroup setWidth: [self defaultContentViewWidth]];
	[itemGroup setHasVerticalScroller: YES];
	[itemGroup setSource: itemGroup];
	[itemGroup setShouldMutateRepresentedObject: YES];
	[itemGroup setLayout: [self listLayout]];	
	[itemGroup setController: AUTORELEASE([TWEditorContentController new])];
	[[itemGroup controller] setPersistentObjectContext: [aController persistentObjectContext]];
	[itemGroup reload];

	[aController setContentViewItem: itemGroup];

	return itemGroup;
}

- (ETLayoutItemGroup *) inspectorWithObject: (id)anObject
                                       size: (NSSize)aSize
                                 controller: (ETController *)aController
{
	ETLayoutItemGroup *itemGroup = [[ETModelDescriptionRenderer renderer] renderObject: anObject];
	
	[itemGroup setIdentifier: @"inspector"];
	[itemGroup setAutoresizingMask: ETAutoresizingFlexibleWidth | ETAutoresizingFlexibleHeight];
	[itemGroup setSize: aSize];
	
	return itemGroup;
}

@end


@implementation ETApplication (TypeWriter)

- (NSMenuItem *) viewMenuItem
{
	TWLayoutItemFactory *itemFactory = [TWLayoutItemFactory factory];
	NSMenuItem *menuItem = (id)[[self mainMenu] itemWithTitle: _(@"View")];

	if (menuItem != nil)
		return menuItem;

	menuItem = [NSMenuItem menuItemWithTitle: _(@"View")
	                                     tag: 0
	                                  action: NULL];
	NSMenu *menu = [menuItem submenu];


	[menu addItemWithTitle: _(@"Text")
	                action: @selector(changePresentationViewFromMenuItem:)
	         keyEquivalent: @""];
	[[menu lastItem] setRepresentedObject: [itemFactory textLayout]];

	[menu addItemWithTitle:  _(@"Outline")
	                action: @selector(changePresentationViewFromMenuItem:)
	         keyEquivalent: @""];
	[[menu lastItem] setRepresentedObject: [itemFactory listLayout]];

	[menu addItemWithTitle: _(@"Outline and Text")
	                action: @selector(changePresentationViewFromMenuItem:)
	         keyEquivalent: @""];
	[[menu lastItem] setRepresentedObject: [NSNull null]];

	[menu addItem: [NSMenuItem separatorItem]];

	[menu addItemWithTitle: _(@"Show Inspector")
	                action: @selector(toggleInspector:)
	         keyEquivalent: @""];

	[menu addItemWithTitle: _(@"New Inspector")
	                action: @selector(showInspectorInStandaloneWindow:)
	         keyEquivalent: @""];

	return menuItem;
}

@end
