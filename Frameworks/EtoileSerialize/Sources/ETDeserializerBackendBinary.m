#include <stdio.h>
#import "ETDeserializerBackendBinary.h"
#import "ETDeserializer.h"
#import "ETObjectStore.h"
#import <GNUstepBase/GSVersionMacros.h>
#import <EtoileFoundation/ETUUID.h>
#import "IntMap.h"

#define GS_GNUSTEP_V GS_API_LATEST
#if GS_API_VERSION(0, 011700)
//NOTE: Remove this once GNUstep has this method in base.
#define HAVE_MMAP
@interface NSData (MappedURL)
+ (id)dataWithContentsOfURL:(NSURL *)aURL 
					options:(unsigned int)mask 
	  				  error:(NSError **)errorPtr;
@end
@implementation NSData (MappedURL)
// TODO: Replace with a new one-line macro declared in EtoileFoundation
enum {
	NSMappedRead = 1,
	NSUncachedRead = 2
};

+ (id)dataWithContentsOfURL:(NSURL *)aURL 
					options:(unsigned int)mask 
	  				  error:(NSError **)errorPtr
{
	if((mask & NSMappedRead)
		&&
		[aURL isFileURL])
	{
		return [NSData dataWithContentsOfMappedFile:[aURL path]];
	}
	//FIXME: NSUncachedRead should set the 
	//F_NOCACHE fcntl, or equivalent
	return [aURL resourceDataUsingCache: YES];
}
@end
#endif
/**
 * Binary file back end for the deserializer.  
 */
@implementation ETDeserializerBackendBinary
/**
 * Loads the URL and prepares to deserialize it.
 */
- (BOOL) deserializeFromStore:(id)aStore
{
	if(![aStore conformsToProtocol:@protocol(ETSerialObjectStore)])
	{
		return NO;
	}
	ASSIGN(store, aStore);
	return YES;
}
/**
 * Load the header from the provided data, containing the offsets and reference
 * counts of objects, and prepare to deserialize.
 */
- (BOOL) deserializeFromData:(NSData*)aData
{
	if (aData == nil)
	{
		return NO;
	}
    const NSMapTableKeyCallBacks keycallbacks = {NULL, NULL, NULL, NULL, NULL, NSNotAnIntMapKey};
	const NSMapTableValueCallBacks valuecallbacks = {NULL, NULL, NULL};
	if(index != NULL)
	{
		NSFreeMapTable(index);
	}
	if(refCounts != NULL)
	{
		NSFreeMapTable(refCounts);
	}
	index = NSCreateMapTable(keycallbacks, valuecallbacks, 100);
	refCounts = NSCreateMapTable(keycallbacks, valuecallbacks, 100);

	ASSIGN(data, aData);
	const char * blob = [data bytes];
	//Load the index
	int indexOffset = *(int*)blob;
	for(unsigned int i=indexOffset ; i<[data length] ; )
	{
		CORef ref = *(CORef*)&blob[i];
		i += sizeof(CORef);
		int offset = *(int*)&blob[i];
		i += sizeof(int);
		int refCount = *(int*)&blob[i];
		i += sizeof(int);
		//NSLog(@"ref: %d, refCount: %d, offset: %d",ref, refCount, offset);
		NSIntMapInsert(index, ref, offset);
		NSIntMapInsert(refCounts, ref, refCount);
		if(offset == sizeof(int))
		{
			principalObjectRef = ref;
		}
	}
	return (data != nil);
}
- (BOOL) setBranch:(NSString*)aBranch
{
	if (![store isValidBranch:aBranch])
	{
		return NO;
	}
	ASSIGN(branch, aBranch);
	return YES;
}
- (int) setVersion:(int)aVersion
{
	//FIXME: Get the branch sensibly.
	if ([self deserializeFromData:[store dataForVersion:aVersion inBranch:branch]])
	{
		return aVersion;
	}
	return -1;
}

- (void) setDeserializer:(id)aDeserializer;
{
	ASSIGN(deserializer, aDeserializer);
}

- (void) dealloc
{
	[data release];
	NSFreeMapTable(index);
	NSFreeMapTable(refCounts);
	[super dealloc];
}
/**
 * Return the first object listed in the index.
 */
- (CORef) principalObject
{
	return principalObjectRef;
}
/**
 * Look up the class of the principle object.
 */
- (char*) classNameOfPrincipalObject
{
	unsigned int offset = (unsigned int)NSIntMapGet(index, principalObjectRef);
	char * obj = ((char*)[data bytes]) + offset;
	if(*obj == '<')
	{
		return ++obj;
	}
	return NULL;
}
#define SKIP_STRING() obj += strlen(obj) + 1
/**
 * Load the object for the specified reference.  This finds the object in the
 * index and then scans the data associated with it, firing off messages to the
 * deserializer for each component.
 */
