#include <stdlib.h>
#include <objc/objc.h>
#include <objc/objc-api.h>
#include <objc/Object.h>
#import <UnitKit/UnitKit.h>
#import "ETSerializer.h"
#import "ETDeserializer.h"
#import "ETDeserializerBackendBinary.h"
#import "ETSerializerBackendExample.h"
#import "ETSerializerBackendXML.h"
#import "ETSerializerBackendBinary.h"
#import "ETObjectStore.h"
#import "ESProxy.h"

#define TEST_COREOBJECT
//#define VISUAL_TEST

/**
 * Example class that the tests try to serialize.  Has lots of instance
 * variables of different types.
 */
@interface TestClass : NSObject {
@public
	int anInteger;
	BOOL aBool;
	float aFloat;
	double aDouble;
	struct
	{
		BOOL boolInStruct;
		unsigned long long int intInStruct;
		float floatArrayInStruct[10];
		struct 
		{
			int foo;
			int bar;
		} thisWontWork[3];
	} aStruct;
	struct TestStruct
	{
		int len;
		void * data;
	} bar;
	id anObject;
	int anArray[3];
	NSString * aString;
	NSString * anotherReferenceToTheSameString;
	NSNumber * aNumber;
	NSNumber * theSameNumber;
	NSData * aData;
	int * aPointer;
}
@end
/**
 * Example custom structure serializer.  Stores the TestStruct structure.
 */
parsed_type_size_t TestStructSerializer(char* aName, void* aStruct, id <ETSerializerBackend> aBackend)
{
	struct TestStruct * s = (struct TestStruct*)aStruct;
	[aBackend beginStruct:"TestStruct" withName:aName];
	[aBackend storeInt:s->len withName:"len"];
	[aBackend storeData:s->data ofSize:s->len withName:"data"];
	[aBackend endStruct];
	parsed_type_size_t retVal;
	retVal.size = sizeof(struct TestStruct);
	retVal.offset = strlen(@encode(struct TestStruct));
	return retVal;
}
#define CASE(x) if(strcmp(varName, #x) == 0)
/**
 * Corresponding custom deserializer function for struct TestStruct.
 */
void * TestStructDeserializer(char* varName,
	void * aBlob,
	void * aLocation)
{
	struct TestStruct * s = (struct TestStruct*)aLocation;
	CASE(len)
	{
		s->len = *(int*)aBlob;
		return aLocation;
	}
	CASE(data)
	{
		s->data = malloc(s->len);
		memcpy(s->data, aBlob, s->len);
		//Return the location of the end of the struct once 
		//we have loaded it
		return aLocation + sizeof(struct TestStruct);
	}
	return aLocation;
}
@implementation TestClass
/**
 * Register the custom [de]serializer function.
 */
+ (void) initialize
{
	[super initialize];
	[ETSerializer registerSerializer:TestStructSerializer forStruct:"TestStruct"];
	[ETDeserializer registerDeserializer:TestStructDeserializer forStructNamed:"TestStruct"];
}
/**
 * Set some values for instance variables that we will test later.
 */
- (id) init
{
	self = [super init];
	if(self==nil)
	{
		return nil;
	}
	anInteger = 10;
	aBool = YES;
	aFloat = 12.345f;
	aDouble = 67.890;
	aStruct.intInStruct = 12;
	aStruct.boolInStruct = YES;
	bar.len = 12;
	bar.data = "123456789012";
	aData = [[NSData dataWithBytes:"this is a bit of data" length:22] retain];
	aStruct.floatArrayInStruct[0] = -0.0f;
	aStruct.floatArrayInStruct[1] = -0.1f;
	aStruct.floatArrayInStruct[2] = -0.2f;
	aStruct.floatArrayInStruct[3] = -0.3f;
	aStruct.floatArrayInStruct[4] = -0.4f;
	aStruct.thisWontWork[0].foo = 23;
	aStruct.thisWontWork[1].foo = 24;
	aStruct.thisWontWork[2].foo = 25;
	//Check we don't break on non-OpenStep objects.
	anObject = [Object new];
	aString = [NSMutableString stringWithString:@"Some text"];
	anotherReferenceToTheSameString = aString;
	anArray[0] = 0;
	anArray[1] = 1;
	anArray[2] = 2;
	aNumber = [[NSNumber numberWithInt:42] retain];
	theSameNumber = [aNumber retain];
	aPointer = malloc(5*sizeof(int));
	for(unsigned int i=0; i<5 ; i++)
	{
		aPointer[i] = i;
	}
	return self;
}
/**
 * Custom serializer method for storing a pointer.
 */
