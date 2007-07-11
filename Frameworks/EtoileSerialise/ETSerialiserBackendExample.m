#include <stdio.h>
#include <objc/objc-api.h>
#import "ETSerialiserBackendExample.h"


@implementation ETSerialiserBackendExample
- (id) init
{
	self = [super init];
	if(self == nil)
	{
		return nil;
	}
	referenceCounts = [[NSMutableDictionary alloc] init];
	return self;
}
- (void) indent
{
	for(unsigned int i=0 ; i<indent ; i++)
	{
		printf("\t");
	}
}

- (void) beginStructNamed:(char*)aName
{
	[self indent];
	printf("struct %s {\n",aName);
	indent++;
}
- (void) endStruct
{
	indent--;
	[self indent];
	printf("}\n");
}
- (void) beginObjectWithID:(CORef)aReference withName:(char*)aName withClass:(Class)aClass
{
	printf("(Object with ID:%lld)\n",aReference);
	[self indent];
	printf("%s * %s {\n",aClass->name,aName);
	indent++;
}
- (void) storeObjectReference:(CORef)aReference withName:(char*)aName
{
	[self indent];
	printf("id %s=%lld\n",aName,aReference);
}
- (void) incrementReferenceCountForObject:(CORef)anObjectID
{
	NSNumber * key = [NSNumber numberWithUnsignedLongLong: anObjectID];
	unsigned long long count = [[referenceCounts objectForKey:key] unsignedLongLongValue];
	count++;
	[referenceCounts setObject:[NSNumber numberWithUnsignedLongLong:count]
						forKey:key];
}
- (void) endObject
{
	indent--;
	[self indent];
	printf("}\n");
}
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength;
{
	[self indent];
	printf("array %s [%u]{\n",aName, aLength);
	indent++;
}
- (void) endArray
{
	indent--;
	[self indent];
	printf("}\n");
}

- (void) storeChar:(char)aChar withName:(char*)aName
{
	[self indent];
	printf("char %s=%c;\n",aName,aChar);
}
- (void) storeUnsignedChar:(unsigned char)aChar withName:(char*)aName
{
	[self indent];
	printf("unsigned char %s=%u;\n",aName,(unsigned int)aChar);
}
- (void) storeShort:(short)aShort withName:(char*)aName
{
	[self indent];
	printf("short %s=%hd;\n",aName,aShort);
}
- (void) storeUnsignedShort:(unsigned short)aShort withName:(char*)aName
{
	[self indent];
	printf("unsigned short %s=%hu;\n",aName,aShort);
}
- (void) storeInt:(int)aInt withName:(char*)aName
{
	[self indent];
	printf("int %s=%d;\n",aName,aInt);
}
- (void) storeUnsignedInt:(unsigned int)aInt withName:(char*)aName
{
	[self indent];
	printf("unsigned int %s=%u;\n",aName,aInt);
}
- (void) storeLong:(long)aLong withName:(char*)aName
{
	[self indent];
	printf("long int %s=%ld;\n",aName,aLong);
}
- (void) storeUnsignedLong:(unsigned long)aLong withName:(char*)aName
{
	[self indent];
	printf("unsigned long int %s=%lu;\n",aName,aLong);
}
- (void) storeLongLong:(long long)aLongLong withName:(char*)aName
{
	[self indent];
	printf("long long int %s=%lld;\n",aName,aLongLong);
}
- (void) storeUnsignedLongLong:(unsigned long long)aLongLong withName:(char*)aName
{
	[self indent];
	printf("unsigned long int %s=%llu;\n",aName,aLongLong);
}
- (void) storeFloat:(float)aFloat withName:(char*)aName
{
	[self indent];
	printf("float %s=%f;\n",aName,(double)aFloat);
}
- (void) storeDouble:(double)aDouble withName:(char*)aName
{
	[self indent];
	printf("double %s=%f;\n",aName,aDouble);
}
- (void) storeClass:(Class)aClass withName:(char*)aName
{
	[self indent];
	printf("Class %s=[%s class];\n",aName,aClass->class_pointer->name);
}
- (void) storeSelector:(SEL)aSelector withName:(char*)aName
{
	[self indent];
	printf("SEL %s=@selector(%s);\n",aName,sel_get_name(aSelector));
}
- (void) storeCString:(char*)aCString withName:(char*)aName
{
	[self indent];
	printf("char* %s=\"%s\";\n",aName, aCString);
}
- (void) storeData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName
{
	[self indent];
	printf("void * %s = <<", aName);
	for(unsigned int i=0 ; i<aSize ; i++)
	{
		printf("%.2u",(unsigned int)(*(char*)(aBlob++)));
	}
	printf(">>;\n");
}

- (void) dealloc
{
	NSEnumerator * keys = [referenceCounts keyEnumerator];
	NSNumber * key;
	while((key = [keys nextObject]) != nil)
	{
		printf("Object %lld has reference count %lld\n",
				[key unsignedLongLongValue],
				[[referenceCounts objectForKey:key] unsignedLongLongValue]);
	}
	[referenceCounts release];
	[super dealloc];
}
@end
