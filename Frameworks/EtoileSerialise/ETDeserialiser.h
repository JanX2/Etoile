#import <Foundation/Foundation.h>

@protocol ETDeserialiserBackend
- (id) deserialiseObjectWithID:(unsigned long long)aRefference;
@end

@interface ETDeserialiser : NSObject {
	id<ETDeserialiserBackend> backend;
	NSMutableDictionary * pointersToReferences;
}
+ (ETSerialiser*) serialiserWithBackend:(id<ETDeserialiserBackend>)aBackend;
- (void) setBackend:(id<ETDeserialiserBackend>)aBackend;
- (unsigned long long) serialiseObject:(id)anObject withName:(char*)aName;
//Objects
- (void) beginObjectWithID:(unsigned long long)aReference withName:(char*)aName withClass:(Class)aClass;
- (void) endObject;
- (void) loadObjectReference:(unsigned long long)aReference withName:(char*)aName;
- (void) incrementReferenceCountForObject:(unsigned long long)anObjectID;
//Nested types
- (void) beginStructNamed:(char*)aName;
- (void) endStruct;
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength;
- (void) endArray;
//Intrinsics
- (void) loadChar:(char)aChar withName:(char*)aName;
- (void) loadUnsignedChar:(unsigned char)aChar withName:(char*)aName;
- (void) loadShort:(short)aShort withName:(char*)aName;
- (void) loadUnsignedShort:(unsigned short)aShort withName:(char*)aName;
- (void) loadInt:(int)aInt withName:(char*)aName;
- (void) loadUnsignedInt:(unsigned int)aInt withName:(char*)aName;
- (void) loadLong:(long)aLong withName:(char*)aName;
- (void) loadUnsignedLong:(unsigned long)aLong withName:(char*)aName;
- (void) loadLongLong:(long long)aLongLong withName:(char*)aName;
- (void) loadUnsignedLongLong:(unsigned long long)aLongLong withName:(char*)aName;
- (void) loadFloat:(float)aFloat withName:(char*)aName;
- (void) loadDouble:(double)aDouble withName:(char*)aName;
- (void) loadClass:(Class)aClass withName:(char*)aName;
- (void) loadFloat:(Class)aClass withName:(char*)aName;
- (void) loadSelector:(SEL)aSelector withName:(char*)aName;
- (void) loadCString:(char*)aCString withName:(char*)aName;
- (void) loadData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName;
@end
