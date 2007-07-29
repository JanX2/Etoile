#include <stdlib.h>
#include <objc/objc.h>
#include <objc/objc-api.h>
#include <objc/Object.h>
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
parsed_type_size_t TestStructSerialiser(char* aName, void* aStruct, id <ETSerialiserBackend> aBackend, BOOL shouldMalloc)
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
	NSLog(@"Method calls work");
	NSLog(@"Integer: 10 = %d", anInteger);
	NSLog(@"String Object: \"Some text\" = \"%@\"", aString, aString);
	NSLog(@"Float: 12.345 = %f",(double)aFloat);
	NSLog(@"Double: 67.890 = %f", aDouble);
	NSLog(@"Array {0,1,2} = {%d,%d,%d}", anArray[0], anArray[1], anArray[2]);
	NSLog(@"Unsigned long long in struct: 12 = %d", aStruct.intInStruct);
	NSLog(@"Struct with custom serialiser: \"123456789012\" = \"%.12s\"", bar.data);
	NSLog(@"BOOL in struct: 1 = %d", (int)aStruct.boolInStruct);
	NSLog(@"Retain count of object %@: 2 = %d", aNumber, [aNumber retainCount]);
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

int main(void)
{
	NSAutoreleasePool * pool = [NSAutoreleasePool new];
	NSLog(@"Testing serialiser with human-readable output");
	testWithBackend([ETSerialiserBackendExample class], nil);
	NSLog(@"Serialising to binary file...");
	testWithBackend([ETSerialiserBackendBinaryFile class], [NSURL fileURLWithPath:@"testfile"]);
	NSLog(@"Deserialising from binary file...");
	id deback = [ETDeserialiserBackendBinaryFile new];
	[deback deserialiseFromURL:[NSURL fileURLWithPath:@"testfile"]];
	id deserialiser = [ETDeserialiser deserialiserWithBackend:deback];
	TestClass * bar = [deserialiser restoreObjectGraph];
	[bar methodTest];
#ifdef TEST_COREOBJECT
	NSMutableString * str = [NSMutableString stringWithString:@"A string"];
	NSMutableString * fake = [[COProxy alloc] initWithObject:str
												  serialiser:[ETSerialiser serialiserWithBackend:[ETSerialiserBackendBinaryFile class] forURL:[NSURL fileURLWithPath:@"cotest"]]];
	[fake appendString:@" containing"];
	[fake appendString:@" some character."];
	NSLog(@"Attempting to re-load an invocation");
	deback = [ETDeserialiserBackendBinaryFile new];
	[deback deserialiseFromURL:[NSURL fileURLWithPath:@"cotest.1"]];
	deserialiser = [ETDeserialiser deserialiserWithBackend:deback];
	NSInvocation * inv = [deserialiser restoreObjectGraph];
	id serialiser = [ETSerialiser serialiserWithBackend:[ETSerialiserBackendExample class] forURL:nil];
	[serialiser serialiseObject:inv withName:"FirstInvocation"];
	NSLog(@"Attempting to re-apply invocation...");
	str = [NSMutableString stringWithString:@"A string"];
	[inv setTarget:str];
	[inv invoke];
	NSLog(@"\"A string containing\" = \"%@\"", str);
#endif
	[pool release];
	return 0;
}
