#include <stdlib.h>
#include <objc/objc.h>
#include <objc/objc-api.h>
#include <objc/Object.h>
#import <UnitKit/UnitKit.h>
#import "ETSerialiser.h"
#import "ETDeserialiser.h"
#import "ETDeserialiserBinaryFile.h"
#import "ETSerialiserBackendExample.h"
#import "ETSerialiserBackendBinaryFile.h"
#import "COProxy.h"

#define TEST_COREOBJECT

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
		/*
		float floatArrayInStruct[10];
		struct 
		{
			int foo;
			int bar;
		} thisWontWork[3];
		*/
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
parsed_type_size_t TestStructSerialiser(char* aName, void* aStruct, id <ETSerialiserBackend> aBackend)
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
void * TestStructDeserialiser(char* varName,
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
+ (void) initialize
{
	[super initialize];
	[ETSerialiser registerSerialiser:TestStructSerialiser forStruct:"TestStruct"];
	[ETDeserialiser registerDeserialiser:TestStructDeserialiser forStructNamed:"TestStruct"];
}
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
	/*
	aStruct.floatArrayInStruct[0] = -0.0f;
	aStruct.floatArrayInStruct[1] = -0.1f;
	aStruct.floatArrayInStruct[2] = -0.2f;
	aStruct.floatArrayInStruct[3] = -0.3f;
	aStruct.floatArrayInStruct[4] = -0.4f;
	*/
	//Check we don't break on non-OpenStep objects.
	anObject = [Object new];
	aString = @"Some text";
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
- (BOOL) serialise:(char*)aVariable using:(id<ETSerialiserBackend>)aBackend
{
	if(strcmp(aVariable, "aPointer") == 0)
	{
		[aBackend storeData:aPointer ofSize:5 withName:aVariable];
		return YES;
	}
	return NO;
}
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
	//Array of ints
	UKIntsEqual(0, anArray[0]);
	UKIntsEqual(1, anArray[1]);
	UKIntsEqual(2, anArray[2]);
	//Int in a structure
	UKIntsEqual(12, aStruct.intInStruct);
	//Custom serialiser for structure
	UKTrue(strncmp("123456789012", bar.data, 12) == 0);
	//BOOL
	UKIntsEqual((int)YES, (int)aStruct.boolInStruct);
	//Retain count
	UKIntsEqual(2, [aNumber retainCount]);
}
@end

void testWithBackend(Class backend, NSURL * anURL)
{
	NSAutoreleasePool * pool = [NSAutoreleasePool new];
	id serialiser = [ETSerialiser serialiserWithBackend:backend forURL:anURL];
	id foo = [TestClass new];
	[serialiser serialiseObject:foo withName:"foo"];
	[serialiser release];
	[pool release];
}

@interface ETSerialiserTest : NSObject <UKTest>
@end
@implementation ETSerialiserTest
#ifdef VISUAL_TEST
- (void) testHuman
{
	testWithBackend([ETSerialiserBackendExample class], nil);
	testWithBackend([ETSerialiserBackendBinaryFile class], [NSURL fileURLWithPath:@"testfile"]);
}
#endif
- (void) testBinary
{
	id deback = [ETDeserialiserBackendBinaryFile new];
	[deback deserialiseFromURL:[NSURL fileURLWithPath:@"testfile"]];
	id deserialiser = [ETDeserialiser deserialiserWithBackend:deback];
	TestClass * bar = [deserialiser restoreObjectGraph];
	[bar methodTest];
}
#ifdef TEST_COREOBJECT
- (void) testCoreObject
{
	NSMutableString * str = [NSMutableString stringWithString:@"A string"];
	NSMutableString * fake = [[COProxy alloc] initWithObject:str
												  serialiser:[ETSerialiser serialiserWithBackend:[ETSerialiserBackendBinaryFile class] forURL:[NSURL fileURLWithPath:@"cotest"]]];
	[fake appendString:@" containing"];
	[fake appendString:@" some character."];
	id deback = [ETDeserialiserBackendBinaryFile new];
	[deback deserialiseFromURL:[NSURL fileURLWithPath:@"cotest.1"]];
	id deserialiser = [ETDeserialiser deserialiserWithBackend:deback];
	NSInvocation * inv = [deserialiser restoreObjectGraph];
#ifdef VISUAL_TEST
	id serialiser = [ETSerialiser serialiserWithBackend:[ETSerialiserBackendExample class] forURL:nil];
	[serialiser serialiseObject:inv withName:"FirstInvocation"];
#endif
	str = [NSMutableString stringWithString:@"A string"];
	[inv setTarget:str];
	[inv invoke];
	UKStringsEqual(@"A string containing", str);
}
#endif
@end
