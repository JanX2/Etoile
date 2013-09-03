#import <UnitKit/UnitKit.h>
#import <Foundation/Foundation.h>
#import <EtoileFoundation/ETModelDescriptionRepository.h>
#import "TestCommon.h"
#import "COObject.h"
#import "COBookmark.h"

@interface COOverridenSetterBookmark : COBookmark
{
	@public
	BOOL setterInvoked;
	BOOL validated;
	BOOL serialized;
	BOOL deserialized;
}

@end

@interface TestObject : EditingContextTestCase <UKTest>
@end

@implementation TestObject

- (void) testKVCForSynthesizedSetterName
{
	COOverridenSetterBookmark *bookmark =
		[[ctx insertNewPersistentRootWithEntityName: @"COOverridenSetterBookmark"] rootObject];
	NSDate *date = [NSDate date];

	[bookmark setValue: date forProperty: @"lastVisitedDate"];

	UKObjectsEqual(date, [bookmark lastVisitedDate]);
	UKTrue(bookmark->setterInvoked);
}

- (void) testValidationForSynthesizedSetterName
{
	COOverridenSetterBookmark *bookmark =
		[[ctx insertNewPersistentRootWithEntityName: @"COOverridenSetterBookmark"] rootObject];
	NSDate *date = [NSDate date];
	NSArray *results = [bookmark validateValue: date forProperty: @"lastVisitedDate"];

	UKTrue([results isEmpty]);
	UKTrue(bookmark->validated);
}

- (void) testSerializationForSynthesizedSetterName
{
	COOverridenSetterBookmark *bookmark =
		[[ctx insertNewPersistentRootWithEntityName: @"COOverridenSetterBookmark"] rootObject];
	[bookmark setLastVisitedDate: [NSDate date]];

	NSString *dateString = [bookmark serializedValueForProperty: @"lastVisitedDate"];

	UKObjectsEqual([[bookmark lastVisitedDate] stringValue], dateString);
	UKTrue(bookmark->serialized);
}

- (void) testDeserializationForSynthesizedSetterName
{
	COOverridenSetterBookmark *bookmark =
		[[ctx insertNewPersistentRootWithEntityName: @"COOverridenSetterBookmark"] rootObject];
	NSDate *date = [NSDate date];

	[bookmark setSerializedValue: date forProperty: @"lastVisitedDate"];
	
	UKObjectsEqual(date, [bookmark lastVisitedDate]);
	UKTrue(bookmark->deserialized);
	UKTrue(bookmark->setterInvoked);
}

@end


@implementation COOverridenSetterBookmark

- (void) setLastVisitedDate: (NSDate *)lastVisitedDate
{
	setterInvoked = YES;
	[super setLastVisitedDate: lastVisitedDate];
}

- (id) validateLastVisitedDate: (id)aValue
{
	validated = YES;
	return [ETValidationResult validResult: aValue];
}

- (id) serializedLastVisitedDate
{
	serialized = YES;
	return [[self lastVisitedDate] stringValue];
}

- (void) setSerializedLastVisitedDate: (id)aValue
{
	deserialized = YES;
	[self setLastVisitedDate: aValue];
}

@end