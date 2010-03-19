/*
   Copyright (C) 2007 Yen-Ju Chen <yjchenx gmail>

   This application is free software; you can redistribute it and/or 
   modify it under the terms of the MIT license. See COPYING.

*/

#import <strings.h>
#import "COObject.h"
#import "COMultiValue.h"
#import "COObjectContext.h"
#import "NSObject+CoreObject.h"
#import "GNUstep.h"

static NSMutableDictionary *propertyTypes;

/* Properties */
NSString *kCOUIDProperty = @"kCOUIDProperty";
NSString *kCOVersionProperty = @"kCOVersionProperty";
NSString *kCOCreationDateProperty = @"kCOCreationDateProperty";
NSString *kCOModificationDateProperty = @"kCOModificationDateProperty";
NSString *kCOReadOnlyProperty = @"kCOReadOnlyProperty";
 /* Transient property (see -finishedDeserializing) */
NSString *kCOParentsProperty = @"kCOParentsProperty";
NSString *kCOSizeProperty = @"kCOSizeProperty";
NSString *kCOTypeNameProperty = @"kCOTypeNameProperty";

NSString *qCOTextContent = @"qCOTextContent";

/* Notifications */
NSString *kCOObjectChangedNotification = @"kCOObjectChangedNotification";
NSString *kCOUpdatedProperty = @"kCOUpdatedProperty";
NSString *kCORemovedProperty = @"kCORemovedProperty";

@interface COObject (FrameworkPrivate)
- (void) setObjectContext: (COObjectContext *)ctxt;
@end

@interface COObject (COPropertyListFormat)
- (void) _readObjectVersion1: (NSDictionary *)propertyList;
- (NSMutableDictionary *) _outputObjectVersion1;
@end

@interface COObject (Private)
- (NSString *) _textContent;
@end


@implementation COObject

/* Data Model Declaration */

/** <p>If you want to create a subclass of a CoreObject data model class, you 
    should declare the new properties and types of the class by creating a 
    dictionary with types as objects and keys as properties, then calls 
    +addPropertiesAndTypes: with this dictionary as parameter.</p>
    <p>Each type must be a <code>NSNumber</code> initialized with one of the type constants 
    defined in <file>COPropertyType.h</file>. Each property must be a string that uniquely 
    identifies the property by its name, and whose name doesn't collide with a 
    property inherited from superclasses. For properties, you typically declare 
    your owns as string constants with an identifier name prefixed by <em>k</em> and
    suffixed by <em>Property</em>. For example, see <file>COObject.h</file> which exposes all 
    properties of the COObject data model class.</p>
    <p>When you create a subclass of COObject some other subclasses such as 
    <ref type="class" id="COGroup">COGroup</ref>, you  must first call +initialize on your superclass to get all 
    inherited properties and types registered for your subclass. This only holds 
    for the GNU runtime though, and may change in future if CoreObject was 
    ported to another runtime.</p> */
+ (void) initialize
{
	NSDictionary *pt = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSNumber numberWithInt: kCOStringProperty], 
			kCOUIDProperty,
		[NSNumber numberWithInt: kCOIntegerProperty], 
			kCOVersionProperty,
		[NSNumber numberWithInt: kCODateProperty], 
			kCOCreationDateProperty,
		[NSNumber numberWithInt: kCODateProperty], 
			kCOModificationDateProperty,
		[NSNumber numberWithInt: kCOIntegerProperty], 
			kCOReadOnlyProperty,
		[NSNumber numberWithInt: kCOArrayProperty], 
			kCOParentsProperty,
		nil];
	[self addPropertiesAndTypes: pt];
	DESTROY(pt);
}

/** <p>Declares new properties for the data model associated with this class.</p>
    <p>The property declaration is a list of property type keyed by property 
    names.</p> */
