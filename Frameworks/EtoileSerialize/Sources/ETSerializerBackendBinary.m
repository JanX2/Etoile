#include <stdio.h>
#include <objc/objc-api.h>
#import "ETSerializerBackendBinary.h"
#import "ETDeserializerBackend.h"
#import "ETDeserializer.h"
#import "ETObjectStore.h"
#import "IntMap.h"


#define FORMAT(format,...) do {\
	char * buffer;\
	int length = asprintf(&buffer, format, __VA_ARGS__);\
	WRITE(buffer, length);\
	free(buffer);\
	} while(0)
#define WRITE(x,b) [store writeBytes:(unsigned char*)x count:b]
#define STORECOMPLEX(type, value, size) WRITE(type,1);FORMAT("%s%c",aName, '\0');WRITE(value, size)
#define STORE(type, value, c_type) STORECOMPLEX(type, &value, sizeof(c_type))
#define OFFSET ([store size])
// FIXME: Remove that once UUID class is part of EtoileFoundation
#define ETUUIDSize (16 * sizeof(char))


/**
 * Version of strcat that performs allocation to prevent numpty errors.
 */
static inline char * safe_strcat(const char* str1, const char* str2)
{
	unsigned int len1 = strlen(str1);
	unsigned int len2 = strlen(str2);
	char * str3 = calloc(len1 + len2 + 1,sizeof(char));
	memcpy(str3, str1, len1);
	memcpy(str3 + len1, str2, len2);
	return str3;	
}

/**
 * Currently this back end only works on local files.  To make it work with
 * other kinds of stream you will need to modify the -initWithURL and
 * -closeFile methods to include a case for non-file URLs, and re-define the
 *  WRITE and FORMAT macros to write to the stream.  This format stores
 *  metadata at the end, with a
 * pointer to the start of the metadata at the beginning of the file.  This
 * would need to be changed for streams that don't support seeking.
 */
@implementation ETSerializerBackendBinary
+ (id) serializerBackendWithStore:(id<ETSerialObjectStore>)aStore
{
	return [[[ETSerializerBackendBinary alloc] initWithStore:aStore] autorelease];
}
+ (Class) deserializer
{
	return NSClassFromString(@"ETDeserializerBackendBinary");
}
- (id) deserializer
{
	id deserializer = [[[[self class] deserializer] alloc] init];
	if([deserializer deserializeFromStore:store])
	{
		return [deserializer autorelease];
	}
	else
	{
		[deserializer release];
		return nil;
	}
	return nil;
}
- (void) startVersion:(int)aVersion
{
	//Space for the header.
	WRITE("\0\0\0\0", sizeof(int));
}

- (id) initWithStore:(id<ETSerialObjectStore>)aStore
{
	if (![aStore conformsToProtocol:@protocol(ETSeekableObjectStore)])
	{
		[NSException raise:@"InvalidStore"
					format:@"Binary backend requires a seekable store"];
	}
	if(nil == (self = [super init]))
	{
		return nil;
	}
	ASSIGN(store, aStore);

	const NSMapTableKeyCallBacks keycallbacks = {NULL, NULL, NULL, NULL, NULL, NSNotAnIntMapKey};
	const NSMapTableValueCallBacks valuecallbacks = {NULL, NULL, NULL};
	//TODO: After we've got some real profiling data, 
	//change 100 to a more sensible value
	offsets = NSCreateMapTable(keycallbacks, valuecallbacks, 100);
	refCounts = NSCreateMapTable(keycallbacks, valuecallbacks, 100);

	return self;
}

- (void) closeFile
{
}

- (void) dealloc
{
	[self closeFile];
	NSFreeMapTable(offsets);
	NSFreeMapTable(refCounts);
	[super dealloc];
}

