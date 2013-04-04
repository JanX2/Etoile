/*
	Copyright (C) 2013 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  March 2013
	License:  Modified BSD  (see COPYING)
 */

#import "OMModelFactory.h"

@implementation OMModelFactory

- (COSmartGroup *) whereGroup
{
	// TODO: Turn whereGroup into a smart group that dynamically computes the content
	COSmartGroup *whereGroup = [[OMSmartGroup alloc] init];
	COSmartGroup *mainGroup = [[COEditingContext currentContext] mainGroup];
	id <ETCollection> content = [A(mainGroup) arrayByAddingObjectsFromArray:
		[[[COEditingContext currentContext] libraryGroup] contentArray]];

	[whereGroup setName: [_(@"Where") uppercaseString]];
	[whereGroup setTargetCollection: content];

	return whereGroup;
}

- (COSmartGroup *) whatGroup
{
	COSmartGroup *whatGroup = [[OMSmartGroup alloc] init];
	id <ETCollection> content = [[[COEditingContext currentContext] tagLibrary] tagGroups];

	[whatGroup setName: [_(@"What") uppercaseString]];
	[whatGroup setTargetCollection: content];

	return whatGroup;
}

- (COSmartGroup *) whenGroup
{
	COSmartGroup *whenGroup = [[OMSmartGroup alloc] init];
	
	[whenGroup setName: [_(@"When") uppercaseString]];
	
	return whenGroup;
}

- (NSArray *) sourceListGroups
{
	COSmartGroup *mainGroup = [[COEditingContext currentContext] mainGroup];

	if ([[mainGroup content] isEmpty])
	{
		[self buildCoreObjectGraphDemo];
		[mainGroup refresh];
		ETAssert([mainGroup count] > 0);
	}

	return A([self whereGroup], [self whatGroup], [self whenGroup]);
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
	//[[ctxt libraryGroup] addObjects: A(cityGroup, pictureGroup, personGroup)];
	
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
	[[ctxt tagLibrary] setTagGroups: A(natureTagGroup, weatherTagGroup, unclassifiedTagGroup)];

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
