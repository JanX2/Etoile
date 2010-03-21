/*
	Copyright (C) 2010 Quentin Mathe

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  March 2010
	License:  Modified BSD (see COPYING)
 */

#import "ETModelDescriptionRepository.h"
#import "ETClassMirror.h"
#import "ETCollection.h"
#import "ETCollection+HOM.h"
#import "ETEntityDescription.h"
#import "ETPackageDescription.h"
#import "ETPropertyDescription.h"
#import "ETReflection.h"
#import "NSObject+Model.h"
#import "Macros.h"
#import "EtoileCompatibility.h"


@implementation ETModelDescriptionRepository

+ (ETEntityDescription *) newEntityDescription
{
	ETEntityDescription *selfDesc = [[ETEntityDescription alloc] initWithName: [self className]];

	// TODO: Add property descriptions...

	return selfDesc;
}

- (void) addUnresolvedEntityDescriptionForClass: (Class)aClass
{
	ETEntityDescription *entityDesc = [aClass newEntityDescription];
	[self addUnresolvedDescription: entityDesc];
	[self setEntityDescription: entityDesc forClass: aClass];
}

- (void) collectEntityDescriptionsFromClass: (Class)aClass resolveNow: (BOOL)resolve
{
	[self addUnresolvedEntityDescriptionForClass: aClass];
	FOREACH([[ETReflection reflectClass: aClass] allSubclassMirrors], mirror, ETClassMirror *)
	{
		[self addUnresolvedEntityDescriptionForClass: [mirror representedClass]];
	}
	if (resolve)
	{
		[self resolveNamedObjectReferences];
	}
}

static ETModelDescriptionRepository *mainRepo = nil;

+ (id) mainRepository
{
	if (nil == mainRepo)
	{
		mainRepo = [[self alloc] init];
		[mainRepo collectEntityDescriptionsFromClass: [NSObject class] resolveNow: YES];
	}
	return mainRepo;
}

static NSString *anonymousPackageName = @"Anonymous";

- (id) init
{
	SUPERINIT
	_unresolvedDescriptions = [[NSMutableSet alloc] init];
	_descriptionsByName = [[NSMutableDictionary alloc] init];
	_entityDescriptionsByClass = [[NSMapTable alloc] init];
	[self addDescription: [ETPackageDescription descriptionWithName: anonymousPackageName]];
	return self;
}

- (void) dealloc
{
	DESTROY(_unresolvedDescriptions);
	DESTROY(_descriptionsByName);
	DESTROY(_entityDescriptionsByClass);
	[super dealloc];
}

- (ETPackageDescription *) anonymousPackageDescription
{
	return [self descriptionForName: anonymousPackageName];
}

- (void) addDescriptions: (NSArray *)descriptions
{
	FOREACH(descriptions, desc, ETModelElementDescription *)
	{
		[self addDescription: desc];
	}
}

- (void) addDescription: (ETModelElementDescription *)aDescription
{
	if ([aDescription isEntityDescription] && [aDescription owner] == nil)
	{
		[[self anonymousPackageDescription] addEntityDescription: (ETEntityDescription *)aDescription];
	}
	[_descriptionsByName setObject: aDescription forKey: [aDescription fullName]];
}

- (void) removeDescription: (ETModelElementDescription *)aDescription
{
	[_descriptionsByName removeObjectForKey: [aDescription fullName]];
	ETAssert([[_descriptionsByName allKeysForObject: aDescription] isEmpty]);
}

- (NSArray *) packageDescriptions
{
	NSMutableArray *descriptions = [NSMutableArray arrayWithArray: [_descriptionsByName allValues]];
	[[descriptions filter] isPackageDescription];
	return descriptions;
}

- (NSArray *) entityDescriptions
{
	NSMutableArray *descriptions = [NSMutableArray arrayWithArray: [_descriptionsByName allValues]];
	[[descriptions filter] isEntityDescription];
	return descriptions;
}

- (NSArray *) propertyDescriptions
{
	NSMutableArray *descriptions = [NSMutableArray arrayWithArray: [_descriptionsByName allValues]];
	[[descriptions filter] isPropertyDescription];
	return descriptions;
}

- (NSArray *) allDescriptions
{
	return AUTORELEASE([[_descriptionsByName allValues] copy]);
}

