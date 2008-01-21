#include <stdio.h>
#include <objc/objc-api.h>
#import "ETSerialiserBackendBinaryFile.h"
#import "ETDeserialiser.h"

#define FORMAT(format,...) fprintf(blobFile, format, __VA_ARGS__)
#define WRITE(x,b) fwrite(x,b,1,blobFile)
#define STORECOMPLEX(type, value, size) WRITE(type,1);FORMAT("%s%c",aName, '\0');WRITE(value, size)
#define STORE(type, value, c_type) STORECOMPLEX(type, &value, sizeof(c_type))
#define OFFSET (ftell(blobFile))


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
@implementation ETSerialiserBackendBinaryFile
+ (id) serialiserBackendWithURL:(NSURL*)anURL
{
	return [[[ETSerialiserBackendBinaryFile alloc] initWithURL:anURL] autorelease];
}
+ (Class) deserialiser
{
	return NSClassFromString(@"ETDeserialiserBackendBinaryFile");
}
- (id) deserialiser
{
	if(fileName != nil)
	{
		id deserialiser = [[[[self class] deserialiser] alloc] init];
		if([deserialiser deserialiseFromURL:[NSURL fileURLWithPath:fileName]])
		{
			return [deserialiser autorelease];
		}
		else
		{
			[deserialiser release];
			return nil;
		}

	}
	return nil;
}
/**
 * This back end currently only works with files.  It uses this method to open
 * and prepare them.
 */
- (void) setFile:(const char*)filename
{
	blobFile = fopen(filename, "w");
	//Space for the header.
	WRITE("\0\0\0\0", sizeof(int));
	const NSMapTableKeyCallBacks keycallbacks = {NULL, NULL, NULL, NULL, NULL, NSNotAnIntMapKey};
	const NSMapTableValueCallBacks valuecallbacks = {NULL, NULL, NULL};
	//TODO: After we've got some real profiling data, 
	//change 100 to a more sensible value
	offsets = NSCreateMapTable(keycallbacks, valuecallbacks, 100);
	refCounts = NSCreateMapTable(keycallbacks, valuecallbacks, 100);
}
- (id) initWithURL:(NSURL*)anURL
{
	if(nil == (self = [self init]))
	{
		return nil;
	}
	/* Only works on local files for now */
	if(![anURL isFileURL])
	{
		[self release];
		return nil;
	}
	NSFileManager * manager = [NSFileManager defaultManager];
	NSString * path = [anURL path];
	if(![manager fileExistsAtPath:path])
	{
		[manager createDirectoryAtPath:path
								  attributes:nil];
	}
	ASSIGN(fileName, [anURL path]);
	[self setFile:[[NSString stringWithFormat:@"%@/0.save", fileName] UTF8String]];
	return self;
}
- (void) closeFile
{
	if(blobFile != NULL)
	{
		NSMapEnumerator enumerator = NSEnumerateMapTable(offsets);
		int indexOffset = (int)OFFSET;
		CORef ref;
		int offset;
		while(NSNextMapEnumeratorPair(&enumerator, (void*)&ref, (void*)&offset))
		{
			int refCount = (int)NSMapGet(refCounts, (void*)ref);
			WRITE(&ref, sizeof(ref));
			WRITE(&offset, sizeof(offset));
			WRITE(&refCount, sizeof(refCount));
		}
		rewind(blobFile);
		WRITE(&indexOffset, sizeof(int));
		fclose(blobFile);
		blobFile = NULL;
		NSFreeMapTable(offsets);
		NSFreeMapTable(refCounts);
	}
}
- (void) dealloc
{
	[self closeFile];
	[super dealloc];
}
- (int) newVersion
{
	return [self setVersion:version+1];
}
- (int) setVersion:(int)aVersion
{
	version = aVersion;
	[self closeFile];
	[self setFile:[[NSString stringWithFormat:@"%@/%d.save", fileName, version] UTF8String]];
	return version;
}
- (void) flush
{
	[self closeFile];
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
	off_t offset = ftello(blobFile);
	NSMapInsert(offsets, (void*)aReference, (void*)(int)offset);
	FORMAT("<%s%c",aClass->name,0);
}
- (void) storeObjectReference:(CORef)aReference withName:(char*)aName
{
	STORE("@", aReference, CORef);
}
- (void) incrementReferenceCountForObject:(CORef)anObjectID
{
	int refCount = (int)NSMapGet(refCounts, (void*)anObjectID);
	NSMapInsert(refCounts, (void*)anObjectID, (void*) (++refCount));
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
@end
