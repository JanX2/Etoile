/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  January 2007
	License:  Modified BSD  (see COPYING)
 */

#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETCollection+HOM.h>
#import <EtoileFoundation/ETUTI.h>
#import "ETController.h"
#import "ETLayoutItemBuilder.h"
#import "ETLayoutItemGroup+Mutation.h"
#import "ETLayoutItemGroup.h"
#import "NSObject+EtoileUI.h"
#import "ETCompatibility.h"


@implementation ETController

/** <init />
Initializes and returns a new controller which automatically rearrange objects.

For the Nib name and bundle arguments, see -[ETNibOwner initWithNibName:bundle:]. 

You can also use it -init to create a controller. See -[ETNibOwner init]. */
- (id) initWithNibName: (NSString *)aNibName bundle: (NSBundle *)aBundle
{
	self = [super initWithNibName: aNibName bundle: aBundle];
	if (nil == self)
		return nil;

	_observations = [[NSMutableSet alloc] init];
	[self setSortDescriptors: nil];
	_allowedPickTypes = [[NSArray alloc] init];
	_allowedDropTypes = [[NSMutableDictionary alloc] init];
	_editorItems = [[NSMutableSet alloc] init];
	_automaticallyRearrangesObjects = YES;

	return self;
}

- (void) stopObservation
{
	NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];

	FOREACH(_observations, observation, NSDictionary *)
	{
		[notifCenter removeObserver: [observation objectForKey: @"object"]];
	}
}

- (void) dealloc
{
	[self stopObservation];

	DESTROY(_observations);
	DESTROY(nibMainContent);
	DESTROY(_templateItem); 
	DESTROY(_templateItemGroup); 
	DESTROY(_objectClass); 
	DESTROY(_groupClass);
	DESTROY(_sortDescriptors);
	DESTROY(_filterPredicate);
	DESTROY(_allowedPickTypes);
	DESTROY(_allowedDropTypes);
	DESTROY(_editorItems);
	
	[super dealloc];
}

/* Nib Support */

- (id) rebuiltObjectForObject: (id)anObject builder: (id)aBuilder
{
	if ([anObject isLayoutItem] == NO && [anObject isView] == NO)
		return anObject;
	
	id newObject = [super rebuiltObjectForObject: anObject builder: aBuilder];

	if ([anObject isEqual: [self nibMainContent]])
	{
		ETAssert([newObject isLayoutItem]);

		[newObject setController: self];
		[self setNibMainContent: nil];
	}
	return newObject;
}

/** Returns the Nib top level object (e.g. a window or a view) that provides the 
item group expected to become the controller content and owner when 
-loadNibAndReturnContent is invoked. 

You shouldn't need to use this method. See -setNibMainContent:.*/
- (id) nibMainContent
{
	return nibMainContent;
}

/** Sets the Nib top level object (e.g. a window or a view) that provides the 
item group expected to become the controller content and owner when 
-loadNibAndReturnContent is invoked.

When no item can be retrieved, -loadNibAndReturnContent renders the Nib main 
content with -builder and uses the resulting item as the controller content.

You usally don't use this method but set the related outlet in IB/Gorm. */
- (void) setNibMainContent: (id)anObject
{
	if ([anObject isLayoutItem])
	{
		NSParameterAssert([anObject isGroup]);
	}
	ASSIGN(nibMainContent, anObject);
}

/** <override-dummy />
Renders view hierarchies reachable from the top level objects of the Nib into a 
layout item tree with -builder.

Are considered traversable the top level objects which returns YES to 
-isLayoutItem or -isView.

You can override this method to disable this behavior or extend the current one. */
- (void) didLoadNib
{
	[self rebuildTopLevelObjectsWithBuilder: [self builder]];
}

/** Don't use this method but -loadNibAndReturnContent.

Raises an exception. */
- (BOOL) loadNib
{
	[self doesNotRecognizeSelector: _cmd];
	return NO;
}