+ (int) addPropertiesAndTypes: (NSDictionary *) properties
{
	if (propertyTypes == nil)
	{
		propertyTypes = [[NSMutableDictionary alloc] init];
	}

	NSMutableDictionary *dict = [propertyTypes objectForKey: NSStringFromClass([self class])];
	if (dict == nil)
	{
		dict = [[NSMutableDictionary alloc] init];
		[propertyTypes setObject: dict forKey: NSStringFromClass([self class])];
		RELEASE(dict);
	}
	int i, count;
	NSArray *allKeys = [properties allKeys];
	NSArray *allValues = [properties allValues];
	count = [allKeys count];
	for (i = 0; i < count; i++)
	{
		[dict setObject: [allValues objectAtIndex: i]
		      forKey: [allKeys objectAtIndex: i]];
	}
	return count;
}

/** <p>Returns the property types keyed by property names for the data model 
    that has been declared for this class, by calling 
    +addPropertiesAndTypes: and +removeProperties: either on this class or a 
    superclass.</p>
    <p>The data model includes the properties declared either on this class or 
    inherited from a superclass, see +initialize.</p> */
+ (NSDictionary *) propertiesAndTypes
{
	return [propertyTypes objectForKey: NSStringFromClass([self class])];
}

/** <p>Returns the property names of the data model declared for this class.</p>
    <p>The data model includes the properties declared either on this class or 
    inherited from a superclass, see +initialize.</p> */
+ (NSArray *) properties
{
	if (propertyTypes == nil)
		return nil;

	NSDictionary *dict = [propertyTypes objectForKey: NSStringFromClass([self class])];
	if (dict == nil)
		return nil;

	return [dict allKeys];
}

/** <p>Removes declared properties (type/name pairs) from the data model, that 
    match a property name from properties array.</p>
    <p>The data model includes the properties declared either on this class or 
    inherited from a superclass, see +initialize.</p>
    <p>Removing a property that is inherited from a superclass, won't remove it 
    in the superclass data model, but only from the receiver class data model.</p> */
+ (int) removeProperties: (NSArray *) properties
{
	if (propertyTypes == nil)
		return 0;
	NSMutableDictionary *dict = [propertyTypes objectForKey: NSStringFromClass([self class])];
	if (dict == nil)
	{
		return 0;
	}
	NSEnumerator *e = [properties objectEnumerator];
	NSArray *allKeys = [dict allKeys];
	NSString *key = nil;
	int count = 0;
	while ((key = [e nextObject]))
	{
		if ([allKeys containsObject: key])
		{
			[dict removeObjectForKey: key];
			count++;
		}
	}
	return count;
}

/** <p>Returns the type of a property declared in the data model for the given 
    property name.</p>
    <p>The data model includes the properties declared either on this class or 
    inherited from a superclass, see +initialize.</p> */
+ (COPropertyType) typeOfProperty: (NSString *) property
{
	if (propertyTypes == nil)
		return kCOErrorInProperty;

	NSDictionary *dict = [propertyTypes objectForKey: NSStringFromClass([self class])];
	if (dict == nil)
	{
		return kCOErrorInProperty;
	}

	NSNumber *type = [dict objectForKey: property];
	if (type)
		return [type intValue];
	else
		return kCOErrorInProperty;
}

/* Factory Method */

/** <p>Returns a core object graph by importing propertyList.</p>
    <p>See -initWithPropertyList:.</p> */
+ (id) objectWithPropertyList: (NSDictionary *) propertyList
{
	id object = nil;
	if ((object = [propertyList objectForKey: pCOClassKey]) &&
	    ([object isKindOfClass: [NSString class]]))
	{
		Class oClass = NSClassFromString((NSString *)object);
		return AUTORELEASE([[oClass alloc] initWithPropertyList: propertyList]);
	}
	return nil;
}

/* Property List Import/Export */

