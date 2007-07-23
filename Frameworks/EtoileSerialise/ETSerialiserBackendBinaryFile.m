#include <stdio.h>
#include <objc/objc-api.h>
#import "ETSerialiserBackendBinaryFile.h"

#define FORMAT(format,...) fprintf(blobFile, format, __VA_ARGS__)
#define WRITE(x,b) fwrite(x,b,1,blobFile)
#define STORECOMPLEX(type, value, size) WRITE(type,1);FORMAT("%s%c",aName, '\0');WRITE(value, size)
#define STORE(type, value, c_type) STORECOMPLEX(type, &value, sizeof(c_type))
#define OFFSET (ftell(blobFile))



static inline char * safe_strcat(const char* str1, const char* str2)
{
	unsigned int len1 = strlen(str1);
	unsigned int len2 = strlen(str2);
	char * str3 = calloc(len1 + len2 + 1,sizeof(char));
	memcpy(str3, str1, len1);
	memcpy(str3 + len1, str2, len2);
	return str3;	
}

@implementation ETSerialiserBackendBinaryFile
+ (id) serialiserBackendWithURL:(NSURL*)anURL
{
	return [[[ETSerialiserBackendBinaryFile alloc] initWithURL:anURL] autorelease];
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
	ASSIGN(fileName, [anURL path]);
	[self setFile:[fileName UTF8String]];
	return self;
}
- (void) setFile:(const char*)filename
{
	blobFile = fopen(filename, "w");
	WRITE("\0\0\0\0", sizeof(int));
	const NSMapTableKeyCallBacks keycallbacks = {NULL, NULL, NULL, NULL, NULL, NSNotAnIntMapKey};
	const NSMapTableValueCallBacks valuecallbacks = {NULL, NULL, NULL};
	//TODO: After we've got some real profiling data, 
	//change 100 to a more sensible value
	offsets = NSCreateMapTable(keycallbacks, valuecallbacks, 100);
	refCounts = NSCreateMapTable(keycallbacks, valuecallbacks, 100);
}
- (void) closeFile
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
	NSFreeMapTable(offsets);
	NSFreeMapTable(refCounts);
}
- (void) dealloc
{
	[self closeFile];
	[super dealloc];
}
- (int) newVersion
{
	version++;
	[self closeFile];
	[self setFile:[[NSString stringWithFormat:@"%@.%d", fileName, version] UTF8String]];
	return version;
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
	//TODO: Don't write this more than once per object if the superclass has the same version as the subclass.
	WRITE("V", 1);
	WRITE(&aVersion, sizeof(int));
}
- (void) storeChar:(char)aChar withName:(char*)aName
{
	STORE("c", aChar, char);
}
- (void) storeUnsignedChar:(unsigned char)aChar withName:(char*)aName
{
	STORE("C", aChar, unsigned char);
}
- (void) storeShort:(short)aShort withName:(char*)aName
{
	STORE("s", aShort, short);
}
- (void) storeUnsignedShort:(unsigned short)aShort withName:(char*)aName
{
	STORE("S", aShort, unsigned short);
}
- (void) storeInt:(int)aInt withName:(char*)aName
{
	STORE("i", aInt, int);
}
- (void) storeUnsignedInt:(unsigned int)aInt withName:(char*)aName
{
	STORE("I", aInt, unsigned int);
}
- (void) storeLong:(long)aLong withName:(char*)aName
{
	STORE("l", aLong, long int);
}
- (void) storeUnsignedLong:(unsigned long)aLong withName:(char*)aName
{
	STORE("L", aLong, unsigned long int);
}
- (void) storeLongLong:(long long)aLongLong withName:(char*)aName
{
	STORE("Q", aLongLong, long long int);
}
- (void) storeUnsignedLongLong:(unsigned long long)aLongLong withName:(char*)aName
{
	STORE("Q", aLongLong, unsigned long long int);
}
- (void) storeFloat:(float)aFloat withName:(char*)aName
{
	STORE("f", aFloat, float);
}
- (void) storeDouble:(double)aDouble withName:(char*)aName
{
	STORE("d", aDouble, double);
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