/** Loads the Nib file with the receiver as the File's Owner and returns the new 
controller content on success, otherwise returns nil and logs a failure message.

You must retain the returned item which owns the receiver once the method has 
returned. Later this item can be released to release the controller.<br />
During the Nib loading phase, the controller owns the Nib (precisely the top 
level objects), but just before returning it transfers the ownership back to 
the returned content (identical to -content) and releases the top level objects.
Which means every top level objects have to inserted into the item tree in 
-didLoadNib or retained with outlets (if you write a subclass).

Raises an exception if the bundle or the Nib itself cannot be found.<br />
Also raises an exception when the new controller content cannot be determined,  
-nibMainContent or -content returns nil. */
- (ETLayoutItemGroup *) loadNibAndReturnContent
{
	if ([self nibMainContent] == nil || [self content] == nil)
	{
		[NSException raise: NSInternalInconsistencyException 
		            format: @"%@ must have a valid -nibMainContent or -content to load a Nib", self];
		return nil;
	}
	
	BOOL nibLoaded = [super loadNib];

	if (NO == nibLoaded)
		return nil;

	ETAssert([content isLayoutItem] && [content isGroup]);

	/* Give the ownership back to the content (see also -rebuiltObjectForObject:builder:) */
	RETAIN(content);
	[[self topLevelObjects] removeObject: content];

	return AUTORELEASE(content);
}

/** Returns the content object which is either a layout item group or nil.

See also -setContent: and -[ETLayoutItemGroup controller].*/
- (ETLayoutItemGroup *) content
{
	return content;
}

/** You must use -[ETLayoutItem setController:] in your code and never this 
method which only exists to be used internally. 

Sets the content object that will be used as the base item for the layout 
item tree to be generated by this controller and put under its control.
 
The content must be nil or an ETLayoutItemGroup instance to be valid, otherwise
an invalid argument exception is raised. */
- (void) setContent: (ETLayoutItemGroup *)anItem
{
	BOOL notItemGroupKind = ([anItem isKindOfClass: [ETLayoutItemGroup class]] == NO);
	if (anItem != nil && notItemGroupKind)
	{
		[NSException raise: NSInvalidArgumentException format: @"-setContent: "
			"parameter %@ must be an ETLayoutItemGroup instance", anItem];
		return;
	}

	content = anItem;
}

/** <override-dummy />
Override to return property names which can be used with KVC to retrieve 
every layout item your subclass keeps track of.

You must override this method when a subclass stores ETLayoutItem or 
ETLayoutItemGroup objects (e.g. in an instance variable). Copying would 
otherwise be unreliable and controllers are required to be copiable.

When the controller is copied, -copyWithZone:content: will use the item index 
paths in the original content to resolve the named items in the controller copy. 

Returns an empty array by default. */
- (NSArray *) trackedItemPropertyNames
{
	return [NSArray array];
}

/* AppKit to EtoileUI Conversion */

/** Returns the AppKit to EtoileUI builder that converts AppKit windows, views 
etc. to items when a nib is loaded.

By default, returns an ETEtoileUIBuilder instance. */
- (ETLayoutItemBuilder *) builder
{
	return [ETEtoileUIBuilder builder];
}

/* Observation */

/** Adds the receiver as an observer on the given object and notification name 
combination to the default notification center.
 
The method bound to the given selector on the receiver will be called back, 
when the observed object posts a notification whose name matches aName.

Pass nil as the notification name, if you want to receive all notifications 
posted by the observed object.

The observed object must not be nil. */ 
- (void) startObserveObject: (id)anObject
        forNotificationName: (NSString *)aName 
                   selector: (SEL)aSelector
{
	NILARG_EXCEPTION_TEST(anObject);

	[_observations addObject: D(anObject, @"object", aName, @"name",  
		NSStringFromSelector(aSelector), @"selector")];

	[[NSNotificationCenter defaultCenter] addObserver: self
	                                         selector: aSelector
	                                             name: aName
	                                           object: anObject];
}

/** Removes the receiver as an observer on the given object and notification 
name combination from the default notification center.
 
Pass nil as the notification name, if you want to stop to receive any 
notification posted by the observed object.

The observed object must not be nil. */ 
- (void) stopObserveObject: (id)anObject forNotificationName: (NSString *)aName 
{
	NILARG_EXCEPTION_TEST(anObject);

	NSNotificationCenter *notifCenter = [NSNotificationCenter defaultCenter];
	BOOL removeAll = (nil == aName);

	FOREACH([NSSet setWithSet: _observations], observation, NSDictionary *)
	{
		id object = [observation objectForKey: @"object"];

		if (object != anObject)
			continue;

		id name = [observation objectForKey: @"name"];

		if ([name isEqual: aName] || removeAll)
		{
			[_observations removeObject: observation];
			[notifCenter removeObserver: self name: aName object: anObject];
		}
	}
}