- (void) flush
{
	NSMapEnumerator enumerator = NSEnumerateMapTable(offsets);
	uint32_t indexOffset = (uint32_t)OFFSET;
	void *refp;
	void *offsetp;
	while(NSNextMapEnumeratorPair(&enumerator, &refp, &offsetp))
	{
		CORef ref = (CORef)(intptr_t)refp;
		int offset = (int)(intptr_t) offsetp;
		int refCount = (int)NSIntMapGet(refCounts, ref);
		WRITE(&ref, sizeof(ref));
		WRITE(&offset, sizeof(offset));
		WRITE(&refCount, sizeof(refCount));
	}
	[(id<ETSeekableObjectStore>)store replaceRange:NSMakeRange(0,4) withBytes:(unsigned char*)&indexOffset];
	[store finalize];
}
- (void) beginStruct:(char*)aStructName withName:(char*)aName
{
	FORMAT("{%s%c%s%c",aStructName, 0, aName,0);
}
- (void) endStruct
{
	WRITE("}",1);
}
- (void) beginObjectWithID:(CORef)aReference withName:(char*)aName withClass:(Class)aClass
{
	uint32_t offset = OFFSET;
	NSIntMapInsert(offsets, aReference, offset);
	FORMAT("<%s%c",aClass->name,0);
}
- (void) storeObjectReference:(CORef)aReference withName:(char*)aName
{
	STORE("@", aReference, CORef);
}
- (void) incrementReferenceCountForObject:(CORef)anObjectID
{
	int refCount = (int)NSIntMapGet(refCounts, anObjectID);
	NSIntMapInsert(refCounts, anObjectID,  (++refCount));
}

- (void) endObject
{
	WRITE(">", 1);
}
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength;
{
	FORMAT("[%s%c",aName,0);
	WRITE(&aLength, sizeof(unsigned int));
}
- (void) endArray
{
	WRITE("]", 1);
}
- (void) setClassVersion:(int)aVersion
{
	WRITE("V", 1);
	WRITE(&aVersion, sizeof(int));
}
#define NSSwapHostCharToBig(x) x
#define NSSwapHostUnsignedCharToBig(x) x
#define NSSwapHostUnsignedShortToBig(x) NSSwapHostShortToBig(x)
#define NSSwapHostUnsignedIntToBig(x) NSSwapHostIntToBig(x)
#define NSSwapHostUnsignedLongToBig(x) NSSwapHostLongToBig(x)
#define NSSwapHostUnsignedLongLongToBig(x) NSSwapHostLongLongToBig(x)
#define STORE_METHOD(typeName, type,typeChar)\
- (void) store##typeName:(type)a##typeName withName:(char*)aName\
{\
	type tmp = NSSwapHost##typeName##ToBig(a##typeName);\
	STORE(typeChar, tmp, type);\
}
STORE_METHOD(Char, char, "c")
STORE_METHOD(UnsignedChar, unsigned char, "C")
STORE_METHOD(Short, short, "s")
STORE_METHOD(UnsignedShort, unsigned short, "S")
STORE_METHOD(Int, int, "i")
STORE_METHOD(UnsignedInt, unsigned int, "I")
STORE_METHOD(Long, long, "l")
STORE_METHOD(UnsignedLong, unsigned long, "L")
STORE_METHOD(LongLong, long long, "q")
STORE_METHOD(UnsignedLongLong, unsigned long long, "Q")
- (void) storeFloat:(float)aFloat withName:(char*)aName
{
	NSSwappedFloat tmp = NSSwapHostFloatToBig(aFloat);
	STORE("f", tmp, NSSwappedFloat);
}
- (void) storeDouble:(double)aDouble withName:(char*)aName
{
	NSSwappedDouble tmp = NSSwapHostDoubleToBig(aDouble);
	STORE("d", tmp, NSSwappedDouble);
}
- (void) storeClass:(Class)aClass withName:(char*)aName
{
	FORMAT("#%s%c%s%c", aName, 0,aClass->name,0);
}
- (void) storeSelector:(SEL)aSelector withName:(char*)aName
{
	FORMAT(":%s%c%s%c", aName, 0, [NSStringFromSelector(aSelector) UTF8String], 0);
}
- (void) storeCString:(char*)aCString withName:(char*)aName
{
	FORMAT("*%s%c%s%c", aName, 0, aCString, 0);
}
- (void) storeData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName
{
	FORMAT("^%s%c", aName, 0);
	WRITE(&aSize, sizeof(int));
	WRITE(aBlob,aSize);
}

- (void) storeUUID: (char *)uuid withName: (char *)aName
{
	// Use the symbol $ to denote a core object in the binary data
	STORECOMPLEX("$", uuid, ETUUIDSize);
}

@end
