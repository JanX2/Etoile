/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License:  Modified BSD (see COPYING)
 */

#import <EtoileUI/ETLayoutItem+CoreObject.h>
#import "DocumentEditorController.h"

@interface ETCompoundDocumentTemplate : ETItemTemplate
@end

@implementation DocumentEditorController

- (void) setUpMenus
{
	[[ETApp mainMenu] addItem: [ETApp documentMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp editMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp insertMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp arrangeMenuItem]];
}

/* For debugging */
/*- (void) showBasicRectangleItems
{
	ETLayoutItem *rectItem = RETAIN([itemFactory rectangle]);
	ETUUID *uuid = [rectItem UUID];

	[rectItem becomePersistentInContext: ctxt rootObject: rectItem];
	[rectItem commit];
	[[itemFactory windowGroup] addItem: rectItem];

	[ctxt unloadRootObjectTree: rectItem];

	ETLayoutItem *newRectItem = [ctxt objectWithUUID: uuid];
	//[newRectItem setStyle: [ETShape rectangleShapeWithRect: [newRectItem contentBounds]]];
	[[itemFactory windowGroup] addItem: newRectItem];
}*/

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	[self setUpMenus];

	COEditingContext *ctxt = [COEditingContext contextWithURL: 
		[NSURL fileURLWithPath: [@"~/TestObjectStore.sqlite" stringByExpandingTildeInPath]]];

	[COEditingContext setCurrentContext: ctxt];

	ETLayoutItemFactory *itemFactory = [ETLayoutItemFactory factory];

	[[itemFactory windowGroup] setController: self];

	ETUTI *mainType = 
		[ETUTI registerTypeWithString: @"org.etoile-project.compound-document" 
		                  description: _(@"Etoile Compound or Composite Document Format")
		             supertypeStrings: A(@"public.composite-content")
		                     typeTags: [NSDictionary dictionary]];

	// TODO: Use -compoundDocumentItem
	[itemFactory beginRootObject];
	mainItem = [itemFactory itemGroup];
	[mainItem setSize: NSMakeSize(500, 400)];
	[mainItem setLayout: [ETFreeLayout layout]];
	[itemFactory endRootObject];

	/*[mainItem addItem: [[itemFactory rectangle] copy]];
	// FIXME:[[itemFactory windowGroup] addItem: [mainItem copy]];
	[[itemFactory windowGroup] addItem: [mainItem deepCopy]];
	return;*/

	[self setTemplate: [ETCompoundDocumentTemplate templateWithItem: mainItem objectClass: Nil objectGraphContext: [itemFactory objectGraphContext]]
	          forType: mainType];

	/* Set the type of the documented to be created by default with 'New' in the menu */
	[self setCurrentObjectType: mainType];

	//[self showBasicRectangleItemsForDebugging];
	//[self newDocument: nil];
	//[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"kETOpenedDocumentUUIDs"];
	[self showPreviouslyOpenedDocuments];

	ETLayoutItemGroup *picker = [itemFactory itemGroupWithRepresentedObject: [ETAspectRepository mainRepository]];
	ETController *controller = AUTORELEASE([[ETController alloc] init]);
	ETItemTemplate *template = [controller templateForType: [controller currentObjectType]];
	ETSelectTool *tool = [ETSelectTool tool];

	[tool setAllowsMultipleSelection: YES];
	[tool setAllowsEmptySelection: NO];
	[tool setShouldRemoveItemsAtPickTime: NO];

	[[template item] setActionHandler: [ETAspectTemplateActionHandler sharedInstanceForObjectGraphContext: [itemFactory objectGraphContext]]];
	[controller setAllowedPickTypes: A([ETUTI typeWithClass: [NSObject class]])];

	[picker setActionHandler: [ETAspectTemplateActionHandler sharedInstanceForObjectGraphContext: [itemFactory objectGraphContext]]];
	[picker setSize: NSMakeSize(300, 400)];
	[picker setController: controller];
	[picker setSource: picker];
	[picker setLayout: [ETOutlineLayout layout]];
	[[picker layout] setAttachedTool: tool];
	[[picker layout] setDisplayedProperties: A(kETIconProperty, kETDisplayNameProperty)];
	[picker setHasVerticalScroller: YES];
	[picker reloadAndUpdateLayout];

	[[itemFactory windowGroup] addItem: picker];
	
	[ETApp toggleDevelopmentMenu: nil];

	/*ETShape *shape = [ETShape rectangleShape];

	[shape becomePersistentInContext: ctxt rootObject: mainItem];*/
}

// TODO: Move the methods below to ETDocumentController once Worktable is more mature