/* Copying */

- (void) resolveTrackedItemsInCopy: (ETController *)newController
{
	ETLayoutItemGroup *newContent = newController->content;

	if (nil == newContent)
		return;

	NSParameterAssert(nil != content);

	FOREACH([self trackedItemPropertyNames], itemName, NSString *)
	{
		ETLayoutItem *item = [self valueForKey: itemName];
		
		NSAssert3(nil != item && [item isLayoutItem], @"Found no item "
			"identified by '%@' property in %@.\n Every name returned by "
			"-trackedItemPropertyNames must match a KVC-compliant properties in "
			"the controller and they must have a valid layout item set.", self, 
			itemName, content);

		NSIndexPath *indexPath = [content indexPathForItem: item];

		NSAssert3(nil != indexPath, @"Found no item at the index path in %@.\n "
			"The name '%@' returned by -trackedItemPropertyNames must "
			"identity a layout item that belongs to the controller content "
			"tree %@", self, itemName, content);

		ETLayoutItem *itemCopy = [newContent itemAtIndexPath: indexPath];
		NSParameterAssert(nil != itemCopy);
		
		[newController setValue: itemCopy forKey: itemName];
	}
}

- (void) setUpObserversForCopy: (ETController *)controllerCopy content: (ETLayoutItemGroup *)contentCopy
{
	FOREACH(_observations, observation, NSDictionary *)
	{ 
		id observedObject = [observation objectForKey: @"object"];

		NSParameterAssert(observedObject != nil);

		if ([observedObject isLayoutItem])
		{
			if (contentCopy != nil)
			{
				NSIndexPath *indexPath = [[self content] indexPathForItem: observedObject];
				observedObject = [[controllerCopy content] itemAtIndexPath: indexPath];
			}
			else
			{
				observedObject = nil;
			}
		}

		BOOL observedObjectUnresolved = (nil ==  observedObject);

		if (observedObjectUnresolved)
			continue;

		[controllerCopy startObserveObject: observedObject
		               forNotificationName: [observation objectForKey: @"name"]
		                          selector: NSSelectorFromString([observation objectForKey: @"selector"])];
	}
}

/** Returns a receiver copy which uses the given content.

This method is ETController designated copier. Subclasses that want to extend 
the copying support must invoke it instead of -copyWithZone:. */
- (id) copyWithZone: (NSZone *)aZone content: (ETLayoutItemGroup *)newContent
{
	ETController *newController = [[[self class] allocWithZone: aZone] init];

	newController->_observations = [[NSMutableSet allocWithZone: aZone] init];
	newController->_templateItem = [_templateItem copyWithZone: aZone];
	newController->_templateItemGroup = [_templateItemGroup copyWithZone: aZone];
	ASSIGN(newController->_objectClass, _objectClass);
	ASSIGN(newController->_groupClass, _groupClass);
	newController->_sortDescriptors = [_sortDescriptors copyWithZone: aZone];
	newController->_filterPredicate = [_filterPredicate copyWithZone: aZone];
	newController->_allowedPickTypes = [_allowedPickTypes copyWithZone: aZone];
	newController->_allowedDropTypes = [_allowedDropTypes mutableCopyWithZone: aZone];
	newController->_editorItems = [[NSMutableSet allocWithZone: aZone] init];
	newController->_automaticallyRearrangesObjects = _automaticallyRearrangesObjects;
	newController->_hasNewSortDescriptors = (NO == [_sortDescriptors isEmpty]);
	newController->_hasNewFilterPredicate = (nil != _filterPredicate);
	newController->_hasNewContent = NO;

	 /* When the copy was initially requested by -[ETLayoutItemGroup copyWithZone:], 
       -finishCopy: will be called back when the item copy is done. */
	if (nil == newContent)
	{
		[self finishDeepCopy: newController withZone: aZone content: newContent];
	}

	return newController;
}

- (void) finishDeepCopy: (ETController *)newController 
               withZone: (NSZone *)aZone
                content: (ETLayoutItemGroup *)newContent
{
	newController->content = newContent; /* Weak reference */

	[self resolveTrackedItemsInCopy: newController];
	[self setUpObserversForCopy: newController content: newContent];
}

