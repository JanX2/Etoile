#import <Foundation/Foundation.h>

typedef uint32_t CORef;

@protocol ETSerialiserBackend <NSObject>
//Setup
+ (id) serialiserBackendWithURL:(NSURL*)anURL;
- (id) initWithURL:(NSURL*)anURL;
- (int) newVersion;
//Objects
- (void) setClassVersion:(int)aVersion;
- (void) beginObjectWithID:(CORef)aReference withName:(char*)aName withClass:(Class)aClass;
- (void) endObject;
- (void) storeObjectReference:(CORef)aReference withName:(char*)aName;
- (void) incrementReferenceCountForObject:(CORef)anObjectID;
//Nested types
- (void) beginStruct:(char*)aStructName withName:(char*)aName;
//- (void) beginStructNamed:(char*)aName;
- (void) endStruct;
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength;
- (void) endArray;
//Intrinsics
- (void) storeChar:(char)aChar withName:(char*)aName;
- (void) storeUnsignedChar:(unsigned char)aChar withName:(char*)aName;
- (void) storeShort:(short)aShort withName:(char*)aName;
- (void) storeUnsignedShort:(unsigned short)aShort withName:(char*)aName;
- (void) storeInt:(int)aInt withName:(char*)aName;
- (void) storeUnsignedInt:(unsigned int)aInt withName:(char*)aName;
- (void) storeLong:(long)aLong withName:(char*)aName;
- (void) storeUnsignedLong:(unsigned long)aLong withName:(char*)aName;
- (void) storeLongLong:(long long)aLongLong withName:(char*)aName;
- (void) storeUnsignedLongLong:(unsigned long long)aLongLong withName:(char*)aName;
- (void) storeFloat:(float)aFloat withName:(char*)aName;
- (void) storeDouble:(double)aDouble withName:(char*)aName;
- (void) storeClass:(Class)aClass withName:(char*)aName;
- (void) storeFloat:(Class)aClass withName:(char*)aName;
- (void) storeSelector:(SEL)aSelector withName:(char*)aName;
- (void) storeCString:(const char*)aCString withName:(char*)aName;
- (void) storeData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName;
@end

//Informal protocol for serialisable objects.  Implement this to manually handle unsupported types.

#define MANUAL_DESERIALISE ((void*)1)
#define AUTO_DESERIALISE ((void*)0)
@interface NSObject (ETSerialisable)
- (BOOL) serialise:(char*)aVariable using:(id<ETSerialiserBackend>)aBackend;
- (void*) deserialise:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion;
@end

typedef struct 
{
	size_t size;
	unsigned int offset;
} parsed_type_size_t;

typedef parsed_type_size_t(*custom_serialiser)(char*,void*, id<ETSerialiserBackend>,BOOL);

@interface ETSerialiser : NSObject {
	id<ETSerialiserBackend> backend;
	NSMutableSet * unstoredObjects;
	NSMutableSet * storedObjects;
	Class currentClass;
}
+ (void) registerSerialiser:(custom_serialiser)aFunction forStruct:(char*)aName;
+ (ETSerialiser*) serialiserWithBackend:(Class)aBackend forURL:(NSURL*)anURL;
- (int) newVersion;
- (unsigned long long) serialiseObject:(id)anObject withName:(char*)aName;
@end