- (BOOL) deserializeObjectWithID:(CORef)aReference
{
	//Note: Using int rather than off_t here.  This is not
	//actually a limitation, since NSData and common sense
	//both impose tighter ones.
	unsigned int offset = (unsigned int)NSIntMapGet(index, aReference);
	//TODO: check offset doesn't point inside the index
	if(nil == data || offset > [data length])
	{
		return NO;
	}

	//Check that this actually is an object
	char * obj = ((char*)[data bytes]) + offset;
	//NSLog(@"offset: %d, obj: %s", offset, obj);
	if(*obj == '<')
	{
		char * class = ++obj;
		[deserializer beginObjectWithID:aReference
							  withClass:NSClassFromString([NSString stringWithUTF8String:class])];
		SKIP_STRING();
	}
	else
	{
		return NO;
	}
	while(*obj != '>')
	{
		char * name;
		//Intrinsics are all stored as a single character indicating the type
		//followed by the value.
#define NSSwapBigCharToHost(x) x
#define NSSwapBigUnsignedCharToHost(x) x
#define NSSwapBigUnsignedShortToHost(x) NSSwapBigShortToHost(x)
#define NSSwapBigUnsignedIntToHost(x) NSSwapBigIntToHost(x)
#define NSSwapBigUnsignedLongToHost(x) NSSwapBigLongToHost(x)
#define NSSwapBigUnsignedLongLongToHost(x) NSSwapBigLongLongToHost(x)
#define NSSwapBigObjectReferenceToHost(x) x
#define LOAD(typeChar, typeName, type) case typeChar: \
	name = ++obj;\
	SKIP_STRING();\
	[deserializer load ## typeName:NSSwapBig##typeName##ToHost(*(type*)obj) withName:name];\
	obj += sizeof(type);\
	break;
		switch(*obj)
		{
			//Intrinsics:
			LOAD('c', Char, char)
			LOAD('C', UnsignedChar, unsigned char)
			LOAD('s', Short, short)
			LOAD('S', UnsignedShort, unsigned short)
			LOAD('i', Int, int)
			LOAD('I', UnsignedInt, unsigned int)
			LOAD('l', Long, long)
			LOAD('L', UnsignedLong, unsigned long)
			LOAD('q', LongLong, long long)
			LOAD('Q', UnsignedLongLong, unsigned long long)
			case 'f':
				name = ++obj;
				SKIP_STRING();
				[deserializer loadFloat:NSSwapBigFloatToHost(*(NSSwappedFloat*)obj) withName:name];
				obj += sizeof(NSSwappedFloat);
				break;
			case 'd':
				name = ++obj;
				SKIP_STRING();
				[deserializer loadDouble:NSSwapBigDoubleToHost(*(NSSwappedDouble*)obj) withName:name];
				obj += sizeof(NSSwappedDouble);
				break;
			LOAD('@', ObjectReference, CORef)
			case 'V':
				[deserializer setClassVersion:*(int*)++obj];
				obj += sizeof(int);
				break;
			//Arbitrary data, to be memcpy'd by the deserializer to the correct
			//location.
			case '^':
				name = ++obj;
				SKIP_STRING();
				int size = *(int*)obj;
				obj += sizeof(int);
				[deserializer loadData:obj ofSize:size withName:name];
				obj += size;
				break;
			//NULL-terminated C strings.
			case '*':
				name = ++obj;
				SKIP_STRING();
				[deserializer loadCString:obj withName:name];
				SKIP_STRING();
				break;
			//Classes.
			case '#':
				name = ++obj;
				SKIP_STRING();
				Class class = NSClassFromString([NSString stringWithUTF8String:obj]);
				[deserializer loadClass:class withName:name];
				SKIP_STRING();
				break;
			//Selectors
			case ':':
				name = ++obj;
				SKIP_STRING();
				SEL selector = NSSelectorFromString([NSString stringWithUTF8String:obj]);
				[deserializer loadSelector:selector withName:name];
				SKIP_STRING();
				break;
			//Complex types
			case '{':
				{
					char * structName = ++obj;
					SKIP_STRING();
					name = obj;
					SKIP_STRING();
					[deserializer beginStruct:structName withName:name];
					break;
				}
			case '}':
				[deserializer endStruct];
				obj++;
				break;
			case '[':
				name = ++obj;
				SKIP_STRING();
				[deserializer beginArrayNamed:name withLength:*(unsigned int*)obj];
				obj += sizeof(unsigned int);
				break;
			case ']':
				[deserializer endArray];
				obj++;
				break;
			case '$':
				name = ++obj;
				SKIP_STRING();
				[deserializer loadUUID: (unsigned char *)obj withName: name];
				obj += ETUUIDSize;
				break;
			default:
				return [self deserializeData: obj withTypeChar: (char)*obj];
				/*NSLog(@"Deserializer encountered unexpected char %c in stream", (char)*obj);
				return NO;*/
		}
	}
	[deserializer endObject];
	[deserializer setReferenceCountForObject:aReference 
										  to:
		(int)NSIntMapGet(refCounts, aReference)];
	return YES;
}

- (BOOL) deserializePrincipalObject
{
	return [self deserializeObjectWithID: principalObjectRef];
}

/**
  * Handle the deserialization of data with an unknown type. By defaults, skips 
  * the data and logs a warning. Overrides to handle custom type on 
  * deserialization. You should use LOAD macro to process the data and pass it
  * to the deserializer.
  */
- (BOOL) deserializeData:(char*)obj withTypeChar:(char)type
{
	NSLog(@"Deserializer encountered unexpected char %c in stream", (char)*obj);
	return NO;
}

@end
