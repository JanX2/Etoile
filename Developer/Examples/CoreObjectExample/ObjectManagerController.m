/*
   Copyright (C) 2008 Quentin Mathe <qmathe@club-internet.fr>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import "ObjectManagerController.h"
#import "Model.h"

@interface COObjectContext (Private)
- (int) lookUpVersionIfRestorePointAtVersion: (int)aVersion;
@end


@implementation ObjectManagerController

/* Builds the UI */
- (ETLayoutItemGroup *) objectNavigatorItem
{
	ETLayoutItemGroup *navigatorItem = [ETLayoutItem itemGroupWithContainer];
	ETLayoutItem *selectionVersionFieldItem = [ETLayoutItem textField];
	/*ETLayoutItem *explanationLabelItem = [ETLayoutItem labelWithTitle: 
		_(@"You can restore a single object or the entire model object graph to "
		   "a past version by typing it respectively in Selection Version field "
		   "or Context Version field.\n"
		   "Each object is versionned independently of the object graph that "
		   "itself versionned as part of the Object Context.")];*/
	ETLayoutItem *selectionVersionLabelItem = [ETLayoutItem labelWithTitle: _(@"Selection Version:")];
	ETLayoutItem *ctxtVersionFieldItem = [ETLayoutItem textField];
	ETLayoutItem *ctxtVersionLabelItem = [ETLayoutItem labelWithTitle: _(@"Context Version:")];
	ETLayoutItem *restoredCtxtVersionFieldItem = [ETLayoutItem textField];
	ETLayoutItem *restoredCtxtVersionLabelItem = [ETLayoutItem labelWithTitle: _(@"Restored Context Version:")];
	ETLayoutItemGroup *mainContainerItem = [ETLayoutItem itemGroupWithContainer];

	[navigatorItem setHeight: 500];
	[navigatorItem setWidth: 800];
	[(ETContainer *)[navigatorItem supervisorView] setEnablesHitTest: YES];
	[[mainContainerItem view] setAutoresizingMask: NSViewWidthSizable];
	[mainContainerItem setHeight: 200];
	[mainContainerItem setWidth: 775];

	[navigatorItem setLayout: [ETStackLayout layout]];
	[(ETComputedLayout *)[navigatorItem layout] setItemMargin: 15];
	[(ETComputedLayout *)[navigatorItem layout] setItemSizeConstraintStyle: ETSizeConstraintStyleNone];
	[navigatorItem addItem: mainContainerItem];
	//[navigatorItem addItem: explanationLabelItem];
	[navigatorItem addItem: selectionVersionLabelItem];
	[navigatorItem addItem: selectionVersionFieldItem];
	[navigatorItem addItem: ctxtVersionLabelItem];
	[navigatorItem addItem: ctxtVersionFieldItem];
	[navigatorItem addItem: restoredCtxtVersionLabelItem];
	[navigatorItem addItem: restoredCtxtVersionFieldItem];
	[navigatorItem updateLayout];

	mainContainer = [mainContainerItem supervisorView];
	selectionVersionField = (NSTextField *)[selectionVersionFieldItem view];
	ctxtVersionField = (NSTextField *)[ctxtVersionFieldItem view];
	restoredCtxtVersionField = (NSTextField *)[restoredCtxtVersionFieldItem view];
	[ctxtVersionField setAction: @selector(fieldVersionDidChange:)];
	[ctxtVersionField setTarget: self];
	[selectionVersionField setAction: @selector(fieldVersionDidChange:)];
	[selectionVersionField setTarget: self];

	return navigatorItem;
}

- (COGroup *) startGroupWithUUID: (ETUUID *)aLibraryUUID
{
	BOOL isNewLibrary = (aLibraryUUID == nil);
	id startGroup = nil;
	
	if (isNewLibrary)
	{
		startGroup = [self startGroup];
	}
	else
	{
		startGroup = [[COObjectContext currentContext] objectForUUID: aLibraryUUID];
		BOOL isInvalidUUID = (startGroup == nil);

		if (isInvalidUUID)
			startGroup = [self startGroup];
	}
	
	return startGroup;
}

