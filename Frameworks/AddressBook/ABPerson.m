/**
	Copyright (C) 2012 Quentin Mathé

	Author:  Quentin Mathe <quentin.mathe@gmail.com>
	Date:  April 2012
	License:  Modified BSD (see COPYING)
 */

#import "ABPerson.h"
#import "ABConstants.h"

@implementation ABPerson

+ (NSInteger)addPropertiesAndTypes: (NSDictionary *)typesByProperty 
               toEntityDescription: (ETEntityDescription *)anEntityDesc
{
	NSInteger nbOfValidProperties = 0;	

	for (NSString *property in typesByProperty)
	{
		NSString *type = [typesByProperty objectForKey: property];
		ETPropertyDescription *desc = [ETPropertyDescription descriptionWithName: property type: (id)type];
		[desc setPersistent: YES];

		[anEntityDesc addPropertyDescription: desc];
		nbOfValidProperties++;
	}

	return nbOfValidProperties;
}

+ (ETEntityDescription *)newEntityDescription
{
	ETEntityDescription *person = [self newBasicEntityDescription];

	// For subclasses that don't override -newEntityDescription, we must not add the 
	// property descriptions that we will inherit through the parent
	if ([[person name] isEqual: [ABPerson className]] == NO) 
		return person;

	ETPropertyDescription *uniqueId = [ETPropertyDescription descriptionWithName: kABUIDProperty type: (id)@"NSString"];
	/* uniqueId is derived from COObject.UUID */
	[uniqueId setDerived: YES];
	ETPropertyDescription *parentGroups = [ETPropertyDescription descriptionWithName: @"parentGroups" type: (id)@"NSArray"];
	/* parentGroups is an alias on COObject.parentCollections */
	[parentGroups setDerived: YES]; 
	[parentGroups setMultivalued: YES];
	[parentGroups setOrdered: YES];

	[person setPropertyDescriptions: A(uniqueId, parentGroups)];
	return person;
}

- (id)initWithAddressBook: (ABAddressBook *)aBook
{
	return self;
}

- (id)initWithVCardRepresentation: (NSData *)vCardData
{
	return self;
}

- (id)init
{
	return self;
}

- (NSData *)vCardRepresentation
{
	return nil;
}

- (BOOL)setImageData: (NSData *)data
{
	return [self setValue: data forProperty: @"imageData"];
}

- (NSData *)imageData
{
	return [self valueForProperty: @"imageData"];
}

- (NSInteger)beginLoadingImageDataForClient: (id <ABImageClient>)aClient
{
	/* For now, we simulate asynchronous loading */
	[self performSelector: @selector(finishLoadingImageDataForClient:) 
                   withObject: aClient
	           afterDelay: 0];
	return ++loadRequestNumber;
}

- (void) finishLoadingImageDataForClient: (id <ABImageClient>)aClient
{
	[aClient consumeImageData: [self imageData] forTag: loadRequestNumber];
}

+ (void)cancelLoadingImageDataForTag: (NSInteger)aTag
{

}

@end