/** <p></p> */
- (id) initWithPropertyList: (NSDictionary *) propertyList
{
	self = [self init];
	if ([propertyList isKindOfClass: [NSDictionary class]] == NO)
	{
		NSLog(@"Error: Not a valid property list: %@", propertyList);
		[self dealloc];
		return nil;
	}
	/* Let check version */
	NSString *v = [propertyList objectForKey: pCOVersionKey];
	if ([v isEqualToString: pCOVersion1Value])
	{
		[self _readObjectVersion1: propertyList];
	}
	else
	{
		NSLog(@"Unknown version %@", v);
		[self dealloc];
		return nil;
	}

	return self;
}

/** <p>Returns the receiver data model as a property list.</p>
    <p>You can use this method for exporting and -initWithPropertyList: as the 
    symetric method for importing.</p>
    <p>If you want to export an object graph rather than a single object, use 
    -[COGroup propertyList].</p> */
- (NSMutableDictionary *) propertyList
{
	return [self _outputObjectVersion1];
}

/* Common Methods */

/** <init /><p></p> */
- (id) init
{
	self = [super init];

	_properties = [[NSMutableDictionary alloc] init];
	[self setValue: [NSNumber numberWithInt: 0] 
	      forProperty: kCOReadOnlyProperty];
	[self setValue: [NSString UUIDString]
	      forProperty: kCOUIDProperty];
	[self setValue: [NSNumber numberWithInt: 0]
	      forProperty: kCOVersionProperty];
	[self setValue: [NSDate date]
	      forProperty: kCOCreationDateProperty];
	[self setValue: [NSDate date]
	      forProperty: kCOModificationDateProperty];
    [self setValue: [NSMutableArray array]
          forProperty: kCOParentsProperty]; /* Transient property */
	_nc = [NSNotificationCenter defaultCenter];

	/* We get the object context at the end, hence all the previous calls are 
	   not serialized by RECORD in -setValue:forProperty: 
	   FIXME: Should be obtained by parameter usually. */
	_objectVersion = -1;
	[self tryStartPersistencyIfInstanceOfClass: [COObject class]];

	return self;
}

/** <p></p> */
- (BOOL) tryStartPersistencyIfInstanceOfClass: (Class)aClass
{
	BOOL isNotSubclassInstance = [self isMemberOfClass: aClass];
	
	if ([[self class] automaticallyMakeNewInstancesPersistent]
	   && isNotSubclassInstance)
	{
		[[COObjectContext currentContext] insertObject: self];
		[self enablePersistency];
		return YES;
	}
	
	return NO;
}

- (void) dealloc
{
	DESTROY(_properties);
	// NOTE: _objectContext is a weak reference
	
	[super dealloc];
}

// TODO: Turn this into -shortDescription probably and add a more detailed 
// -description that ouputs all the properties. 
// Take note that [_properties description] won't work, because...
// -description triggers -description on kCOParentsProperty and each element 
// is a COGroup instances which will call -description on 
// kCOGroupChildrenProperty and kCOGroupSubgroupsProperty. This will call back 
// -description on the receiver and results in an infinite recursion.
- (NSString *) description
{
	NSString *desc = [super description];

	return [NSString stringWithFormat: @"%@ id: %@ version: %i", desc, 
		[self UUID], [self objectVersion]];
}

/** <p>Returns YES. See COManagedObject protocol.</p> */
- (BOOL) isCoreObject
{
	return YES;
}

/** <p>Returns YES. See COManagedObject protocol.</p> */
- (BOOL) isManagedCoreObject
{
	return YES;
}

- (BOOL) isCopyPromise
{
	return NO;
}

// FIXME: Implement
- (NSDictionary *) metadatas
{
	return nil;
}

/* Managed Object Edition */

/** <p>Returns the properties published by the receiver and accessible through 
    <em>Property Value Coding</em>. The returned array includes the properties 
    inherited from the superclass too, see -[NSObject properties].</p> */
- (NSArray *) properties
{
	return [[super properties] arrayByAddingObjectsFromArray: [[self class] properties]];
}

