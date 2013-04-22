/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2013
	License:  Modified BSD  (see COPYING)
 */

#import "TWAppController.h"
#import "TWLayoutItemFactory.h"
#import "TWTextTreeDocumentTemplate.h"

@implementation TWAppController

@synthesize currentPresentationTitle;

- (void) dealloc
{
	DESTROY(itemFactory);
	DESTROY(mainUndoTrack);
	DESTROY(currentPresentationTitle);
	[super dealloc];
}

- (id) init
{
	self = [super initWithNibName: nil bundle: nil];
	ASSIGN(itemFactory, [TWLayoutItemFactory factory]);
	openedGroups = [[NSMutableSet alloc] init];
	return self;
}

- (void) setUpMenus
{
	[[ETApp mainMenu] addItem: [ETApp documentMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp editMenuItem]];
	[[ETApp mainMenu] addItem: [ETApp viewMenuItem]];
	
	[[[[ETApp viewMenuItem] submenu] itemWithTitle: _(@"List")] setState: NSOnState];
	ASSIGN(currentPresentationTitle,  _(@"List"));
}

- (void) setUpUndoTrack
{
	ETUUID *trackUUID = [[NSUserDefaults standardUserDefaults] UUIDForKey: @"TWMainUndoTrackUUID"];

	if (trackUUID == nil)
	{
		trackUUID = [ETUUID UUID];
		[[NSUserDefaults standardUserDefaults] setUUID: trackUUID 
		                                        forKey: @"TWMainUndoTrackUUID"];
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

- (void) registerTemplates
{
	ETUTI *mainType = 
		[ETUTI registerTypeWithString: @"org.etoile-project.compound-document" 
		                  description: _(@"Etoile Compound or Composite Document Format")
		             supertypeStrings: A(@"public.composite-content")
		                     typeTags: [NSDictionary dictionary]];
	ETLayoutItemGroup *item = [itemFactory editorWithRepresentedObject: [[ETTextTree new] autorelease]
	                                                    editingContext: [COEditingContext currentContext]];
	ETItemTemplate *template = [TWTextTreeDocumentTemplate templateWithItem: item
	                                                            objectClass: [ETTextTree class]];

	[self setTemplate: template forType: mainType];
	/* Set the type of the documented to be created by default with 'New' in the menu */
	[self setCurrentObjectType: mainType];
}

- (void) presentInitialUI
{
	[[itemFactory windowGroup] setController: self];
	[self newDocument: nil];
}

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	[self setUpMenus];
	[self setUpEditingContext];
	[self setUpUndoTrack];
	[self registerTemplates];
	[self presentInitialUI];
}

- (void) didMakeLocalCommit: (NSNotification *)notif
{
	ETUUID *storeUUID = [[[COEditingContext currentContext] store] UUID];

	ETAssert([[[[notif object] store] UUID] isEqual: storeUUID]);

	[mainUndoTrack addRevisions: [[notif userInfo] objectForKey: kCORevisionsKey]];
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
		historyBrowserWithRepresentedObject: mainUndoTrack title: nil];

	[[[ETLayoutItemFactory factory] windowGroup] addItem: browser];
}

@end
