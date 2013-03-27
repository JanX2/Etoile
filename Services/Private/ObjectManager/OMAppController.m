/*
	Copyright (C) 2011 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  November 2011
	License:  Modified BSD  (see COPYING)
 */

#import "OMAppController.h"
#import "OMLayoutItemFactory.h"

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

#if 0
- (NSArray *) sourceListGroups
{
	COGroup *libraryGroup = [[COEditingContext currentContext] libraryGroup];
	COSmartGroup *mainGroup = [[COEditingContext currentContext] mainGroup];
	COGroup *whereGroup = [[COGroup alloc] init];
	COGroup *whenGroup = [[COGroup alloc] init];

	if ([[mainGroup content] isEmpty])
	{
		[self buildCoreObjectGraphDemo];
		[mainGroup refresh];
		ETAssert([mainGroup count] > 0);
	}

	//[whereGroup addObjects: [A(mainGroup) arrayByAddingObjectsFromArray: [libraryGroup contentArray]]];
	//[whenGroup add
	return [A(mainGroup) arrayByAddingObjectsFromArray: [libraryGroup contentArray]];
}
#else
- (NSArray *) sourceListGroups
{
	COSmartGroup *mainGroup = [[COEditingContext currentContext] mainGroup];

	if ([[mainGroup content] isEmpty])
	{
		[self buildCoreObjectGraphDemo];
		[mainGroup refresh];
		ETAssert([mainGroup count] > 0);
	}

	// TODO: Turn whereGroup into a smart group that dynamically computes...
	//[whereGroup addObjects: [A(mainGroup) arrayByAddingObjectsFromArray: [libraryGroup contentArray]]];
	COSmartGroup *whereGroup = [[OMSmartGroup alloc] init];
	COSmartGroup *whatGroup = [[OMSmartGroup alloc] init];
	COGroup *whenGroup = [[OMGroup alloc] init];
	COGroup *libGroup = [[COEditingContext currentContext] libraryGroup];

	[whereGroup setName: [_(@"Where") uppercaseString]];
	[whereGroup setTargetCollection: [A(mainGroup) arrayByAddingObjectsFromArray: [libGroup contentArray]]];
	[whatGroup setName: [_(@"What") uppercaseString]];
	[whatGroup setTargetCollection: [[[COEditingContext currentContext] tagLibrary] tagGroups]];
	[whenGroup setName: [_(@"When") uppercaseString]];

	return A(whereGroup, whatGroup, whenGroup);
}
#endif

- (void) didMakeLocalCommit: (NSNotification *)notif
{
	ETUUID *storeUUID = [[[COEditingContext currentContext] store] UUID];

	ETAssert([[[[notif object] store] UUID] isEqual: storeUUID]);

	[mainUndoTrack addRevisions: [[notif userInfo] objectForKey: kCORevisionsKey]];
}

- (IBAction) browseMainGroup: (id)sender
{
	[[itemFactory windowGroup] addObject: [itemFactory browserWithGroup: [self sourceListGroups]]];
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

- (void) buildCoreObjectGraphDemo
{
	COEditingContext *ctxt = [COEditingContext currentContext];

	/* Cities */

	COObject *a1 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];
	COObject *a2 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];
	COObject *a3 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];

	[a1 setName: @"New York"];
	[a2 setName: @"London"];
	[a3 setName: @"Tokyo"];

	COLibrary *cityGroup = [ctxt insertObjectWithEntityName: @"Anonymous.COLibrary"];

	[cityGroup setName: @"Cities"];
	[cityGroup addObjects: A(a1, a2, a3)];

	/* Pictures */

	COObject *b1 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];
	COObject *b2 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];
	COObject *b3 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];
	COObject *b4 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];

	[b1 setName: @"Sunset"];
	[b2 setName: @"Eagle on a snowy Beach"];
	[b3 setName: @"Cloud"];
	[b4 setName: @"Fox"];

	COLibrary *pictureGroup = [ctxt insertObjectWithEntityName: @"Anonymous.COLibrary"];

	[pictureGroup setName: @"Pictures"];
	[pictureGroup addObjects: A(b1, b2, b3, b4)];

	/* Persons */

	COObject *c1 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];
	COObject *c2 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];

	[c1 setName: @"Ann"];
	[c2 setName: @"John"];

	COLibrary *personGroup = [ctxt insertObjectWithEntityName: @"Anonymous.COLibrary"];

	[personGroup setName: @"Persons"];
	[personGroup addObjects: A(c1, c2)];

	/* Libraries */

	// TODO: For every library, the name should be made read-only.
	[[ctxt libraryGroup] addObjects: A(cityGroup, pictureGroup, personGroup)];
	
	/* Scenery Tag */

	COTag *sceneryTag = [ctxt insertObjectWithEntityName: @"Anonymous.COTag"];

	[sceneryTag setName: _(@"scenery")];
	[sceneryTag addObjects: A(b1, b2)];

	/* Animal Tag */

	COTag *animalTag = [ctxt insertObjectWithEntityName: @"Anonymous.COTag"];

	[animalTag setName: _(@"animal")];
	[animalTag addObjects: A(b4, b2)];

	/* Rain Tag */

	COTag *rainTag = [ctxt insertObjectWithEntityName: @"Anonymous.COTag"];

	[rainTag setName: _(@"rain")];
	[rainTag addObjects: A(a2, a3, b3, b4)];

	/* Snow Tag */

	COTag *snowTag = [ctxt insertObjectWithEntityName: @"Anonymous.COTag"];

	[snowTag setName: _(@"snow")];
	[rainTag addObjects: A(a1, b2)];

	/* Tag Groups */

	COTagGroup *natureTagGroup = [ctxt insertObjectWithEntityName: @"Anonymous.COTagGroup"];

	[natureTagGroup setName: _(@"Nature")];
	[natureTagGroup addObjects: A(sceneryTag, animalTag, rainTag, snowTag)];

	COTagGroup *weatherTagGroup = [ctxt insertObjectWithEntityName: @"Anonymous.COTagGroup"];

	[weatherTagGroup setName: _(@"Weather")];
	[weatherTagGroup addObjects: A(rainTag, snowTag)];

	COTagGroup *unclassifiedTagGroup = [ctxt insertObjectWithEntityName: @"Anonymous.COTagGroup"];

	[unclassifiedTagGroup setName: _(@"Unclassified")];

	/* Declare the groups used as tags and commit */

	[[ctxt tagLibrary] addObjects: A(rainTag, sceneryTag, animalTag, snowTag)];
	[[[ctxt tagLibrary] tagGroups] addObjects: A(natureTagGroup, weatherTagGroup, unclassifiedTagGroup)];

	[ctxt commitWithMetadata: D(@"Object Creation", @"summary",
		@"Created Initial Core Objects", @"shortDescription",
		@"Created various core objects such as photos, cities etc. organized by tags and libraries", @"longDescription")];
}

@end


@implementation OMGroup

- (NSImage *) icon
{
	return nil;
}

@end

@implementation OMSmartGroup

- (NSImage *) icon
{
	return nil;
}

@end