/** <p></p> */
- (BOOL) removeValueForProperty: (NSString *) property
{
	if (IGNORE_CHANGES || [self isReadOnly])
		return NO;

	RECORD(property)
	[_properties removeObjectForKey: property];
	[self setValue: [NSDate date] forProperty: kCOModificationDateProperty];
    [_nc postNotificationName: kCOObjectChangedNotification
         object: self
	     userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
	                 property, kCORemovedProperty, nil]];
	END_RECORD

	return YES;
}

/** <p></p> */
- (BOOL) setValue: (id) value forProperty: (NSString *) property
{
	if (IGNORE_CHANGES || [self isReadOnly])
		return NO;

	RECORD(value, property)
	[_properties setObject: value forKey: property];
	[_properties setObject: [NSDate date] 
	                forKey: kCOModificationDateProperty];
    [_nc postNotificationName: kCOObjectChangedNotification
         object: self
	     userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
	                 property, kCOUpdatedProperty, nil]];
	END_RECORD

	return YES;
}

/** <p>Returns the value identified by property. If the property doesn't exist,
    returns nil.</p>
    <p>First try to find the property in the receiver data model. If no property is 
    found, try to find it in the properties inherited from the superclass.</p>
    <p>Take note that COObject only inherits properties from <code>NSObject</code>.</p> */
- (id) valueForProperty: (NSString *) property
{
	id value = [_properties objectForKey: property];
	
	/* Pass up to NSObject+Model if not declared in our data model */
	if (value == nil && [[[self class] properties] containsObject: property] == NO)
		value = [super valueForProperty: property];

	return value;
}

/** <p></p> */
- (NSArray *) parentGroups
{
    NSMutableSet *set = AUTORELEASE([[NSMutableSet alloc] init]);
    NSArray *value = [self valueForProperty: kCOParentsProperty];
    if (value)
    {
        [set addObjectsFromArray: value];

        int i, count = [value count];
        for (i = 0; i < count; i++)
        {
            [set addObjectsFromArray: [[value objectAtIndex: i] parentGroups]];
        }
    }
    return [set allObjects];
}

/** <p>Returns whether the receiver is in read-only mode.</p> */
- (BOOL) isReadOnly
{	
	return ([[self valueForProperty: kCOReadOnlyProperty] intValue] == 1);
}

/** <p>Returns the version of the object format, plays a role similar to class 
    versioning provided by +[NSObject version].</p> */
- (int) version
{
	return [(NSNumber *)[self valueForProperty: kCOVersionProperty] intValue];
}

/* Persistency */

/** <p>Returns an array of all selectors names whose methods calls can trigger
    persistency, by handing an invocation to the object context which can in  
    turn record it and snapshot the receiver if necessary.</p>
    <p>All messages which are persistency method calls are persisted only if necessary, 
    so if such a message is sent by another managed object part of the same 
    object context, it won't be recorded (see COObjectContext for a more 
    thorough explanation).</p>
    <p>This method plays no role currently, if we put aside some runtime 
    reflection that could be eventually done with it. In future, by overriding 
    this method, you will be able to declare which methods should automatically 
    trigger persistency without having to rely on RECORD and END_RECORD macros 
    in your method body.</p> */
- (NSArray *) persistencyMethodNames
{
	return A(NSStringFromSelector(@selector(setValue:forProperty:)),
	         NSStringFromSelector(@selector(removeValueForProperty:)));
}

static NSMutableSet *automaticPersistentClasses = nil;

/** <p>Returns whether the instances, that are members of this specific class, are 
    made persistent when they are initialized.</p>
    <p>Returns NO by default, but this is subject to change in future.</p> */
+ (BOOL) automaticallyMakeNewInstancesPersistent
{
	return [automaticPersistentClasses containsObject: self];
}

/** <p>Sets whether the instances, that are members of this specific class, are 
    made persistent when they are initialized.</p>
    <p>An instance becomes persistent by registering it in an object context and 
    sending it -enablePersistency. See -tryStartPersistencyIfInstanceOfClass: 
    to do so.</p> */
