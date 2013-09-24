/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2011
	License:  Modified BSD  (see COPYING)
 */

#import "OMAppController.h"
#import "OMLayoutItemFactory.h"
#import "OMModelFactory.h"

@implementation OMAppController

@synthesize currentPresentationTitle, editingContext;

- (void) dealloc
{
	DESTROY(editingContext);
	DESTROY(itemFactory);
	DESTROY(openedGroups);
	DESTROY(mainUndoTrack);
	DESTROY(currentPresentationTitle);
	[super dealloc];
}

- (id) initWithObjectGraphContext: (COObjectGraphContext *)aContext
{
	self = [super initWithNibName: nil bundle: nil objectGraphContext: aContext];
	ASSIGN(itemFactory, [OMLayoutItemFactory factoryWithObjectGraphContext: aContext]);
	openedGroups = [[NSMutableSet alloc] init];
	return self;
}

- (void) setUpMenus
{
	[[ETApp mainMenu] addItem: [ETApp objectMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp editMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp viewMenuItem]];
	
	[[[[ETApp viewMenuItem] submenu] itemWithTitle: _(@"List")] setState: NSOnState];
	ASSIGN(currentPresentationTitle,  _(@"List"));
}

- (void) setUpUndoTrack
{
#if 0
	ETUUID *trackUUID = [[NSUserDefaults standardUserDefaults] UUIDForKey: @"OMMainUndoTrackUUID"];

	if (trackUUID == nil)
	{
		trackUUID = [ETUUID UUID];
		[[NSUserDefaults standardUserDefaults] setUUID: trackUUID 
		                                        forKey: @"OMMainUndoTrackUUID"];
	}
	mainUndoTrack = [[COCustomTrack alloc] initWithUUID: trackUUID 
	                                     editingContext: [COEditingContext currentContext]];

	/* For pushing revisions on the track */
	[[NSNotificationCenter defaultCenter] addObserver: self 
	                                         selector: @selector(didMakeLocalCommit:) 
	                                             name: COEditingContextDidCommitNotification 
	                                           object: [COEditingContext currentContext]];
#endif
}


- (void) setUpEditingContext
{
	[[NSFileManager defaultManager] 
		removeFileAtPath: [@"~/TestObjectStore" stringByExpandingTildeInPath] handler: nil];
	COEditingContext *ctxt = [COEditingContext contextWithURL: 
		[NSURL fileURLWithPath: [@"~/TestObjectStore.sqlite" stringByExpandingTildeInPath]]];
	ETAssert(ctxt != nil);
	ASSIGN(editingContext, ctxt);
}

- (void) setUpAndShowBrowserUI
{
	[[itemFactory windowGroup] setController: self];
	[self browseMainGroup: nil];
}

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	[self setUpMenus];
	[self setUpEditingContext];
	[self setUpUndoTrack];
	[self setUpAndShowBrowserUI];
}

- (void) didMakeLocalCommit: (NSNotification *)notif
{
#if 0
	ETUUID *storeUUID = [[[COEditingContext currentContext] store] UUID];

	ETAssert([[[[notif object] store] UUID] isEqual: storeUUID]);

	[mainUndoTrack addRevisions: [[notif userInfo] objectForKey: kCORevisionsKey]];
#endif
}

- (IBAction) browseMainGroup: (id)sender
{
	OMModelFactory *modelFactory = [[[OMModelFactory alloc]
		initWithEditingContext: [self editingContext]] autorelease];
	ETLayoutItemGroup *browser = [itemFactory browserWithGroup: [modelFactory sourceListGroups]
	                                            editingContext: [self editingContext]];

	[[itemFactory windowGroup] addObject: browser];
	[openedGroups addObject: [modelFactory allObjectGroup]];
}

- (IBAction) undo: (id)sender
{
	[mainUndoTrack undoWithEditingContext: [self editingContext]];
}

- (IBAction) redo: (id)sender
{
	[mainUndoTrack redoWithEditingContext: [self editingContext]];
}

- (IBAction) browseUndoHistory: (id)sender
{
	ETLayoutItemGroup *browser = [[ETLayoutItemFactory factory] 
		historyBrowserWithRepresentedObject: mainUndoTrack title: nil];

	[[[ETLayoutItemFactory factory] windowGroup] addItem: browser];
}

@end
