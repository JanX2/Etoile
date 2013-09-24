/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  March 2013
	License:  Modified BSD  (see COPYING)
 */

#import "OMModelFactory.h"

@implementation OMModelFactory

@synthesize editingContext = _editingContext;

- (id) initWithEditingContext: (COEditingContext *)aContext
{
	NILARG_EXCEPTION_TEST(aContext);
	SUPERINIT;
	ASSIGN(_editingContext, aContext);
	return self;
}

- (id) init
{
	return [self initWithEditingContext: nil];
}

- (void) dealloc
{
	DESTROY(_editingContext);
	[super dealloc];
}

- (NSSet *) rootObjects
{
	return (id)[[[[self editingContext] persistentRoots] mappedCollection] rootObject];
}

- (COSmartGroup *) allObjectGroup
{
	COSmartGroup *group = [[OMSmartGroup alloc]
		initWithObjectGraphContext: [COObjectGraphContext objectGraphContext]];
	[group setName: _(@"All Objects")];
	[group setContentBlock: ^ ()
	{
		return [[self  rootObjects] allObjects];
	}];
	return group;
}

- (NSArray *) libraries
{
	return [[[self editingContext] libraryGroup] contentArray];
}

- (COSmartGroup *) whereGroup
{
	// TODO: Turn whereGroup into a smart group that dynamically computes the content
	COSmartGroup *group = [[OMSmartGroup alloc]
		initWithObjectGraphContext: [COObjectGraphContext objectGraphContext]];
	id <ETCollection> content =
		[A([self allObjectGroup]) arrayByAddingObjectsFromArray: [self libraries]];

	[group setName: [_(@"Where") uppercaseString]];
	[group setTargetCollection: content];

	return group;
}

- (NSArray *) tagGroups
{
	return [[[self editingContext] tagLibrary] tagGroups];
}

- (COSmartGroup *) whatGroup
{
	COSmartGroup *group = [[OMSmartGroup alloc]
		initWithObjectGraphContext: [COObjectGraphContext objectGraphContext]];
	[group setName: [_(@"What") uppercaseString]];
	[group setTargetCollection: [self tagGroups]];
	return group;
}

- (COSmartGroup *) whenGroup
{
	COSmartGroup *group = [[OMSmartGroup alloc]
		initWithObjectGraphContext: [COObjectGraphContext objectGraphContext]];
	[group setName: [_(@"When") uppercaseString]];
	return group;
}

- (void) buildCoreObjectGraphDemoIfNeeded
{
	COSmartGroup *allObjectGroup = [self allObjectGroup];

	if ([[allObjectGroup content] isEmpty] == NO)
		return;

	[self buildCoreObjectGraphDemo];
	[allObjectGroup refresh];
	ETAssert([allObjectGroup isEmpty] == NO);
}

- (NSArray *) sourceListGroups
{
	[self buildCoreObjectGraphDemoIfNeeded];
	return A([self whereGroup], [self whatGroup], [self whenGroup]);
}

- (id) insertNewRootObjectWithEntityName: (NSString *)anEntityName
{
	return [[[self editingContext]
		insertNewPersistentRootWithEntityName: anEntityName] rootObject];
}