- (id) descriptionForName: (NSString *)aFullName
{
	return [_descriptionsByName objectForKey: aFullName];
}

/* Binding Descriptions to Class Instances and Prototypes */

- (ETEntityDescription *) entityDescriptionForClass: (Class)aClass
{
	return [_entityDescriptionsByClass objectForKey: aClass];
}

- (void) setEntityDescription: (ETEntityDescription *)anEntityDescription
                     forClass: (Class)aClass
{
	if ([_descriptionsByName objectForKey: [anEntityDescription fullName]] == nil
	 && [_unresolvedDescriptions containsObject: anEntityDescription] == NO)
	{
		[NSException raise: NSInvalidArgumentException 
		            format: @"The entity description must have been previously "
					         "added to the repository"];
	}
	[_entityDescriptionsByClass setObject: anEntityDescription forKey: aClass];
}

- (void) addUnresolvedDescription: (ETModelElementDescription *)aDescription
{
	[_unresolvedDescriptions addObject: aDescription];
}

/* 'isPackageRef' prevents to wrongly look up a package as an entity (with the 
same name). */
- (void) resolveProperty: (NSString *)aProperty
          forDescription: (ETModelElementDescription *)desc
            isPackageRef: (BOOL)isPackageRef
{
	id value = [desc valueForKey: aProperty];

	if ([value isString] == NO) return;

	id realValue = [self descriptionForName: (NSString *)value];
	BOOL lookUpInAnonymousPackage = (nil == realValue && NO == isPackageRef);

	if (lookUpInAnonymousPackage)
	{
		value = [anonymousPackageName stringByAppendingFormat: @".%@", value];
		realValue = [self descriptionForName: (NSString *)value];
	}

	[desc setValue: realValue forKey: aProperty];
}

- (NSSet *) resolveAndAddEntityDescriptions: (NSSet *)unresolvedEntityDescs
{
	NSMutableSet *propertyDescs = [NSMutableSet set];

	FOREACH(unresolvedEntityDescs, desc, ETEntityDescription *)
	{
		[self resolveProperty: @"owner" forDescription: desc isPackageRef: YES];
		[propertyDescs addObjectsFromArray: [desc propertyDescriptions]];
		[self addDescription: desc];
	}

	FOREACH(unresolvedEntityDescs, desc2, ETEntityDescription *)
	{
		[self resolveProperty: @"parent" forDescription: desc2 isPackageRef: NO];
	}

	return propertyDescs;
}

- (void) resolveAndAddPropertyDescriptions:(NSMutableSet *)unresolvedPropertyDescs
{
	FOREACH(unresolvedPropertyDescs, desc, ETPropertyDescription *)
	{
		[self resolveProperty: @"owner" forDescription: desc isPackageRef: NO];
		/* A package is set when the property is an entity extension */
		[self resolveProperty: @"package" forDescription: desc isPackageRef: YES];
		 /* For property extension */
		[self addDescription: desc];
	}

	FOREACH(unresolvedPropertyDescs, desc2, ETPropertyDescription *)
	{
		[self resolveProperty: @"opposite" forDescription: desc2 isPackageRef: NO];
	}
}

- (void) resolveNamedObjectReferences
{
	NSMutableSet *unresolvedPackageDescs = [NSMutableSet setWithSet: _unresolvedDescriptions];
	NSMutableSet *unresolvedEntityDescs = [NSMutableSet setWithSet: _unresolvedDescriptions];
	NSMutableSet *unresolvedPropertyDescs = [NSMutableSet setWithSet: _unresolvedDescriptions];

	[[unresolvedPackageDescs filter] isPackageDescription];
	[[unresolvedEntityDescs filter] isEntityDescription];
	[[unresolvedPropertyDescs filter] isPropertyDescription];

	[self addDescriptions: [unresolvedPackageDescs allObjects]];
	NSSet *collectedPropertyDescs = 
		[self resolveAndAddEntityDescriptions: unresolvedEntityDescs];
	[unresolvedPropertyDescs unionSet: collectedPropertyDescs];
	[self resolveAndAddPropertyDescriptions: unresolvedPropertyDescs];
}

- (void) checkConstraints: (NSMutableArray *)warnings
{

}

@end
