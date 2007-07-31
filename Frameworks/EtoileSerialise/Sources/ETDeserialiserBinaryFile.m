#include <stdio.h>
#import "ETDeserialiserBinaryFile.h"

//NOTE: Remove this once GNUstep has this method in base.
#define HAVE_MMAP
@interface NSData (MappedURL)
+ (id)dataWithContentsOfURL:(NSURL *)aURL 
					options:(unsigned int)mask 
	  				  error:(NSError **)errorPtr;
@end
@implementation NSData (MappedURL)
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

/**
 * Binary file back end for the deserialiser.  
 */
@implementation ETDeserialiserBackendBinaryFile
/**
 * Loads the URL and prepares to deserialise it.
 */
- (BOOL) deserialiseFromURL:(NSURL*)aURL
{
	return [self deserialiseFromData:[NSData dataWithContentsOfURL:aURL 
	                                                       options:NSMappedRead
	                                                         error:(NSError**)nil]];
}
/**
 * Load the header from the provided data, containing the offsets and reference
 * counts of objects, and prepare to deserialise.
 */
- (BOOL) deserialiseFromData:(NSData*)aData
{
	data = [aData retain];
    const NSMapTableKeyCallBacks keycallbacks = {NULL, NULL, NULL, NULL, NULL, NSNotAnIntMapKey};
	const NSMapTableValueCallBacks valuecallbacks = {NULL, NULL, NULL};
	index = NSCreateMapTable(keycallbacks, valuecallbacks, 100);
	refCounts = NSCreateMapTable(keycallbacks, valuecallbacks, 100);

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
		NSMapInsert(index, (void*)(int)ref, (void*)offset);
		NSMapInsert(refCounts, (void*)(int)ref, (void*)refCount);
		if(offset == sizeof(int))
		{
			principalObjectRef = ref;
		}
	}
	return (data != nil);
}
- (void) setDeserialiser:(id)aDeserialiser;
{
	ASSIGN(deserialiser, aDeserialiser);
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
	unsigned int offset = (unsigned int)NSMapGet(index, (void*)principalObjectRef);
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
 * deserialiser for each component.
 */
- (BOOL) deserialiseObjectWithID:(CORef)aReference
{
	//Note: Using int rather than off_t here.  This is not
	//actually a limitation, since NSData and common sense
	//both impose tighter ones.
	unsigned int offset = (unsigned int)NSMapGet(index, (void*)aReference);
	//TODO: check offset doesn't point inside the index
	if(offset > [data length])
	{
		return NO;
	}

	//Check that this actually is an object
	char * obj = ((char*)[data bytes]) + offset;
	//NSLog(@"offset: %d, obj: %s", offset, obj);
	if(*obj == '<')
	{
		char * class = ++obj;
		[deserialiser beginObjectWithID:aReference
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
#define LOAD(typeChar, typeName, type) case typeChar: \
	name = ++obj;\
	SKIP_STRING();\
	[deserialiser load ## typeName:*(type*)obj withName:name];\
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
			LOAD('f', Float, float)
			LOAD('d', Double, double)
			LOAD('@', ObjectReference, CORef)
			case 'V':
				[deserialiser setClassVersion:*(int*)++obj];
				obj += sizeof(int);
				break;
			//Arbitrary data, to be memcpy'd by the deserialiser to the correct
			//location.
			case '^':
				name = ++obj;
				SKIP_STRING();
				int size = *(int*)obj;
				obj += sizeof(int);
				[deserialiser loadData:obj ofSize:size withName:name];
				obj += size;
				break;
			//NULL-terminated C strings.
			case '*':
				name = ++obj;
				SKIP_STRING();
				[deserialiser loadCString:obj withName:name];
				SKIP_STRING();
				break;
			//Classes.
			case '#':
				name = ++obj;
				SKIP_STRING();
				Class class = NSClassFromString([NSString stringWithUTF8String:obj]);
				[deserialiser loadClass:class withName:name];
				SKIP_STRING();
				break;
			//Selectors
			case ':':
				name = ++obj;
				SKIP_STRING();
				SEL selector = NSSelectorFromString([NSString stringWithUTF8String:obj]);
				[deserialiser loadSelector:selector withName:name];
				SKIP_STRING();
				break;
			//Complex types
			case '{':
				{
					char * structName = ++obj;
					SKIP_STRING();
					name = obj;
					SKIP_STRING();
					[deserialiser beginStruct:structName withName:name];
					break;
				}
			case '}':
				[deserialiser endStruct];
				obj++;
				break;
			case '[':
				name = ++obj;
				SKIP_STRING();
				[deserialiser beginArrayNamed:name withLength:*(unsigned int*)obj];
				obj += sizeof(unsigned int);
				break;
			case ']':
				[deserialiser endArray];
				obj++;
				break;
			default:
				NSLog(@"Deserialiser encountered unexpected char %c in stream", (char)*obj);
				return NO;
		}
	}
	[deserialiser endObject];
	[deserialiser setReferenceCountForObject:aReference 
										  to:(int) NSMapGet(refCounts, (void*)aReference)];
	return YES;
}
@end