- (void) buildCoreObjectGraphDemo
{
	// TODO: For every library, the name should be made read-only.

	/* Cities */

	COObject *a1 = [self insertNewRootObjectWithEntityName: @"Anonymous.COObject"];
	COObject *a2 = [self insertNewRootObjectWithEntityName: @"Anonymous.COObject"];
	COObject *a3 = [self insertNewRootObjectWithEntityName: @"Anonymous.COObject"];

	[a1 setName: @"New York"];
	[a2 setName: @"London"];
	[a3 setName: @"Tokyo"];

	COLibrary *cityLibrary = [self insertNewRootObjectWithEntityName: @"Anonymous.COLibrary"];

	[cityLibrary setName: @"Cities"];
	[cityLibrary addObjects: A(a1, a2, a3)];

	/* Pictures */

	COObject *b1 = [self insertNewRootObjectWithEntityName: @"Anonymous.COObject"];
	COObject *b2 = [self insertNewRootObjectWithEntityName: @"Anonymous.COObject"];
	COObject *b3 = [self insertNewRootObjectWithEntityName: @"Anonymous.COObject"];
	COObject *b4 = [self insertNewRootObjectWithEntityName: @"Anonymous.COObject"];

	[b1 setName: @"Sunset"];
	[b2 setName: @"Eagle on a snowy Beach"];
	[b3 setName: @"Cloud"];
	[b4 setName: @"Fox"];

	COLibrary *pictureLibrary = [self insertNewRootObjectWithEntityName: @"Anonymous.COLibrary"];

	[pictureLibrary setName: @"Pictures"];
	[pictureLibrary addObjects: A(b1, b2, b3, b4)];

	/* Persons */

	COObject *c1 = [self insertNewRootObjectWithEntityName: @"Anonymous.COObject"];
	COObject *c2 = [self insertNewRootObjectWithEntityName: @"Anonymous.COObject"];

	[c1 setName: @"Ann"];
	[c2 setName: @"John"];

	COLibrary *personLibrary = [self insertNewRootObjectWithEntityName: @"Anonymous.COLibrary"];

	[personLibrary setName: @"Persons"];
	[personLibrary addObjects: A(c1, c2)];
	
	/* Scenery Tag */

	COTag *sceneryTag = [self insertNewRootObjectWithEntityName: @"Anonymous.COTag"];

	[sceneryTag setName: _(@"scenery")];
	[sceneryTag addObjects: A(b1, b2)];

	/* Animal Tag */

	COTag *animalTag = [self insertNewRootObjectWithEntityName: @"Anonymous.COTag"];

	[animalTag setName: _(@"animal")];
	[animalTag addObjects: A(b4, b2)];

	/* Rain Tag */

	COTag *rainTag = [self insertNewRootObjectWithEntityName: @"Anonymous.COTag"];

	[rainTag setName: _(@"rain")];
	[rainTag addObjects: A(a2, a3, b3, b4)];

	/* Snow Tag */

	COTag *snowTag = [self insertNewRootObjectWithEntityName: @"Anonymous.COTag"];

	[snowTag setName: _(@"snow")];
	[rainTag addObjects: A(a1, b2)];

	/* Tag Groups */

	COTagGroup *natureTagGroup = [self insertNewRootObjectWithEntityName: @"Anonymous.COTagGroup"];

	[natureTagGroup setName: _(@"Nature")];
	[natureTagGroup addObjects: A(sceneryTag, animalTag, rainTag, snowTag)];

	COTagGroup *weatherTagGroup = [self insertNewRootObjectWithEntityName: @"Anonymous.COTagGroup"];

	[weatherTagGroup setName: _(@"Weather")];
	[weatherTagGroup addObjects: A(rainTag, snowTag)];

	COTagGroup *unclassifiedTagGroup = [self insertNewRootObjectWithEntityName: @"Anonymous.COTagGroup"];

	[unclassifiedTagGroup setName: _(@"Unclassified")];

	/* Declare the groups used as tags and commit */

	[[[self editingContext] tagLibrary] addObjects: A(rainTag, sceneryTag, animalTag, snowTag)];
	[[[self editingContext] tagLibrary] setTagGroups: A(natureTagGroup, weatherTagGroup, unclassifiedTagGroup)];

	[[self editingContext] commitWithType: @"Object Creation"
	                     shortDescription: @"Created Initial Core Objects"];
	// TODO: Decide whether we support long description or not
	//[[self editingContext] commitWithMetadata: D(@"Object Creation", @"summary",
	//	@"Created Initial Core Objects", @"shortDescription",
	//	@"Created various core objects such as photos, cities etc. organized by tags and libraries", @"longDescription")];
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

@implementation COContainer (OMNote)

+ (NSMenuItem *) noteMenuItem
{
	NSMenuItem *menuItem = [NSMenuItem menuItemWithTitle: _(@"Note")
	                                                 tag: 0
	                                              action: NULL];

	[menuItem setRepresentedObject: self];

	NSMenu *menu = [menuItem submenu];

	[menu addItemWithTitle: _(@"New List…")
	                action: @selector(addNewList:)
	         keyEquivalent: @""];

	return menuItem;
}

+ (NSArray *) menuItems
{
	return A([self noteMenuItem]);
}

@end
