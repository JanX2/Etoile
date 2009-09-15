#include <stdio.h>
#include <inttypes.h>
#include <objc/objc-api.h>
#import "ETSerializerBackendExample.h"
#import "ETObjectStore.h"
#import <EtoileFoundation/ETUUID.h>
@class ETUUID;

#define FORMAT(format,...) do {\
	char * buffer;\
	int length = asprintf(&buffer, format, ##__VA_ARGS__);\
	WRITE(buffer, length);\
	free(buffer);\
	} while(0)
#define WRITE(x,b) [store writeBytes:(unsigned char*)x count:b]


@implementation ETSerializerBackendExample
+ (id) serializerBackendWithStore:(id<ETSerialObjectStore>)aStore
{
	return [[[ETSerializerBackendExample alloc] initWithStore:aStore] autorelease];
}
+ (Class) deserializer
{
	//No corresponding deserializer
	return Nil;
}
- (void) startVersion:(int)aVersion {}
- (void) flush 
{
	[store commit];
}
- (id) deserializer
{
	//No corresponding deserializer
	return nil;
}
- (id) initWithStore:(id<ETSerialObjectStore>)aStore
{
	ASSIGN(store, aStore);
	return [self init];
}
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
		FORMAT("\t");
	}
}
- (void) beginStruct:(char*)aStructName withName:(char*)aName
{
	[self indent];
	FORMAT("struct %s %s {\n",aStructName, aName);
	indent++;
}
- (void) endStruct
{
	indent--;
	[self indent];
	FORMAT("}\n");
}
- (void) setClassVersion:(int)aVersion
{
	[self indent];
	FORMAT("Class has version %d\n", aVersion);
}
- (void) beginObjectWithID:(CORef)aReference withName:(char*)aName withClass:(Class)aClass
{
	FORMAT("(Object with ID:%"PRIu32")\n",aReference);
	[self indent];
	FORMAT("%s * %s {\n",aClass->name,aName);
	indent++;
}
- (void) storeObjectReference:(CORef)aReference withName:(char*)aName
{
	[self indent];
	FORMAT("id %s=%"PRIu32"\n",aName,aReference);
}
- (void) incrementReferenceCountForObject:(CORef)anObjectID
{
	NSNumber * key = [NSNumber numberWithUnsignedInt: anObjectID];
	unsigned int count = [[referenceCounts objectForKey:key] unsignedIntValue];
	count++;
	[referenceCounts setObject:[NSNumber numberWithUnsignedInt:count]
						forKey:key];
}
- (void) endObject
{
	indent--;
	[self indent];
	FORMAT("}\n");
}
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength;
{
	[self indent];
	FORMAT("array %s [%u]{\n",aName, aLength);
	indent++;
}
- (void) endArray
{
	indent--;
	[self indent];
	FORMAT("}\n");
}

- (void) storeChar:(char)aChar withName:(char*)aName
{
	[self indent];
	FORMAT("char %s=%c;\n",aName,aChar);
}
- (void) storeUnsignedChar:(unsigned char)aChar withName:(char*)aName
{
	[self indent];
	FORMAT("unsigned char %s=%u;\n",aName,(unsigned int)aChar);
}
- (void) storeShort:(short)aShort withName:(char*)aName
{
	[self indent];
	FORMAT("short %s=%hd;\n",aName,aShort);
}
- (void) storeUnsignedShort:(unsigned short)aShort withName:(char*)aName
{
	[self indent];
	FORMAT("unsigned short %s=%hu;\n",aName,aShort);
}
- (void) storeInt:(int)aInt withName:(char*)aName
{
	[self indent];
	FORMAT("int %s=%d;\n",aName,aInt);
}
- (void) storeUnsignedInt:(unsigned int)aInt withName:(char*)aName
{
	[self indent];
	FORMAT("unsigned int %s=%u;\n",aName,aInt);
}
- (void) storeLong:(long)aLong withName:(char*)aName
{
	[self indent];
	FORMAT("long int %s=%ld;\n",aName,aLong);
}
- (void) storeUnsignedLong:(unsigned long)aLong withName:(char*)aName
{
	[self indent];
	FORMAT("unsigned long int %s=%lu;\n",aName,aLong);
}
- (void) storeLongLong:(long long)aLongLong withName:(char*)aName
{
	[self indent];
	FORMAT("long long int %s=%lld;\n",aName,aLongLong);
}
- (void) storeUnsignedLongLong:(unsigned long long)aLongLong withName:(char*)aName
{
	[self indent];
	FORMAT("unsigned long int %s=%llu;\n",aName,aLongLong);
}
- (void) storeFloat:(float)aFloat withName:(char*)aName
{
	[self indent];
	FORMAT("float %s=%f;\n",aName,(double)aFloat);
}
- (void) storeDouble:(double)aDouble withName:(char*)aName
{
	[self indent];
	FORMAT("double %s=%f;\n",aName,aDouble);
}
- (void) storeClass:(Class)aClass withName:(char*)aName
{
	[self indent];
	FORMAT("Class %s=[%s class];\n",aName,aClass->class_pointer->name);
}
- (void) storeSelector:(SEL)aSelector withName:(char*)aName
{
	[self indent];
	FORMAT("SEL %s=@selector(%s);\n",aName,sel_get_name(aSelector));
}
- (void) storeCString:(char*)aCString withName:(char*)aName
{
	[self indent];
	FORMAT("char* %s=\"%s\";\n",aName, aCString);
}
- (void) storeData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName
{
	[self indent];
	FORMAT("void * %s = <<", aName);
	for(unsigned int i=0 ; i<aSize ; i++)
	{
		FORMAT("%.2u",(unsigned int)(*(char*)(aBlob++)));
	}
	FORMAT(">>;\n");
}

- (void) storeUUID:(unsigned char *)aUUID withName:(char *)aName
{
	[self indent];
	ETUUID * uuidObj = [[ETUUID alloc] initWithUUID:aUUID];
	FORMAT("UUID %s=%s\n", aName, [[uuidObj stringValue] UTF8String]);
	[uuidObj release];
}

- (void) dealloc
{
	NSEnumerator * keys = [referenceCounts keyEnumerator];
	NSNumber * key;
	while((key = [keys nextObject]) != nil)
	{
		FORMAT("Object %d has reference count %d\n",
				[key unsignedIntValue],
				[[referenceCounts objectForKey:key] unsignedIntValue]);
	}
	[store release];
	[referenceCounts release];
	[super dealloc];
}
@end