- (BOOL) serialize:(char*)aVariable using:(ETSerializer*)aSerializer
{
	if(strcmp(aVariable, "aPointer") == 0)
	{
		[[aSerializer backend] storeData:aPointer ofSize:5 withName:aVariable];
		return YES;
	}
	return NO;
}
/**
 * Test that the class was correctly re-loaded after serialization.
 */
- (void) methodTest
{
	//Method correctly entered
	UKPass();
	//Integer 
	UKIntsEqual(10, anInteger);
	//NSString
	UKStringsEqual(@"Some text", aString);
	//Float
	UKFloatsEqual(12.345f, aFloat, 0.01);
	//Double
	UKFloatsEqual(67.890f, (float)aDouble, 0.01);
	UKIntsEqual(25, aStruct.thisWontWork[2].foo);
	UKFloatsEqual(-0.4f, aStruct.floatArrayInStruct[4], 0.01);

	UKIntsEqual(0, anArray[0]);
	UKIntsEqual(1, anArray[1]);
	UKIntsEqual(2, anArray[2]);
	//NSData
	UKIntsEqual(22, [aData length]);
	UKTrue([aData bytes] != nil && 
			(strncmp("this is a bit of data", [aData bytes], 22) == 0));
	//Int in a structure
	UKIntsEqual(12, aStruct.intInStruct);
	//Custom serializer for structure
	UKTrue(strncmp("123456789012", bar.data, 12) == 0);
	//BOOL
	UKIntsEqual((int)YES, (int)aStruct.boolInStruct);
	//Retain count
	UKIntsEqual(2, [aNumber retainCount]);
}
@end

/**
 * Attempt to serialize an instance of the test class with the specified back
 * end.
 */
void testWithBackend(Class backend, NSURL * anURL)
{
	NSAutoreleasePool * pool = [NSAutoreleasePool new];
	id serializer = [ETSerializer serializerWithBackend:backend forURL:anURL];
	id foo = [TestClass new];
	[serializer serializeObject:foo withName:@"foo"];
	[pool release];
}
id testRoundTrip(NSString * tempfile, id object)
{
	NSAutoreleasePool * pool = [NSAutoreleasePool new];
	id serializer = [ETSerializer serializerWithBackend:[ETSerializerBackendBinary class]
												 forURL:[NSURL fileURLWithPath:tempfile]];
	[serializer serializeObject:object withName:@"test"];
	id deserializer = [serializer deserializer];
	[pool release];
	[deserializer setVersion:0];
	return [deserializer restoreObjectGraph];
}

@interface ETSerializerTest : NSObject <UKTest>
@end
@implementation ETSerializerTest
#ifdef VISUAL_TEST
/**
 * If VISUAL_TEST is defined, use the example back end to serialize the test
 * class to the standard output for visual inspection.
 */
