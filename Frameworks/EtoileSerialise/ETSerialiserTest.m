#include <stdlib.h>
#include <objc/objc.h>
#include <objc/objc-api.h>
#include <objc/Object.h>
#import "ETSerialiser.h"
#import "ETDeserialiser.h"
#import "ETDeserialiserBinaryFile.h"
#import "ETSerialiserBackendExample.h"
#import "ETSerialiserBackendBinaryFile.h"

@interface TestClass : NSObject {
@public
	int anInteger;
	BOOL aBool;
	float aFloat;
	double aDouble;
	/*
	struct
	{
		BOOL boolInStruct;
		float floatArrayInStruct[10];
		unsigned long long int intInStruct;
		struct 
		{
			int foo;
			int bar;
		} thisWontWork[3];
	} aStruct;*/
	id anObject;
	/*
	int anArray[3];
	*/
	NSString * aString;
	NSString * anotherReferenceToTheSameString;
	int * aPointer;
}
@end
@implementation TestClass

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
	/*
	aStruct.intInStruct = 12;
	aStruct.boolInStruct = YES;
	aStruct.floatArrayInStruct[0] = -0.0f;
	aStruct.floatArrayInStruct[1] = -0.1f;
	aStruct.floatArrayInStruct[2] = -0.2f;
	aStruct.floatArrayInStruct[3] = -0.3f;
	aStruct.floatArrayInStruct[4] = -0.4f;
	*/
	anObject = [Object new];
	aString = @"Some text";
	anotherReferenceToTheSameString = aString;
	/*
	anArray[0] = 0;
	anArray[1] = 1;
	anArray[2] = 2;
	*/
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
	NSLog(@"Retain count of object: 2 = %d", [aString retainCount]);
}
@end

int main(void)
{
	[NSAutoreleasePool new];
	id foo = [TestClass new];
	//id backend = [ETSerialiserBackendExample new];
	id backend = [ETSerialiserBackendBinaryFile new];
	[backend setFile:"testfile"];
	id serialiser = [ETSerialiser serialiserWithBackend:backend];
	printf("Object serialised with handle %lld\n",[serialiser serialiseObject:foo withName:"foo"]);
	[backend release];
	NSLog(@"Deserialising...");
	id deback = [ETDeserialiserBackendBinaryFile new];
	[deback readDataFromURL:[NSURL fileURLWithPath:@"testfile"]];
	id deserialiser = [ETDeserialiser deserialiserWithBackend:deback];
	TestClass * bar = [deserialiser restoreObjectGraph];
	[bar methodTest];
	return 0;
}
