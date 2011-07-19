/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  July 2011
	License:  Modified BSD (see COPYING)
 */

#import <ObjectMerging/COEditingContext.h>
#import <EtoileUI/ETLayoutItem+CoreObject.h>
#import "DocumentEditorController.h"

@interface ETCompoundDocumentTemplate : ETItemTemplate
@end

@implementation DocumentEditorController

- (void) setUpMenus
{
	[[ETApp mainMenu] addItem: [ETApp documentMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp insertMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp arrangeMenuItem]];
}

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	[self setUpMenus];

	COEditingContext *ctxt = [COEditingContext contextWithURL: 
		[NSURL fileURLWithPath: [@"~/TestDocumentStore" stringByExpandingTildeInPath]]];

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
	[mainItem setLayout: [ETFixedLayout layout]];
	[itemFactory endRootObject];
										 
	[self setTemplate: [ETCompoundDocumentTemplate templateWithItem: mainItem objectClass: Nil]
	          forType: mainType];

	/* Set the type of the documented to be created by default with 'New' in the menu */
	[self setCurrentObjectType: mainType];
	
	//[self newDocument: nil];
	//[[NSUserDefaults standardUserDefaults] removeObjectForKey: @"kETOpenedDocumentUUIDs"];
	[self showPreviouslyOpenedDocuments];

	/*ETShape *shape = [ETShape rectangleShape];

	[shape becomePersistentInContext: ctxt rootObject: mainItem];*/
}

// TODO: Move the methods below to ETDocumentController once Worktable is more mature

- (void) showPreviouslyOpenedDocuments
{
	for (ETUUID *uuid in [self openedDocumentUUIDsFromDefaults])
	{
		ETLayoutItemGroup *documentItem = (id)[[COEditingContext currentContext] objectWithUUID: uuid];
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

	if ([openedDocUUIDs containsObject: [anItem UUID]])
		return;

	openedDocUUIDs = [openedDocUUIDs arrayByAddingObject: [anItem UUID]];
	[[NSUserDefaults standardUserDefaults] setObject: [[openedDocUUIDs mappedCollection] stringValue]
	                                          forKey: @"kETOpenedDocumentUUIDs"];
}

- (void) rememberClosedDocumentItem: (ETLayoutItem *)anItem
{
	NSArray *openedDocUUIDs = [self openedDocumentUUIDsFromDefaults];

	if ([openedDocUUIDs containsObject: [anItem UUID]] == NO)
		return;

	openedDocUUIDs = [openedDocUUIDs arrayByRemovingObject: [anItem UUID]];
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
	[[COEditingContext currentContext] commit];
}

// Won't be called on quit, -terminate: doesn't close the windows with -performClose:
- (void) willCloseDocumentItem: (ETLayoutItem *)anItem
{
	[self rememberClosedDocumentItem: anItem];
}

@end

@implementation ETCompoundDocumentTemplate

- (BOOL) writeItem: (ETLayoutItem *)anItem 
             toURL: (NSURL *)aURL 
           options: (NSDictionary *)options
{
	ETAssert([anItem compoundDocument] != nil);
	[[anItem editingContext] commit];
	return YES;
}

- (ETLayoutItem *) newItemWithURL: (NSURL *)aURL options: (NSDictionary *)options
{
	COEditingContext *editingContext = [COEditingContext currentContext];
	NSAssert(editingContext != nil, @"Current editing context must not be nil to create a new item");

	ETLayoutItem *item = [super newItemWithURL: aURL options: options];
	[item becomePersistentInContext: editingContext rootObject: item];
	return item;
}

@end

