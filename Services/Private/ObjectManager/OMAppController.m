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

- (void) applicationDidFinishLaunching: (NSNotification *)notif
{
	[self setUpMenus];

	//[[NSFileManager defaultManager] 
	//	removeFileAtPath: [@"~/TestObjectStore" stringByExpandingTildeInPath] handler: nil];
	COEditingContext *ctxt = [COEditingContext contextWithURL: 
		[NSURL fileURLWithPath: [@"~/TestObjectStore" stringByExpandingTildeInPath]]];

	[COEditingContext setCurrentContext: ctxt];

	[[itemFactory windowGroup] setController: self];
	[self browseMainGroup: nil];
}

- (NSArray *) sourceListGroups
{
	COGroup *tagGroup = [[COEditingContext currentContext] tagGroup];
	COGroup *libraryGroup = [[COEditingContext currentContext] libraryGroup];
	COSmartGroup *mainGroup = [[COEditingContext currentContext] mainGroup];

	if ([[mainGroup content] isEmpty])
	{
		[self buildCoreObjectGraphDemo];
		[mainGroup refresh];
		ETAssert([mainGroup count] > 0);
	}

	return [A(mainGroup, tagGroup) arrayByAddingObjectsFromArray: [libraryGroup contentArray]];
}

- (IBAction) browseMainGroup: (id)sender
{
	[[itemFactory windowGroup] addObject: [itemFactory browserWithGroup: [self sourceListGroups]]];
	//[[itemFactory windowGroup] addObject: [itemFactory browserTopBarWithController: nil]];
	[openedGroups addObject: [[COEditingContext currentContext] mainGroup]];
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

	COGroup *cityGroup = [ctxt insertObjectWithEntityName: @"Anonymous.COGroup"];

	[cityGroup setName: @"Cities"];
	[cityGroup addObjects: A(a1, a2, a3)];

	/* Pictures */

	COObject *b1 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];
	COObject *b2 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];
	COObject *b3 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];
	COObject *b4 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];

	[b1 setName: @"Sunset"];
	[b2 setName: @"Beach"];
	[b3 setName: @"Cloud"];
	[b4 setName: @"Fox"];

	COGroup *pictureGroup = [ctxt insertObjectWithEntityName: @"Anonymous.COGroup"];

	[pictureGroup setName: @"Pictures"];
	[pictureGroup addObjects: A(b1, b2, b3, b4)];

	/* Persons */

	COObject *c1 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];
	COObject *c2 = [ctxt insertObjectWithEntityName: @"Anonymous.COObject"];

	[c1 setName: @"Ann"];
	[c2 setName: @"John"];

	COGroup *personGroup = [ctxt insertObjectWithEntityName: @"Anonymous.COGroup"];

	[personGroup setName: @"Persons"];
	[personGroup addObjects: A(c1, c2)];

	/* Libraries */

	// TODO: For every library, the name should be made read-only.
	[[ctxt libraryGroup] addObjects: A(cityGroup, pictureGroup, personGroup)];
	
	/* Scenery Tag */

	COGroup *sceneryTag = [ctxt insertObjectWithEntityName: @"Anonymous.COGroup"];

	[sceneryTag setName: _(@"scenery")];
	[sceneryTag addObjects: A(b1, b2)];

	/* Animal Tag */

	COGroup *animalTag = [ctxt insertObjectWithEntityName: @"Anonymous.COGroup"];

	[animalTag setName: _(@"animal")];
	[animalTag addObject: b4];

	/* Rain Tag */

	COGroup *rainTag = [ctxt insertObjectWithEntityName: @"Anonymous.COGroup"];

	[rainTag setName: _(@"rain")];
	[rainTag addObjects: A(a2, b3)];

	/* Declare the groups used as tags and commit */

	[[ctxt tagGroup] addObjects: A(rainTag, sceneryTag, animalTag)];
	[ctxt commit];
}

@end
