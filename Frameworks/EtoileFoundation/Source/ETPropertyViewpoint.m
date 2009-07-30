/*
	Copyright (C) 2007 Quentin Mathe
 
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  December 2007
 */

#import "ETPropertyViewpoint.h"
#import "NSObject+Etoile.h"
#import "NSObject+Model.h"
#import "EtoileCompatibility.h"


@implementation ETProperty

/** Returns a new autoreleased property viewpoint that represents the property 
identified by the given name in object. */
+ (id) propertyWithName: (NSString *)key representedObject: (id)object
{
	return AUTORELEASE([[ETProperty alloc] initWithName: key representedObject: object]);
}

/** <init />
Returns and initializes a new property viewpoint that represents the property 
identified by the given name in object. */
- (id) initWithName: (NSString *)key representedObject: (id)object
{
	self = [super init];
	
	if (self != nil)
	{
		ASSIGN(_propertyName, key);
		[self setRepresentedObject: object];
	}
	
	return self;
}

- (void) dealloc
{
	DESTROY(_propertyName);
	DESTROY(_propertyOwner);
	
	[super dealloc];
}

/** Returns the object to which the property belongs to. */
- (id) representedObject
{
	return _propertyOwner;
}

/** Sets the object to which the property belongs to. */
- (void) setRepresentedObject: (id)object
{
	ASSIGN(_propertyOwner, object);
}

/** Returns the name used to declared property in the owner object. */
- (NSString *) name
{
	return _propertyName;
}

/** Returns the UTI type of the property value. */
- (ETUTI *) type
{
	// NOTE: May be necessary to cache this value...
	// or [[self representedObject] typeForKey: [self name]]
	return [[self objectValue] UTI];
}

/** Returns the value of the property. */
- (id) objectValue
{
	return [[self representedObject] valueForProperty: [self name]];
}

/** Sets the value of the property to be the given object value. */
- (void) setObjectValue: (id)objectValue
{
	[[self representedObject] setValue: objectValue forProperty: [self name]];
}

/* Property Value Coding */

- (NSArray *) properties
{
	return [NSArray arrayWithObjects: @"property", @"name", @"value", nil];
}

- (id) valueForProperty: (NSString *)key
{
	id value = nil;
	
	if ([[self properties] containsObject: key])
	{
		if ([key isEqual: @"value"])
		{
			value = [self objectValue];
		}
		else if ([key isEqual: @"property"])
		{
			value = [self name];
		}
		else /* name, type properties */
		{
			value = [self primitiveValueForKey: key];
		}
	}
	
	return value;
}

- (BOOL) setValue: (id)value forProperty: (NSString *)key
{
	BOOL result = NO;
	
	if ([[self properties] containsObject: key])
	{
		// NOTE: name, type are read-only properties
		if ([key isEqual: @"value"])
		{
			[self setObjectValue: value];
			result = YES;
		}
	}
	
	return result;
}

@end

