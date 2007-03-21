#import <Foundation/Foundation.h>

@protocol ETSerialiserBackend
//Objects
- (void) beginObjectWithID:(unsigned long long)aReference withName:(char*)aName withClass:(Class)aClass;
- (void) endObject;
- (void) storeObjectReference:(unsigned long long)aReference withName:(char*)aName;
- (void) incrementReferenceCountForObject:(unsigned long long)anObjectID;
//Nested types
- (void) beginStructNamed:(char*)aName;
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
- (void) storeCString:(char*)aCString withName:(char*)aName;
- (void) storeData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName;
@end

//Informal protocol for serialisable objects.  Implement this to manually handle unsupported types.
@protocol ETSerialisable
- (BOOL) serialise:(char*)aVariable using:(id<ETSerialiserBackend>)aBackend;
- (BOOL) deserialise:(char*)aVariable fromPointer:(void*)aBlob;
@end

@interface ETSerialiser : NSObject {
	id<ETSerialiserBackend> backend;
	NSMutableSet * unstoredObjects;
	NSMutableSet * storedObjects;
}
+ (ETSerialiser*) serialiserWithBackend:(id<ETSerialiserBackend>)aBackend;
- (void) setBackend:(id<ETSerialiserBackend>)aBackend;
- (unsigned long long) serialiseObject:(id)anObject withName:(char*)aName;
@end