#define NEW(X) (AUTORELEASE([[X alloc] init]))

- (COGroup *) startGroup
{
	COObject *object = NEW(SubObject);
	COObject *object2 = NEW(SubObject);
	COObject *object3 = NEW(SubObject);
	COGroup *group = NEW(COGroup);
	COGroup *group2 = NEW(COGroup);
	COGroup *group3 = NEW(COGroup);

	[object setValue: @"Azalea" forProperty: @"whoami"];
	[object2 setValue: @"Koelr" forProperty: @"whoami"];
	[object3 setValue: @"Cloud" forProperty: @"whoami"];
	[group setValue: @"Flowers" forProperty: kCOGroupNameProperty];
	[group2 setValue: @"Weather" forProperty: kCOGroupNameProperty];
	[group3 setValue: @"Cities" forProperty: kCOGroupNameProperty];

	[group addMember: object]; // version 13
	[group addMember: object2];
	[group addGroup: group2];
	[group addGroup: group3];
	[group2 addMember: object];

	[group removeMember: object2]; // version 18
	[group removeMember: group3];
	[group2 addGroup: group3];

	[group3 setValue: @"Around the World" forProperty: kCOGroupNameProperty]; // version 21
	[object3 setValue: A(@"New York", @"Minneapolis", @"London") forProperty: @"otherObjects"];
	[group3 addMember: object3];
	[group2 setValue: @"More Flowers" forProperty: kCOGroupNameProperty];
	[group2 addMember: object2]; // version 25

	return group;
}

- (id) setUpPersistency
{
	/* Turn on persistency */
	[COGroup setAutomaticallyMakeNewInstancesPersistent: YES];
	[SubObject setAutomaticallyMakeNewInstancesPersistent: YES];

	/* Recreate persistency context and core object graph entry point 
	   identified by UUID in defaults. If nil is read from the defaults, 
	   -initWithUUID and -startGroupWithUUID: will create respectively a 
	   new context and a new library (aka start group). */
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	COObjectContext *context = [(COObjectContext *)[COObjectContext alloc] initWithUUID: 
		[defaults UUIDForKey: @"StuffContextUUID"]];
	[COObjectContext setCurrentContext: context];
	COGroup *startGroup = [self startGroupWithUUID: [defaults UUIDForKey: @"StuffLibraryUUID"]];

	// NOTE: We could also retrieve the context with -[COObjectContext currentContext]
	/* Set the delegate to catch the merged objects when a old version is 
	   restored (either the whole context or a single object). */
	[[startGroup objectContext] setDelegate: self];

	/* Update defaults in case no values where previously written (new context 
	   and library just created)*/
	[defaults setUUID: [context UUID] forKey: @"StuffContextUUID"];
	[defaults setUUID: [startGroup UUID] forKey: @"StuffLibraryUUID"];

	ETLog(@"Found Stuff library %@ with context %@", startGroup, context);

	return startGroup;
}

- (void) awakeFromNib
{
	COGroup *startGroup = [self setUpPersistency];

	/* Set up UI */

	// TODO: Add a return type to -windowGroup to work around NSMenuItem 
	// protocol and excessive type checking of GCC. Or better fix GCC :-)
	[(ETLayoutItemGroup *)[ETLayoutItem windowGroup] addItem: [self objectNavigatorItem]];

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver: self 
           selector: @selector(mainContainerDidResize:) 
               name: NSViewFrameDidChangeNotification 
             object: mainContainer];

	ETLayout *layout = AUTORELEASE([[ETOutlineLayout alloc] init]);

	// TODO: At later point, work out something like...
	// [layout setDisplayedProperties: [startGroup displayProperties]];
	[layout setDisplayedProperties: 
		A(@"icon", @"displayName", @"otherObjects", @"objectVersion", @"kCOUIDProperty")];

	[mainContainer setAllowsMultipleSelection: NO];
	[[mainContainer layoutItem] setRepresentedObject: startGroup];
	[(ETLayoutItemGroup *)[mainContainer layoutItem] setShouldMutateRepresentedObject: YES];
	[mainContainer setSource: [mainContainer layoutItem]];
	[mainContainer setHasVerticalScroller: YES];
	[mainContainer setHasHorizontalScroller: YES];
	[mainContainer setLayout: layout];
	[mainContainer setDelegate: self];
	[mainContainer reloadAndUpdateLayout];

	[self updateUI];
}