/** Returns a receiver copy with a nil content.

You can set the returned controller content indirectly with 
-[ETLayoutItemGroup setController:].

To customize the copying in a subclass, you must override 
-copyWithZone:content:. */
- (id) copyWithZone: (NSZone *)aZone
{
	return [self copyWithZone: aZone content: nil];
}

/* Templates */

/** Returns the template item used to create leaf items. This template item
	is used as a prototype to make new layout items by 
	-[ETLayoutItemGroup newItem].
	This method returns nil by default and -[ETLayoutItemGroup newItem] will 
	simply create a new ETLayoutItem instance in such case. */
- (ETLayoutItem *) templateItem
{
	return _templateItem;
}

/** Returns the template item used to create branch items. This template item
	is used as a prototype to make new layout item groups by 
	-[ETLayoutItemGroup newItemGroup].
	This method returns nil by default and -[ETLayoutItemGroup newItemGroup] 
	will simply create a new ETLayoutItemGroup instance in such case. */
- (ETLayoutItemGroup *) templateItemGroup
{
	return _templateItemGroup;
}

/** Sets the template item used to create leaf items. This template item
	is used as a prototype to make new layout items by 
	-[ETLayoutItemGroup newItem].
	You can pass an instance of any ETLayoutItem class or subclass. */
- (void) setTemplateItem: (ETLayoutItem *)template
{
	ASSIGN(_templateItem, template);
}

/** Sets the template item used to create branch items. This template item
	is used as a prototype to make new layout item groups by 
	-[ETLayoutItemGroup newItemGroup].
	You can pass an instance of any ETLayoutItemGroup class or subclass. */
- (void) setTemplateItemGroup: (ETLayoutItemGroup *)template
{
	ASSIGN(_templateItemGroup, template);
}

/** Returns the class used to create model objects for leaf items. */
- (Class) objectClass
{
	return _objectClass;
}

/** Sets the class used to create model objects for leaf items.
	See also -newObject. */
- (void) setObjectClass: (Class)modelClass
{
	ASSIGN(_objectClass, modelClass);
}

/** Returns the group class used to create model objects for branch items.*/
- (Class) groupClass
{
	return _groupClass;
}
/** Sets the class used to create model objects for branch items.
	See also -newGroup. */
- (void) setGroupClass: (Class)modelClass
{
	ASSIGN(_groupClass, modelClass);
}

/** Creates and returns a new object that can be either a layout item clone of 
	-templateItem or a fresh instance of -objectClass. 
	If both a template item and an object class are set, the returned object 
	is a layout item with a new instance of -objectClass set as its 
	represented object. 
	This method is used by -add: and -insert: actions to generate the object 
	to be inserted into the content of the controller. 
	Take note that the autoboxing feature of -[ETLayoutItemGroup addObject:] 
	will take care of wrapping the created object into a layout item if needed.

The returned object is retained. */
- (id) newObject
{
	id object = nil;

	if ([self templateItem] != nil)
	{
		object = [content newItem]; /* Calls -templateItem */
	}

	if ([self objectClass] != nil)
	{
		id modelObject = [[[self objectClass] alloc] init];

		if (object != nil)
		{
			[object setRepresentedObject: AUTORELEASE(modelObject)];
		}
		else
		{
			object = modelObject;
		}
	}

	return object;
}

/** Creates and returns a new object group that can be either a layout item 
	group clone of -templateItemGroup or a fresh instance of -groupClass. 
	If both a template item group and an group class are set, the returned 
	object is a layout item group with a new instance of -groupClass set as its 
	represented object. 
	This method is used by -addGroup: and -insertGroup: actions to generate the 
	object to be inserted into the content of the controller. 
	Take note that the autoboxing feature of -[ETLayoutItemGroup addObject:] 
	will take care of wrapping the created object into a layout item if needed.

The returned object is retained. */
- (id) newGroup
{
	id object = nil;

	if ([self templateItemGroup] != nil)
	{
		object = [content newItemGroup]; /* Calls -templateItemGroup */
	}

	if ([self groupClass] != nil)
	{
		id modelObject = [[[self groupClass] alloc] init];

		if (object != nil)
		{
			[object setRepresentedObject: AUTORELEASE(modelObject)];
		}
		else
		{
			object = modelObject;
		}
	}

	return object;
}