- (void) testHuman
{
	testWithBackend([ETSerializerBackendExample class], nil);
	testWithBackend([ETSerializerBackendXML class], nil);
}
#endif
- (void) testDictionary
{
	NSDictionary * dict = [NSDictionary dictionaryWithObjectsAndKeys:
		@"val1", @"key1",
		@"val2", @"key2",
		@"val3", @"key3",
		@"val4", @"key4",
		@"val5", @"key5",
		nil];
	NSDictionary * newdict = testRoundTrip(@"dictionarytestfile", dict);
	UKTrue([dict isEqual:newdict]);
	NSMutableDictionary * mutable = [newdict mutableCopy];
	UKTrue([dict isEqual:testRoundTrip(@"dictionarytestfile", mutable)]);
}
- (void) testSet
{
	NSSet * set =[NSSet setWithObjects:@"foo", @"bar", @"wibble", nil];
	NSSet * newSet = testRoundTrip(@"settestfile", set);
	UKTrue([set isEqual:newSet]);
	NSMutableSet * mutable = [newSet mutableCopy];
	[mutable addObject:[NSNumber numberWithInt:12]];
	[mutable addObject:[NSNumber numberWithInt:26]];
	[mutable addObject:[NSNumber numberWithInt:35]];
	[mutable addObject:[NSNumber numberWithInt:59]];
	[mutable addObject:@"another string"];
	NSMutableSet * mutableCopy = testRoundTrip(@"mutablesettestfile", mutable);
	UKTrue([mutable isEqual:mutableCopy]);
}
- (void) testArray
{
	NSArray * array =[NSArray arrayWithObjects:@"foo", @"bar", @"wibble", nil];
	NSArray * newArray = testRoundTrip(@"arraytestfile", array);
	UKTrue([array isEqual:newArray]);
	NSMutableArray * mutable = [newArray mutableCopy];
	[mutable addObject:[NSNumber numberWithInt:12]];
	[mutable addObject:[NSNumber numberWithInt:26]];
	[mutable addObject:[NSNumber numberWithInt:35]];
	[mutable addObject:[NSNumber numberWithInt:59]];
	[mutable addObject:@"another string"];
	NSMutableArray * mutableCopy = testRoundTrip(@"mutablearraytestfile", mutable);
	UKTrue([mutable isEqual:mutableCopy]);
}

- (void) testURL
{
	NSURL * url = [NSURL URLWithString: @"http://www.etoile-project.org"];
	NSArray * newURL = testRoundTrip(@"urltestfile", url);

	UKObjectsEqual(url, newURL);

	NSURL * relURL = [NSURL URLWithString: @"whatever/.." relativeToURL: url];
	NSURL * newRelURL = testRoundTrip(@"relativeurltestfile", relURL);
	UKObjectsEqual(relURL, newRelURL);
}

/**
 * Serialize an instance of the test class with the binary back end, then try
 * re-loading it and see if any information was lost.
 */
- (void) testBinary
{
	testWithBackend([ETSerializerBackendBinary class], [NSURL fileURLWithPath:@"testfile"]);
	id deback = [ETDeserializerBackendBinary new];
	id store = [[ETSerialObjectBundle alloc] initWithPath:@"testfile"];
	[deback deserializeFromStore:store];
	id deserializer = [ETDeserializer deserializerWithBackend:deback];
	[deserializer setBranch:@"root"];
	[deserializer setVersion:0];
	TestClass * bar = [deserializer restoreObjectGraph];
	[bar methodTest];
	[store release];
}
// Test for bug reported by Eric Wasylishen
- (void) testEric
{
	id dict = [NSArray arrayWithObjects: [NSArray array], [NSArray array], nil];
	id dict2 = testRoundTrip(@"erictest", dict);
	UKObjectsEqual(dict, dict2);
}
#ifdef TEST_COREOBJECT
/**
 * Test CoreObject replay by sending a message to a class and seeing if we can
 * re-load and re-play that message.
 */
- (void) testCoreObject
{
	NSMutableString * str = [NSMutableString stringWithString:@"A string"];
	NSMutableString * fake = [[ESProxy alloc] initWithObject:str
												  serializer:[ETSerializerBackendBinary class] 
												   forBundle:[NSURL fileURLWithPath:@"cotest.CoreObject"]];
	[fake appendString:@" containing"];
	[fake appendString:@" some character."];
	[(ESProxy*)fake setVersion:2];
	UKStringsEqual(fake, @"A string containing");
}
#endif
@end
