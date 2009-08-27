#include <stdio.h>
#include <inttypes.h>
#include <locale.h>
#include <objc/objc-api.h>
#import <EtoileFoundation/ETUUID.h>
#import <EtoileFoundation/NSData+Hash.h>
#import "ETSerializerBackendXML.h"
#import "ETDeserializerBackendXML.h"
#import "ETDeserializerBackend.h"
#import "ETDeserializer.h"
#import "ETObjectStore.h"
#import "IntMap.h"

@class ETUUID;

#define FORMAT(format,...) do {\
	char * buffer;\
	int length = asprintf(&buffer, format, ## __VA_ARGS__);\
	WRITE(buffer, length);\
	free(buffer);\
	} while(0)
#define WRITE(x,b) [self indent];[store writeBytes:(unsigned char*)x count:b]
#define STORECOMPLEX(type, value, size) WRITE(type,1);FORMAT("%s%c",aName, '\0');WRITE(value, size)

/**
 * Currently this back end only works on local files.  To make it work with
 * other kinds of stream you will need to modify the -initWithURL and
 * -closeFile methods to include a case for non-file URLs, and re-define the
 *  WRITE and FORMAT macros to write to the stream.  This format stores
 *  metadata at the end, with a
 * pointer to the start of the metadata at the beginning of the file.  This
 * would need to be changed for streams that don't support seeking.
 */