/** Creates a new object by calling -newObject and adds it to the content. */
- (void) add: (id)sender
{
	[[self content] addObject: AUTORELEASE([self newObject])];
}

/** Creates a new object group by calling -newGroup and adds it to the content. */
- (void) addNewGroup: (id)sender
{
	[[self content] addObject: AUTORELEASE([self newGroup])];
}

/** Creates a new object by calling -newGroup and inserts it to the content at 
	-insertionIndex. */
- (void) insert: (id)sender
{
	[[self content] insertObject: AUTORELEASE([self newObject])
	                     atIndex: [self insertionIndex]];
}

/** Creates a new object group by calling -newGroup and inserts it to the 
	content at -insertionIndex. */
- (void) insertNewGroup: (id)sender
{
	[[self content] insertObject: AUTORELEASE([self newGroup])
	                     atIndex: [self insertionIndex]];
}

/** Removes all selected objects in the content. Selected objects are retrieved 
	by calling -selectedItemsInLayout on the content. */
- (void) remove: (id)sender
{
	NSArray *selectedItems = [[self content] selectedItemsInLayout];

	//ETLog(@"Will remove selected items %@", selectedItems);
	/* Removed items are temporarily retained by the array returned by 
	   -selectedItemsInLayout, therefore we can be sure we won't trigger the 
	   release of an already deallocated item. The typical case would be 
	   removing an item from a parent that was also selected and already got 
	   removed from the layout item tree. */
	[selectedItems makeObjectsPerformSelector: @selector(removeFromParent)];
}

/** Returns the next responder in the responder chain. 

The next responder is the enclosing item of the content unless specified otherwise.

You can override this method in a subclass, although it should rarely be needed. */
- (id) nextResponder
{
	return [[self content] enclosingItem];
}

/* Selection */

- (BOOL) setSelectionIndexes: (NSIndexSet *)selection
{
	[content setSelectionIndexes: selection];
	return YES;
}

- (NSMutableIndexSet *) selectionIndexes
{
	return [content selectionIndexes];
}
	
- (BOOL) setSelectionIndex: (unsigned int)index
{
	[content setSelectionIndex: index];
	return YES;
}

- (unsigned int) selectionIndex
{
	return [content selectionIndex];
}

/** Returns the position in the content, at which -insert: and -insertGroup: 
	will insert the object they create. The returned value is the last 
	selection index in the content. */
- (unsigned int) insertionIndex
{
	unsigned int index = [[[self content] selectionIndexes] lastIndex];

	/* No selection or no items */
	if (index == NSNotFound)
		index = [[self content] numberOfItems];

	return index;
}

/** Returns the sort descriptors used to sort the content associated with the 
receiver.

By default, returns an empty array. */
- (NSArray *) sortDescriptors
{
	return AUTORELEASE([_sortDescriptors copy]);
}

/** Set the sort descriptors used to sort the content associated with the 
receiver. */
- (void) setSortDescriptors: (NSArray *)sortDescriptors
{
	if (sortDescriptors != nil)
	{
		ASSIGNCOPY(_sortDescriptors, sortDescriptors);
	}
	else
	{
		_sortDescriptors = [[NSArray alloc] init];
	}
	_hasNewSortDescriptors = YES;
	if ([self automaticallyRearrangesObjects])
		[self rearrangeObjects];
}

/** Returns the search predicate to filter the controller content. */
- (NSPredicate *) filterPredicate
{
	return _filterPredicate;
}

/** Sets the search predicate to filter the controller content. */
- (void) setFilterPredicate: (NSPredicate *)searchPredicate
{
	ASSIGN(_filterPredicate, searchPredicate);
	_hasNewFilterPredicate = YES;
	if ([self automaticallyRearrangesObjects])
		[self rearrangeObjects];
}