+ (void) setAutomaticallyMakeNewInstancesPersistent: (BOOL)flag
{
	if (automaticPersistentClasses == nil)
		automaticPersistentClasses = [[NSMutableSet alloc] init];

	if (flag)
	{
		[automaticPersistentClasses addObject: self];
	}
	else
	{
		[automaticPersistentClasses removeObject: self];
	}
}

/** <p>Allows to temporarily disable persistency for the receiver. 
    All persistency method calls will not result in any recorded invocations or 
    snapshots.</p>
    <p>A very common usage of this method is to avoid the recording of a large 
    number of messages and only take a snapshot by calling -save once done, 
    then returning to normal with -enablePersistency.</p>
    <p>An object will continue to return YES for -isPersistent, even if 
   -disablePersistency has been called.</p> */
- (void) disablePersistency
{
	if ([self objectContext] == nil)
	{
		//ETLog(@"WARNING: %@ misses an object context to disable persistency", self);
	}

	// NOTE: Another way would be: [_objectContext unregisterObject: self];
	// By doing, we wouldn't need to check explictly for _isPersistencyEnabled 
	// in RECORD macro and the object context would discard the invocation 
	// because the receiver isn't registered. However testing whether the 
	// persistency is enabled makes sense, because invocations are created 
	// only if needed.
	// _isPersistencyEnabled would be easy to replace by -isPersistencyEnabled 
	// { return [[_objectContext registeredObjects] containsObject: self] }
	_isPersistencyEnabled = NO;
}

/** <p>Allows to restore persistency for the receiver, if it is presently
    disabled. See -disablePersistency.</p> */
- (void) enablePersistency
{
	if ([self objectContext] == nil)
	{
		//ETLog(@"WARNING: %@ misses an object context to enable persistency", self);
	}
	
	// NOTE: Another way would be: [_objectContext registerObject: self];
	_isPersistencyEnabled = YES;
}

/** <p>Returns whether the receiver has been turned into a persistent object.</p>
    <p>Once an object has become persistent, it will remain so until it got 
    fully destroyed:</p>
    <list>
    <item>deallocated in memory</item>
    <item>deleted on-disk</item></list> */
- (BOOL) isPersistent
{
	return ([self objectVersion] > -1);
}

/** <p>See COManagedObject protocol.</p> */
- (COObjectContext *) objectContext
{
	return _objectContext;
}

/* Framework private method used only by COObjectContext on insertion/removal of 
   objects. */
- (void) setObjectContext: (COObjectContext *)ctxt
{
	/* The object context is our owner and retains us. */
	_objectContext = ctxt;
}

/* Framework private method used on serialization and deserialization, either 
   delta or snapshot. */
- (void) _setObjectVersion: (int)version
{
	ETDebugLog(@"Setting version from %d to %d of %@", _objectVersion, version, self);
	_objectVersion = version;
}

/** <p>See COManagedObject protocol.</p>
    <p>The last object version which can be known by calling -lastObjectVersion.</p> */
- (int) objectVersion
{
	return _objectVersion;
}

/** <p>API only used for replacing an existing object by a past temporal in the 
    managed object graph. See COObjectContext.</p>
    <p><strong>WARNING: May be removed later.</strong></p> */
- (int) lastObjectVersion
{
	ETDebugLog(@"Requested last object version, found %d in %@", 
		[_objectContext lastVersionOfObject: self], _objectContext);

	return [_objectContext lastVersionOfObject: self];
	// NOTE: An implementation variant that may prove be quicker would be...
	// return [[COObjectServer objectForUUID: [self UUID]] objectVersion]
	//
	// All managed objects cached in the object server have always 
	// -objectVersion equal to -lastObjectVersion, only temporal instances 
	// break this rule, but temporal instances are never referenced by the 
	// object server. If they are merged, then their object version is 
	// updated to match the one of the object they replace. At this point, 
	// they will be cached in the object server, but not qualify as temporal
	// instances anymore.
}

/** <p>Saves the receiver by asking the object context to make a new snapshot.</p>
    <p>If the save succeeds, returns YES. If the save fails, NO is returned and 
    the object version isn't touched.</p> */
