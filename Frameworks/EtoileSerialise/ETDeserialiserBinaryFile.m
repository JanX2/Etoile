#include <stdio.h>
#import "ETDeserialiserBinaryFile.h"

@implementation ETDeserialiserBackendBinaryFile
- (BOOL) readDataFromURL:(NSURL*)aURL
{
	/* TODO: Implement this method in GNUstep's NSData
	data = [[NSData dataWithContentsOfURL:aURL 
								  options:NSMappedRead
									error:nil] retain];
	 */
	data = [NSData dataWithContentsOfURL:aURL];
	//TODO: Get rid of this hack and store the index in the file
	FILE * indexFile = fopen([[[aURL path] stringByAppendingString:@"index"] UTF8String], "r");
    const NSMapTableKeyCallBacks keycallbacks = {NULL, NULL, NULL, NULL, NULL, NSNotAnIntMapKey};
	const NSMapTableValueCallBacks valuecallbacks = {NULL, NULL, NULL};
	index = NSCreateMapTable(keycallbacks, valuecallbacks, 100);
	while(!feof(indexFile))
	{
		CORef ref;
		off_t offset;
		fread(&ref, sizeof(CORef), 1, indexFile);
		fread(&offset, sizeof(off_t), 1, indexFile);
		NSMapInsert(index, (void*)(int)ref, (void*)(int) offset);
		if(principalObjectRef == 0)
		{
			principalObjectRef = ref;
		}
	}
	fclose(indexFile);
	return (data != nil);
}
- (void) setDeserialiser:(id)aDeserialiser;
{
	deserialiser = aDeserialiser;
}

- (void) dealloc
{
	[data release];
	NSFreeMapTable(index);
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
	if(offset > [data length])
	{
		return NO;
	}

	char * obj = ((char*)[data bytes]) + offset;
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
	return YES;
}
@end
