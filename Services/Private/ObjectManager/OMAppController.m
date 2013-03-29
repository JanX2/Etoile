/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2011
	License:  Modified BSD  (see COPYING)
 */

#import "OMAppController.h"
#import "OMLayoutItemFactory.h"
#import "OMModelFactory.h"

@interface OMAppController (Private)
- (NSArray *) makeDemoLibraries;
@end

@implementation OMAppController

- (void) dealloc
{
	DESTROY(itemFactory);
	DESTROY(openedGroups);
	DESTROY(mainUndoTrack);
	[super dealloc];
}

- (id) init
{
	self = [super initWithNibName: nil bundle: nil];
	ASSIGN(itemFactory, [OMLayoutItemFactory factory]);
	openedGroups = [[NSMutableSet alloc] init];
	return self;
}

- (void) setUpMenus
{
	[[ETApp mainMenu] addItem: [ETApp objectMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp editMenuItem]];
}

- (void) setUpUndoTrack
{
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
}

- (void) setUpEditingContext
{
	//[[NSFileManager defaultManager] 
	//	removeFileAtPath: [@"~/TestObjectStore" stringByExpandingTildeInPath] handler: nil];
	COEditingContext *ctxt = [COEditingContext contextWithURL: 
		[NSURL fileURLWithPath: [@"~/TestObjectStore.sqlite" stringByExpandingTildeInPath]]];

	[COEditingContext setCurrentContext: ctxt];
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
	ETUUID *storeUUID = [[[COEditingContext currentContext] store] UUID];

	ETAssert([[[[notif object] store] UUID] isEqual: storeUUID]);

	[mainUndoTrack addRevisions: [[notif userInfo] objectForKey: kCORevisionsKey]];
}

- (IBAction) browseMainGroup: (id)sender
{
	OMModelFactory *modelFactory = [[OMModelFactory new] autorelease];
	ETLayoutItemGroup *browser = [itemFactory browserWithGroup: [modelFactory sourceListGroups]
	                                            editingContext: [COEditingContext currentContext]];

	[[itemFactory windowGroup] addObject: browser];
	[openedGroups addObject: [[COEditingContext currentContext] mainGroup]];
}

- (IBAction) undo: (id)sender
{
	[mainUndoTrack undo];
}

- (IBAction) redo: (id)sender
{
	[mainUndoTrack redo];
}

- (IBAction) browseUndoHistory: (id)sender
{
	ETLayoutItemGroup *browser = [[ETLayoutItemFactory factory] 
		historyBrowserWithRepresentedObject: mainUndoTrack];

	[[[ETLayoutItemFactory factory] windowGroup] addItem: browser];
}

@end