- (BOOL) save
{
	int prevVersion = [self objectVersion];
	[[self objectContext] snapshotObject: self];
	return ([self objectVersion] > prevVersion);
}

/* Identity */

/** <p>See COManagedObject protocol.</p> */
- (ETUUID *) UUID
{
	return AUTORELEASE([[ETUUID alloc] initWithString: [self valueForProperty: kCOUIDProperty]]);
}

/** <p>See COManagedObject protocol.</p> */
- (NSUInteger) hash
{
	return [[self valueForProperty: kCOUIDProperty] hash];
}

/**  <p>See COManagedObject protocol.</p> */
- (BOOL) isEqual: (id)other
{
	if (other == nil || [other isKindOfClass: [self class]] == NO)
		return NO;

	BOOL hasEqualUUID = [[self valueForProperty: kCOUIDProperty] isEqual: [other valueForProperty: kCOUIDProperty]];
	BOOL hasEqualObjectVersion = ([self objectVersion] == [other objectVersion]);

	return hasEqualUUID && hasEqualObjectVersion;
}

/** <p>See COOManagedObject protocol.</p> */
- (BOOL) isTemporalInstance: (id)other
{
	if (other == nil || [other isKindOfClass: [self class]] == NO)
		return NO;

	BOOL hasEqualUUID = [[self valueForProperty: kCOUIDProperty] isEqual: [other valueForProperty: kCOUIDProperty]];
	BOOL hasDifferentObjectVersion = ([self objectVersion] != [other objectVersion]);

	return hasEqualUUID && hasDifferentObjectVersion;
}

/* Query */

/** <p>See COObject protocol.</p> */
- (BOOL) matchesPredicate: (NSPredicate *)aPredicate
{
	BOOL result = NO;
	if ([aPredicate isKindOfClass: [NSCompoundPredicate class]])
	{
		NSCompoundPredicate *cp = (NSCompoundPredicate *)aPredicate;
		NSArray *subs = [cp subpredicates];
		int i, count = [subs count];
		switch ([cp compoundPredicateType])
		{
			case NSNotPredicateType:
				result = ![self matchesPredicate: [subs objectAtIndex: 0]];
				break;
			case NSAndPredicateType:
				result = YES;
				for (i = 0; i < count; i++)
				{
					result = result && [self matchesPredicate: [subs objectAtIndex: i]];
				}
				break;
			case NSOrPredicateType:
				result = NO;
				for (i = 0; i < count; i++)
				{
					result = result || [self matchesPredicate: [subs objectAtIndex: i]];
				}
				break;
			default: 
				ETLog(@"Error: Unknown compound predicate type");
		}
	}
	else if ([aPredicate isKindOfClass: [NSComparisonPredicate class]])
	{
		NSComparisonPredicate *cp = (NSComparisonPredicate *)aPredicate;
		id lv = [[cp leftExpression] expressionValueWithObject: self context: nil];
		id rv = [[cp rightExpression] expressionValueWithObject: self context: nil];
		NSArray *array = nil;
		if ([lv isKindOfClass: [NSArray class]] == NO)
		{
			array = [NSArray arrayWithObjects: lv, nil];
		}
		else
		{
			array = (NSArray *) lv;
		}
		NSEnumerator *e = [array objectEnumerator];
		id v = nil;
		while ((v = [e nextObject]))
		{
			switch ([cp predicateOperatorType])
			{
				case NSLessThanPredicateOperatorType:
					return ([v compare: rv] == NSOrderedAscending);
				case NSLessThanOrEqualToPredicateOperatorType:
					return ([v compare: rv] != NSOrderedDescending);
				case NSGreaterThanPredicateOperatorType:
				return ([v compare: rv] == NSOrderedDescending);
				case NSGreaterThanOrEqualToPredicateOperatorType:
					return ([v compare: rv] != NSOrderedAscending);
				case NSEqualToPredicateOperatorType:
					return [v isEqual: rv];
				case NSNotEqualToPredicateOperatorType:
					return ![v isEqual: rv];
				case NSMatchesPredicateOperatorType:
					{
						// FIXME: regular expression
						return NO;
					}
				case NSLikePredicateOperatorType:
					{
						// FIXME: simple regular expression
						return NO;
					}
				case NSBeginsWithPredicateOperatorType:
					return [[v description] hasPrefix: [rv description]];
				case NSEndsWithPredicateOperatorType:
					return [[v description] hasSuffix: [rv description]];
				case NSInPredicateOperatorType:
					// NOTE: it is the reverse CONTAINS
					return ([[rv description] rangeOfString: [v description]].location != NSNotFound);;
				case NSCustomSelectorPredicateOperatorType:
					{
						// FIXME: use NSInvocation
						return NO;
					}
				default:
					ETLog(@"Error: Unknown predicate operator");
			}
		}
	}
	return result;
}