- (NSArray *) firstSelectedModelObject
{
	ETLayoutItem *selectedItem = [[mainContainer selectedItemsInLayout] firstObject];

	return [selectedItem representedObject];
}

- (void) updateUI
{
	[ctxtVersionField setIntValue: [[COObjectContext currentContext] version]];

	id selectedModel = [self firstSelectedModelObject];

	if (selectedModel != nil)
	{
		[selectionVersionField setIntValue: [selectedModel objectVersion]];
	}
	else
	{
		[selectionVersionField setStringValue: @""];	
	}
}

- (void) objectContextDidMergeObjects: (NSNotification *)notif
{
	id startGroup = [[mainContainer layoutItem] representedObject];
	// NOTE: the next line is equivalent to...
	// [[[notif object] objectServer] cachedObjectForUUID: [startGroup UUID]]
	id newStartGroup = [[notif object] objectForUUID: [startGroup UUID]];

	ETLog(@"Did merge old %@ with %@ in %@ - %@", startGroup, newStartGroup, 
		[notif object], [notif userInfo]);
	ETLog(@"New start group members: %@", [newStartGroup allObjects]);

	[[mainContainer layoutItem] setRepresentedObject: newStartGroup];
	[mainContainer reloadAndUpdateLayout];

	[self updateUI];
}

- (void) fieldVersionDidChange: (id)sender
{
	int version = [sender intValue];

	if ([sender isEqual: ctxtVersionField])
	{
		[[COObjectContext currentContext] restoreToVersion: version];

		int restoredVersion = [[COObjectContext currentContext] 
			lookUpVersionIfRestorePointAtVersion: version];
		[restoredCtxtVersionField setIntValue: restoredVersion];
	}
	else if ([sender isEqual: selectionVersionField])
	{
		[[COObjectContext currentContext] 
			objectByRestoringObject: [self firstSelectedModelObject] 
			              toVersion: version
			       mergeImmediately: YES];
	}
}

- (void) containerSelectionDidChange: (NSNotification *)notif
{
	[self updateUI];
}

- (void) mainContainerDidResize: (NSNotification *)notif
{
	if ([mainContainer canUpdateLayout])
		[mainContainer updateLayout];
}

@end

/* Patch -startGroup to create the object graph that is used by COObjectContext 
   test suite. Useful to verify the graph coherency visually. */
#ifdef TEST
@implementation ObjectManagerController (TestObjectGraph)

- (id) startGroup
{
	COObject *object;
	COObject *object2;
	COObject *object3;
	COGroup *group;
	COGroup *group2;
	COGroup *group3;

	// context v0
	object = [[SubObject alloc] init]; // context v1
	object2 = [[SubObject alloc] init];
	object3 = [[SubObject alloc] init];
	group = [[COGroup alloc] init];
	group2 = [[COGroup alloc] init];
	group3 = [[COGroup alloc] init];

	[group2 setValue: @"blizzard" forProperty: kCOGroupNameProperty];
	[group2 setValue: @"cloud" forProperty: kCOGroupNameProperty];
	[group2 addMember: object2]; 
	[group2 setValue: @"tulip" forProperty: kCOGroupNameProperty];
	[group addMember: object];
	[group addGroup: group2];  // context v12
	[group addGroup: group3]; 
	[group removeGroup: group2]; 
	[group2 addMember: object3];

	[object setValue: @"me" forProperty: @"whoami"]; 
	[object setValue: A(@"New York", @"Minneapolis", @"London") forProperty: @"otherObjects"]; // context v17

	return group;
}

@end
#endif