@implementation ETSerializerBackendXML
+ (id) serializerBackendWithStore:(id<ETSerialObjectStore>)aStore
{
	return [[[ETSerializerBackendXML alloc] initWithStore:aStore] autorelease];
}
+ (Class) deserializer
{
	return [ETDeserializerBackendXML class];
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
- (void) setShouldIndent:(BOOL)aFlag
{
	shouldIndent = aFlag;
}
- (void) indent
{
	for(int i=0 ; i<indentLevel ; i++)
	{
		[store writeBytes:(unsigned char*)"\t " count:2];
	}
}
- (void) startVersion:(int)aVersion
{
	// NOTE: The locale must be set to ensure printf has consistent output in all
	// environments.
	locale_t cLocale = newlocale(LC_ALL_MASK,"C",NULL);
	uselocale(cLocale);
	freelocale(cLocale);
	//Space for the header.
	FORMAT("<objects xmlns='http://etoile-project.org/EtoileSerialize' version='1'>\n");
	indentLevel = 1;
}

- (id) initWithStore:(id<ETSerialObjectStore>)aStore
{
	if(nil == (self = [super init]))
	{
		return nil;
	}
	ASSIGN(store, aStore);

	const NSMapTableKeyCallBacks keycallbacks = {NULL, NULL, NULL, NULL, NULL, NSNotAnIntMapKey};
	const NSMapTableValueCallBacks valuecallbacks = {NULL, NULL, NULL};
	//TODO: After we've got some real profiling data, 
	//change 100 to a more sensible value
	refCounts = NSCreateMapTable(keycallbacks, valuecallbacks, 100);

	return self;
}

- (void) dealloc
{
	NSFreeMapTable(refCounts);
	[super dealloc];
}

- (void) flush
{
	NSMapEnumerator enumerator = NSEnumerateMapTable(refCounts);
	uintptr_t ref;
	uintptr_t refCount;
	while(NSNextMapEnumeratorPair(&enumerator, (void*)&ref, (void*)&refCount))
	{
		FORMAT("<refcount object='%"PRIu32"'>%u</refcount>\n", (CORef)ref, (unsigned int)refCount);
	}
	NSEndMapTableEnumeration(&enumerator);
	indentLevel--;
	FORMAT("</objects>\n");

	//Reset the locale
	uselocale(LC_GLOBAL_LOCALE);
	[store finalize];
}
- (void) beginStruct:(char*)aStructName withName:(char*)aName
{
	FORMAT("<struct type='%s' name='%s'>\n",aStructName, aName);
	indentLevel++;
}
- (void) endStruct
{
	indentLevel--;
	FORMAT("</struct>\n");
}
- (void) beginObjectWithID:(CORef)aReference withName:(char*)aName withClass:(Class)aClass
{
	FORMAT("<object class='%s' name='%s' ref='%"PRIu32"'>\n", aClass->name, aName, aReference);
	indentLevel++;
}
- (void) storeObjectReference:(CORef)aReference withName:(char*)aName
{
	FORMAT("<objref name='%s'>%"PRIu32"</objref>\n",aName, aReference);
}
- (void) incrementReferenceCountForObject:(CORef)anObjectID
{
	int refCount = (int)NSIntMapGet(refCounts, anObjectID);
	NSIntMapInsert(refCounts, anObjectID,  (++refCount));
}

- (void) endObject
{
	indentLevel--;
	FORMAT("</object>\n");
}
- (void) beginArrayNamed:(char*)aName withLength:(unsigned int)aLength;
{
	FORMAT("<array name='%s' length='%u'>\n",aName,aLength);
	indentLevel++;
}
- (void) endArray
{
	indentLevel--;
	FORMAT("</array>\n");
}
- (void) setClassVersion:(int)aVersion
{
	FORMAT("<classVersion>%d</classVersion>\n", aVersion);
}
#define STORE_METHOD(typeName, type, typeChar, printfType)\
- (void) store##typeName:(type)a##typeName withName:(char*)aName\
{\
	FORMAT("<%s name='%s'>%" printfType "</%s>\n", typeChar, aName, a##typeName, typeChar);\
}
STORE_METHOD(Char, char, "c", "hhd")
STORE_METHOD(UnsignedChar, unsigned char, "C","hhu")
STORE_METHOD(Short, short, "s", "hd")
STORE_METHOD(UnsignedShort, unsigned short, "S","hu")
STORE_METHOD(Int, int, "i", "d")
STORE_METHOD(UnsignedInt, unsigned int, "I","u")
STORE_METHOD(Long, long, "l", "ld")
STORE_METHOD(UnsignedLong, unsigned long, "L", "lu")
STORE_METHOD(LongLong, long long, "q", "lld")
STORE_METHOD(UnsignedLongLong, unsigned long long, "Q","llu")
STORE_METHOD(Double, double, "d", "f")
- (void) storeFloat:(float)aFloat withName:(char*)aName
{
	FORMAT("<f name='%s'>%f</f>\n", aName, (double)aFloat);
}
- (void) storeClass:(Class)aClass withName:(char*)aName
{
	FORMAT("<class name='%s'>%s</class>\n", aName, aClass->name);
}
- (void) storeSelector:(SEL)aSelector withName:(char*)aName
{
	FORMAT("<sel name='%s'>%s</sel>\n", aName, [NSStringFromSelector(aSelector) UTF8String]);
}
- (void) storeCString:(char*)aCString withName:(char*)aName
{
	FORMAT("<str name='%s'>%s</str>\n", aName, aCString);
}
- (void) storeData:(void*)aBlob ofSize:(size_t)aSize withName:(char*)aName
{
	NSString *b64  = [[NSData dataWithBytes: aBlob length: aSize] base64String];
	FORMAT("<data size='%u' name='%s'><![CDATA[", (unsigned)aSize, aName);
	[store writeBytes: (unsigned char*)[b64 UTF8String] count: [b64 length]];
	[store writeBytes:(unsigned char*)"]]></data>\n" count:11];
}
- (void) storeUUID:(unsigned char *)aUUID withName:(char *)aName
{
	//FORMAT("<uuid name='%s'>
	ETUUID * uuidObj = [[ETUUID alloc] initWithUUID:aUUID];
	FORMAT("<uuid name='%s'>%s</uuid>\n", aName, [[uuidObj stringValue] UTF8String]);
	[uuidObj release];
}
@end