- (void) showPreviouslyOpenedDocuments
{
	for (ETUUID *uuid in [self openedDocumentUUIDsFromDefaults])
	{
		ETLayoutItemGroup *documentItem = [[[COEditingContext currentContext] persistentRootForUUID: uuid] rootObject];
		if (documentItem == nil)
		{
			ETLog(@"WARNING: Found no document %@", uuid);
			[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"kETOpenedDocumentUUIDs"];
			return;
		}
		[[[ETLayoutItemFactory factory] windowGroup] addItem: documentItem];
	}
}

- (NSArray *) openedDocumentUUIDsFromDefaults
{
	NSArray *openedDocUUIDStrings = [[NSUserDefaults standardUserDefaults] arrayForKey: @"kETOpenedDocumentUUIDs"];
	NSMutableArray *openedDocUUIDs = [NSMutableArray array];

	for (NSString *UUIDString in openedDocUUIDStrings)
	{
		[openedDocUUIDs addObject: [ETUUID UUIDWithString: UUIDString]];
	}

	return openedDocUUIDs;
}

- (void) rememberOpenedDocumentItem: (ETLayoutItem *)anItem
{
	NSArray *openedDocUUIDs = [self openedDocumentUUIDsFromDefaults];
	ETUUID *persistentRootUUID = [[anItem persistentRoot] persistentRootUUID];

	if ([openedDocUUIDs containsObject: persistentRootUUID])
		return;

	openedDocUUIDs = [openedDocUUIDs arrayByAddingObject: persistentRootUUID];
	[[NSUserDefaults standardUserDefaults] setObject: [[openedDocUUIDs mappedCollection] stringValue]
	                                          forKey: @"kETOpenedDocumentUUIDs"];
}

- (void) rememberClosedDocumentItem: (ETLayoutItem *)anItem
{
	NSArray *openedDocUUIDs = [self openedDocumentUUIDsFromDefaults];
	ETUUID *persistentRootUUID = [[anItem persistentRoot] persistentRootUUID];

	if ([openedDocUUIDs containsObject: persistentRootUUID] == NO)
		return;

	openedDocUUIDs = [openedDocUUIDs arrayByRemovingObject: persistentRootUUID];
	[[NSUserDefaults standardUserDefaults] setObject: openedDocUUIDs 
	                                          forKey: @"kETOpenedDocumentUUIDs"];
}

- (void) didOpenDocumentItem: (ETLayoutItem *)anItem
{
	[self rememberOpenedDocumentItem: anItem];
}

- (void) didCreateDocumentItem: (ETLayoutItem *)anItem
{
	[self rememberOpenedDocumentItem: anItem];
	// Hmm, not sure that's the proper place to commit
	[[COEditingContext currentContext] commitWithType: @"Item Creation" shortDescription: @"Created Compound Document"];
}

// Won't be called on quit, -terminate: doesn't close the windows with -performClose:
- (void) willCloseDocumentItem: (ETLayoutItem *)anItem
{
	[self rememberClosedDocumentItem: anItem];
}

- (IBAction) undo: (id)sender
{
	[[[self activeItem] branch] undo];
}

- (IBAction) redo: (id)sender
{
	[[[self activeItem] branch] redo];
}

@end

@implementation ETCompoundDocumentTemplate

- (BOOL) writeItem: (ETLayoutItem *)anItem 
             toURL: (NSURL *)aURL 
           options: (NSDictionary *)options
{
	ETAssert([anItem compoundDocument] != nil);
	[[anItem persistentRoot] commit];
	return YES;
}

- (ETLayoutItem *) newItemWithURL: (NSURL *)aURL options: (NSDictionary *)options
{
	COEditingContext *editingContext = [COEditingContext currentContext];
	NSAssert(editingContext != nil, @"Current editing context must not be nil to create a new item");

	ETLayoutItem *item = [super newItemWithURL: aURL options: options];

	[editingContext insertNewPersistentRootWithRootObject: item];
	return item;
}

@end

@implementation ETUIBuilderDemoController

- (IBAction)increment: (id)sender
{
	ETLayoutItem *counterItem = [[self content] itemForIdentifier: @"counter"];

	NSLog(@"Increment counter %@", counterItem);

	[[counterItem view] setIntegerValue: [[counterItem view] integerValue] + 1];
	[counterItem didChangeValueForProperty: kETViewProperty];
	[counterItem commit];
}

@end

@implementation  ETApplication (UIBuilder)

- (IBAction) toggleLiveDevelopment: (id)sender
{
	ETDocumentController *controller = (id)[[[ETLayoutItemFactory factory] windowGroup] controller];
	ETLayoutItem *documentItem = [controller activeItem];
	BOOL isLiveDevelopmentActive = [[documentItem layout] isKindOfClass: [ETFreeLayout class]];

	if (isLiveDevelopmentActive)
	{
		[documentItem setLayout: [ETFixedLayout layout]];
	}
	else
	{
		[documentItem setLayout: [ETFreeLayout layout]];
	}
	[documentItem commit];
}

@end