/* Serialization (EtoileSerialize) */

/** <p>If you override this method, you must call superclass implemention before 
    your own code.</p> */
- (BOOL) serialize: (char *)aVariable using: (ETSerializer *)aSerializer
{
	//ETDebugLog(@"Try serialize %s in %@", aVariable, self);
	if (strcmp(aVariable, "_nc") == 0
	 || strcmp(aVariable, "_objectContext") == 0
	 || strcmp(aVariable, "_objectVersion") == 0
	 || strcmp(aVariable, "_isPersistencyEnabled") == 0)
	{
		return YES; /* Should not be automatically serialized (manual) */
	}
	if (strcmp(aVariable, "_properties") == 0)
	{
		/* We discard the parents array which is transient and may have become 
		   invalid. For example, a parent group might have been deleted. 
		   The most important issue is that we are unable to treat a 
		   relationship change, that alter two different objects as an atomic 
		   unit of change. This would imply to serialize/deserialize two 
		   invocations, in a single transaction that binds the two new object 
		   versions (in the history of each object).
		   Moreover...
		   Deserializing all child objects to correct their parent relationships, 
		   would be really slow, if the group has several hundreds of children 
		   or more. Add, remove operations would also be slow on a huge number 
		   of objects, because this would involve to deserialize/reserialize 
		   each moved object.
		   We could alternatively discard kCOParentsProperty on deserialization 
		   rather than at serialization time. */
		// TODO: Benchmark persistentProperties creation cost. If this is too 
		// slow, cache, optimize or eventually turn kCOParentsProperty into 
		// a transient ivar... or some other clever trick.
		// peristentProperties is also fragile currently because it relies 
		// on the assumption that no other autorelease pools is created within 
		// the serialization triggered by -[ETSerializer serializeObject:withName:]
		NSMutableDictionary *persistentProperties = 
			[[NSMutableDictionary alloc] initWithDictionary: _properties];
		[persistentProperties setObject: [NSMutableArray array] forKey: kCOParentsProperty];
		[aSerializer storeObjectFromAddress: &persistentProperties withName: "_properties"];
		AUTORELEASE(persistentProperties);
		return YES;
	}

	return NO; /* Serializer handles the ivar */
}

/** <p>If you override this method, you must call superclass implemention before 
    your own code.</p> */
- (void *) deserialize: (char *)aVariable 
           fromPointer: (void *)aBlob 
               version: (int)aVersion
{
	//ETDebugLog(@"Try deserialize %s into %@ (class version %d)", aVariable, aVersion, self);

	return AUTO_DESERIALIZE;
}

// TODO: If we can get the deserializer in parameter, the need to call 
// -_setObjectVersion: in delta or snapshot deserialization methods might 
// eventually be eliminated.
/** <p>If you override this method, you must call superclass implemention before 
    your own code.</p> */
