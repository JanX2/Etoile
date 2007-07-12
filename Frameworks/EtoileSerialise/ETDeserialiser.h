#import <Foundation/Foundation.h>
#import "ETSerialiser.h"


@protocol ETDeserialiserBackend <NSObject>
- (BOOL) readDataFromURL:(NSURL*)aURL;
- (BOOL) deserialiseObjectWithID:(CORef)aReference;
- (void) setDeserialiser:(id)aDeserialiser;
- (CORef) principalObject;
@end


typedef struct 
{
	void * startOffset;
	int index;
	char type;
} ETDeserialiserState;

/**
 * Deserialiser.  Performs construction of object graphs based
 * on instructions received from back end.  Each back end is
 * expected to read data from a 
 */
@interface ETDeserialiser : NSObject {
	id<ETDeserialiserBackend> backend;
	NSMutableDictionary * pointersToReferences;
	NSMapTable * loadedObjects;
	NSMapTable * objectPointers;
	//State machine stack
	ETDeserialiserState states[20];
	int stackTop;
	//Object currently being deserialised
	id object;
	int loadedIVar;
}
+ (ETDeserialiser*) deserialiserWithBackend:(id<ETDeserialiserBackend>)aBackend;
- (void) setBackend:(id<ETDeserialiserBackend>)aBackend;
- (id) restoreObjectGraph;
//Objects
- (void) beginObjectWithID:(CORef)aReference withClass:(Class)aClass;
- (void) endObject;
- (void) loadObjectReference:(CORef)aReference withName:(char*)aName;
- (void) setReferenceCountForObject:(CORef)anObjectID to:(int)aRefCount;
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
- (void) loadSelector:(SEL)aSelector withName:(char*)aName;
- (void) loadCString:(char*)aCString withName:(char*)aName;
- (void) loadData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName;
@end
