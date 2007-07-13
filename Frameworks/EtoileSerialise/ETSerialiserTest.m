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
	id anObject;
	int anArray[3];
	NSString * aString;
	NSString * anotherReferenceToTheSameString;
	NSNumber * aNumber;
	NSNumber * theSameNumber;
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
	aStruct.intInStruct = 12;
	aStruct.boolInStruct = YES;
	/*
	aStruct.floatArrayInStruct[0] = -0.0f;
	aStruct.floatArrayInStruct[1] = -0.1f;
	aStruct.floatArrayInStruct[2] = -0.2f;
	aStruct.floatArrayInStruct[3] = -0.3f;
	aStruct.floatArrayInStruct[4] = -0.4f;
	*/
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
	NSLog(@"BOOL in struct: 1 = %d", (int)aStruct.boolInStruct);
	NSLog(@"Retain count of object %@: 2 = %d", aNumber, [aNumber retainCount]);
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
	NSLog(@"Serialising...");
	NSLog(@"Object serialised with handle %lld\n",[serialiser serialiseObject:foo withName:"foo"]);
	[backend release];
	NSLog(@"Deserialising...");
	id deback = [ETDeserialiserBackendBinaryFile new];
	[deback deserialiseFromURL:[NSURL fileURLWithPath:@"testfile"]];
	id deserialiser = [ETDeserialiser deserialiserWithBackend:deback];
	TestClass * bar = [deserialiser restoreObjectGraph];
	[bar methodTest];
	return 0;
}
