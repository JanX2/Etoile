#import "ETSerialiserNullBackend.h"

/**
 * Null backend.  Ignores all serialise messages.
 */
@implementation ETSerialiserNullBackend
//Setup
+ (id) serialiserBackendWithURL:(NSURL*)anURL
{
	return [[[ETSerialiserNullBackend alloc] init] autorelease];
}
- (id) initWithURL:(NSURL*)anURL 
{
	return [self init];
}
- (int) newVersion {return 0;}
//Objects
- (void) setClassVersion:(int)aVersion {}
- (void) beginObjectWithID:(CORef)aReference withName:(char*)aName withClass:(Class)aClass {}
- (void) endObject {}
- (void) storeObjectReference:(CORef)aReference withName:(char*)aName {}
- (void) incrementReferenceCountForObject:(CORef)anObjectID {}
//Nested types
- (void) beginStructNamed:(char*)aName {}
- (void) endStruct {}
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength {}
- (void) endArray {}
//Intrinsics
- (void) storeChar:(char)aChar withName:(char*)aName {}
- (void) storeUnsignedChar:(unsigned char)aChar withName:(char*)aName {}
- (void) storeShort:(short)aShort withName:(char*)aName {}
- (void) storeUnsignedShort:(unsigned short)aShort withName:(char*)aName {}
- (void) storeInt:(int)aInt withName:(char*)aName {}
- (void) storeUnsignedInt:(unsigned int)aInt withName:(char*)aName {}
- (void) storeLong:(long)aLong withName:(char*)aName {}
- (void) storeUnsignedLong:(unsigned long)aLong withName:(char*)aName {}
- (void) storeLongLong:(long long)aLongLong withName:(char*)aName {}
- (void) storeUnsignedLongLong:(unsigned long long)aLongLong withName:(char*)aName {}
- (void) storeFloat:(float)aFloat withName:(char*)aName {}
- (void) storeDouble:(double)aDouble withName:(char*)aName {}
- (void) storeClass:(Class)aClass withName:(char*)aName {}
- (void) storeSelector:(SEL)aSelector withName:(char*)aName {}
- (void) storeCString:(char*)aCString withName:(char*)aName {}
- (void) storeData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName {}
@end
