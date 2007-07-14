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
@implementation ETDeserialiserBackendBinaryFile
- (BOOL) deserialiseFromURL:(NSURL*)aURL
{
	return [self deserialiseFromData:[NSData dataWithContentsOfURL:aURL 
	                                                       options:NSMappedRead
	                                                         error:(NSError**)nil]];
}
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
- (CORef) principalObject
{
	return principalObjectRef;
}
#define SKIP_STRING() obj += strlen(obj) + 1
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
			case '*':
				name = ++obj;
				SKIP_STRING();
				[deserialiser loadCString:obj withName:name];
				SKIP_STRING();
				break;
			case '#':
				name = ++obj;
				SKIP_STRING();
				Class class = NSClassFromString([NSString stringWithUTF8String:obj]);
				[deserialiser loadClass:class withName:name];
				SKIP_STRING();
				break;
			case ':':
				name = ++obj;
				SKIP_STRING();
				SEL selector = NSSelectorFromString([NSString stringWithUTF8String:obj]);
				[deserialiser loadSelector:selector withName:name];
				SKIP_STRING();
				break;
			//Complex types
			case '{':
				name = ++obj;
				SKIP_STRING();
				[deserialiser beginStructNamed:name];
				break;
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
				return NO;
		}
	}
	[deserialiser endObject];
	[deserialiser setReferenceCountForObject:aReference 
										  to:(int) NSMapGet(refCounts, (void*)aReference)];
	return YES;
}
@end
