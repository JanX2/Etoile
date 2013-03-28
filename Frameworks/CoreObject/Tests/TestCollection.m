#import <UnitKit/UnitKit.h>
#import <Foundation/Foundation.h>
#import <EtoileFoundation/ETModelDescriptionRepository.h>
#import "TestCommon.h"
#import "COEditingContext.h"
#import "COBookmark.h"
#import "COObject.h"
#import "COCollection.h"
#import "COContainer.h"
#import "COGroup.h"
#import "COPersistentRoot.h"

@interface TestCollection : TestCommon <UKTest>
@end

@implementation TestCollection

- (void)testBookmarkLibrary
{
	COLibrary *library = [ctx bookmarkLibrary];
	ETEntityDescription *entity = [library entityDescription];

	UKObjectsEqual([COLibrary class], [library class]);
	UKStringsEqual(@"COBookmarkLibrary", [entity name]);
	UKStringsEqual(@"COLibrary", [[entity parent] name]);

	UKStringsEqual(@"COBookmark", [[[entity propertyDescriptionForName: @"contents"] type] name]);
	UKObjectsEqual([ETUTI typeWithClass: [COBookmark class]], [library objectType]);

	UKTrue([library isOrdered]);
}
								  
- (void)testNoteLibrary
{
	COLibrary *library = [ctx noteLibrary];
	ETEntityDescription *entity = [library entityDescription];

	UKObjectsEqual([COLibrary class], [library class]);
	UKStringsEqual(@"CONoteLibrary", [entity name]);
	UKStringsEqual(@"COLibrary", [[entity parent] name]);

	UKStringsEqual(@"COContainer", [[[entity propertyDescriptionForName: @"contents"] type] name]);
	UKObjectsEqual([ETUTI typeWithClass: [COContainer class]], [library objectType]);

	UKTrue([library isOrdered]);
}

@end