/** Arranges the objects in the content by sorting them, then filtering them 
with -filterPredicate if the returned predicate is not nil. 

If the content is a tree structure, the entire tree is rearranged recursively 
by sorting and filtering each item group that get traversed.

You can override this method to implement another sort and filter strategy than 
the default one based on 
-[ETLayoutItemGroup sortWithSortDescriptors:recursively:], -sortDescriptors, 
-[ETLayoutItemGroup filterWithPredicate:recursively:] and -filterPredicate . */
- (void) rearrangeObjects
{
	if (_hasNewContent || _hasNewSortDescriptors)
		[content sortWithSortDescriptors: [self sortDescriptors] recursively: YES];

	if (_hasNewContent || _hasNewFilterPredicate)
		[content filterWithPredicate: [self filterPredicate] recursively: YES];

	if (_hasNewContent || _hasNewSortDescriptors || _hasNewFilterPredicate)
		[content updateLayout];
}

/** Returns whether -rearrangeObjects should be automatically called when 
-setFilterPredicate: is called.

Returns YES by default. */
- (BOOL) automaticallyRearrangesObjects
{
	return _automaticallyRearrangesObjects;
}

/** Sets whether -rearrangeObjects should be automatically called when 
-setFilterPredicate: is called. */
- (void) setAutomaticallyRearrangesObjects: (BOOL)flag
{
	_automaticallyRearrangesObjects = flag;
}

/* Pick and Drop */

- (NSArray *) allowedPickTypes
{
	return _allowedPickTypes;
}

- (void) setAllowedPickTypes: (NSArray *)UTIs
{
	NILARG_EXCEPTION_TEST(UTIs)
	ASSIGN(_allowedPickTypes, UTIs);
}

/* -allowedDropTypesForTargetType: can be rewritten with HOM. Not sure it won't
too slow given that the method tends to be invoked repeatedly.

	NSArray *matchedTargetTypes = [[[_allowedDropTypes allKeys] filter] conformsToType: targetType];
	NSArray *matchedDropTypeArrays = [_allowedDropTypes objectsForKeys: matchedTargetTypes
	                                                    notFoundMarker: [NSNull null]];

	return [matchedDropTypeArrays flattenedCollection]; */

- (NSArray *) allowedDropTypesForTargetType: (ETUTI *)aUTI
{
	NILARG_EXCEPTION_TEST(aUTI)
	NSMutableArray *matchedDropTypes = [NSMutableArray arrayWithCapacity: 100];
	
	FOREACH([_allowedDropTypes allKeys], targetType, ETUTI *)
	{
		if ([aUTI conformsToType: targetType])
		{
			[matchedDropTypes addObjectsFromArray: [_allowedDropTypes objectForKey: targetType]];
		}
	}

	return matchedDropTypes;
}

- (void) setAllowedDropTypes: (NSArray *)UTIs forTargetType: (ETUTI *)targetUTI
{
	NILARG_EXCEPTION_TEST(targetUTI)
	NILARG_EXCEPTION_TEST(UTIs)
	[_allowedDropTypes setObject: UTIs forKey: targetUTI];
}

/* Editing (NSEditor and NSEditorRegistration Protocols) */

/** Returns YES when one or several editors are registered, otherwise NO. */
- (BOOL) isEditing
{
	return ([_editorItems isEmpty] == NO);
}

/** Tries to commit all the pending changes existing the current editors that 
were previously registered with -objectDidBeginEditing:.

When all pending changes have been committed and all editors have been 
unregistered returns YES, otherwise returns NO. */
- (BOOL) commitEditing
{
	FOREACH(_editorItems, item, ETLayoutItem *)
	{
		if ([item commitEditing] == NO)
		{
			return NO;
		}
		[_editorItems removeObject: item];
	}
	return YES;
}

/** Discards all the pending changes existing the current editors that 
were previously registered with -objectDidBeginEditing:.

All the editors get unregistered. */
- (void) discardEditing
{
	[[_editorItems map] discardEditing];
	[_editorItems removeAllObjects];	
}

/** Notifies the controller the given item has begun to be edited.

You should never need to invoke this method.<br />
See instead -[ETLayoutItem objectDidBeginEditing:]. */
- (void) objectDidBeginEditing: (ETLayoutItem *)anItem
{
	[_editorItems addObject: anItem];
}

/** Notifies the controller the editing which was underway in the given item 
has ended.

You should never need to invoke this method.<br />
See instead -[ETLayoutItem objectDidEndEditing:]. */
- (void) objectDidEndEditing: (ETLayoutItem *)anItem
{
	[_editorItems removeObject: anItem];
}

@end