- (void) finishedDeserializing
{
	ETDebugLog(@"Finished deserializing of %@", self);

	_nc = [NSNotificationCenter defaultCenter];
	_objectContext = nil;
	 /* Reset a default version to be immediately overriden by
	   _setObjectVersion: called back by the context. 
	   This is also useful to ensure consistency if a non-persistent object is 
	   serialized/deserialized without COObjectContext facility. 
	   See TestSerializer.m */
	_objectVersion = -1;
	/* If we deserialize an object, it is persistent :-) */
	_isPersistencyEnabled = YES;
	// TODO: _properties is an invalid dictionary when this method is called.
	// The next line results in a crash in EtoileSerialize. May be we should 
	// improve EtoileSerialize to push back -finishedDeserializing to a point 
	// where all objects are fully deserialized...
	// This line should be removed later, we now handle kCOParentsProperty as 
	// transient in -serialize:using.
	//[_properties setObject: [NSMutableArray array] forKey: kCOParentsProperty];
}

/* Copying */

- (id) copyWithZone: (NSZone *) zone
{
	COObject *clone = [[[self class] allocWithZone: zone] init];
	clone->_properties = [_properties mutableCopyWithZone: zone];
	return clone;
}

/* KVC */

/** <p>Returns the value identified by key.</p>
    <p>The returned value is identical to -valueForProperty:, except that it 
    returns the text content if you pass qCOTextContent as key. This addition 
    is used by -matchesPredicate:.</p>
    <p>For now, this method returns nil for an undefined key and doesn't raise an 
    exception by calling -valueForUndefinedKey:, however this is subject to 
    change.</p> */
- (id) valueForKey: (NSString *) key
{
	/* Intercept query property */
	if ([key isEqualToString: qCOTextContent])
	{
		return [self _textContent];
	}
	return [self valueForProperty: key];
}

/** <p>Returns the value for the given key path. See -valueForKey:.</p> */
- (id) valueForKeyPath: (NSString *) key
{
	/* Intercept query property */
	if ([key isEqualToString: qCOTextContent])
	{
		return [self _textContent];
	}

	NSArray *keys = [key componentsSeparatedByString: @"."];
	if ([keys count])
	{
		id value = [self valueForProperty: [keys objectAtIndex: 0]];
		if ([value isKindOfClass: [COMultiValue class]])
		{
			COMultiValue *mv = (COMultiValue *) value;
			int i, count = [mv count];
			NSMutableArray *array = [[NSMutableArray alloc] init];
			if ([keys count] > 1)
			{
				/* Find the label first */
				NSString *label = [keys objectAtIndex: 1];
				for (i = 0; i < count; i++)
				{
					if ([[mv labelAtIndex: i] isEqualToString: label])
					{
						[array addObject: [mv valueAtIndex: i]];
					}
				}
			}
			else
			{
				/* Search all labels */
				for (i = 0; i < count; i++)
				{
					[array addObject: [mv valueAtIndex: i]];
				}
			}
			return AUTORELEASE(array);
		}
	}
	return [self valueForKey: key];
}

/* Return all text for search */
- (NSString *) _textContent
{
	NSMutableString *text = [[NSMutableString alloc] init];
	NSEnumerator *e = [[[self class] properties] objectEnumerator];
	NSString *property = nil;
	while ((property = [e nextObject]))
	{
		COPropertyType type = [[self class] typeOfProperty: property];
		switch(type)
		{
			case kCOStringProperty:
			case kCOArrayProperty:
			case kCODictionaryProperty:
				[text appendFormat: @"%@ ", [[self valueForProperty: property] description]];
				break;
			case kCOMultiStringProperty:
			case kCOMultiArrayProperty:
			case kCOMultiDictionaryProperty:
				{
					COMultiValue *mv = [self valueForProperty: property];
					int i, count = [mv count];
					for (i = 0; i < count; i++)
					{
						[text appendFormat: @"%@ ", [[mv valueAtIndex: i] description]];
					}
				}
				break;
			default:
				continue;
		}
	}
	return AUTORELEASE(text);
}

/* Deprecated */

- (NSString *) uniqueID
{
	return [self valueForProperty: kCOUIDProperty];
}

@end
