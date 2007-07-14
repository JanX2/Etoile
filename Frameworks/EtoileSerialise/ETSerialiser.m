#import "ETSerialiser.h"
#include <stdlib.h>
#include <ctype.h>
#include <objc/objc.h>
#include <objc/objc-api.h>
#include <objc/Object.h>

@implementation Object (UglyHack)
- (BOOL)isKindOfClass:(Class)aClass
{
	return aClass == [Object class];
}
@end

@implementation NSObject (ETSerialisable)
- (BOOL) serialise:(char*)aVariable using:(id<ETSerialiserBackend>)aBackend
{
	return NO;
}
- (BOOL) deserialise:(char*)aVariable fromPointer:(void*)aBlob
{
	return NO;
}
@end

//Must be set to the size along which things are aligned.
const unsigned int WORD_SIZE = sizeof(int);
typedef struct 
{
	size_t size;
	unsigned int offset;
} parsed_type_size_t;

@implementation ETSerialiser
- (void) setBackend:(id<ETSerialiserBackend>)aBackend
{
	ASSIGN(backend, aBackend);
}
+ (ETSerialiser*) serialiserWithBackend:(Class)aBackend forURL:(NSURL*)anURL
{
	ETSerialiser * serialiser = [[self alloc] init];
	[serialiser setBackend:[aBackend serialiserBackendWithURL:anURL]];
	return serialiser;
}
- (int) newVersion
{
	return [backend newVersion];
}
- (id) init
{
	self = [super init];
	if(self == nil)
	{
		return nil;
	}
	unstoredObjects = [[NSMutableSet alloc] init];
	storedObjects = [[NSMutableSet alloc] init];
	return self;
}
- (void) dealloc
{
	[backend release];
	[unstoredObjects release];
	[storedObjects release];
	[super dealloc];
}

- (void) enqueueObject:(id)anObject
{
	if(![storedObjects containsObject:anObject] &&
	   ![unstoredObjects containsObject:anObject])
	{
		[unstoredObjects addObject:anObject];
	}
	[backend incrementReferenceCountForObject:(unsigned long long)(uintptr_t)anObject];
}

- (size_t) storeIntrinsicOfType:(char) type fromAddress:(void*) address withName:(char*) name
{
	switch(type)
	{
		case '#':
			[backend storeClass:(Class)address withName:name];
			return sizeof(id);
		case 'c':
			[backend storeChar:*(char*)address withName:name];
			return sizeof(char);
		case 'C':
			[backend storeUnsignedChar:*(unsigned char*)address withName:name];
			return sizeof(unsigned char);
		case 's':
			[backend storeShort:*(short*)address withName:name];
			return sizeof(short);
		case 'S':
			[backend storeUnsignedShort:*(unsigned short*)address withName:name];
			return sizeof(unsigned short);
		case 'i':
			[backend storeInt:*(int*)address withName:name];
			return sizeof(int);
		case 'I':
			[backend storeUnsignedInt:*(unsigned int*)address withName:name];
			return sizeof(unsigned int);
		case 'l':
			[backend storeLong:*(long int*)address withName:name];
			return sizeof(long int);
		case 'L':
			[backend storeUnsignedLong:*(unsigned long int*)address withName:name];
			return sizeof(unsigned long int);
		case 'q':
			[backend storeLongLong:*(long long int*)address withName:name];
			return sizeof(long long int);
		case 'Q':
			[backend storeUnsignedLongLong:*(unsigned long long int*)address withName:name];
			return sizeof(unsigned long long int);
		case 'f':
			[backend storeFloat:*(float*)address withName:name];
			return sizeof(float);
		case 'd':
			[backend storeDouble:*(double*)address withName:name];
			return sizeof(double);
		case '*':
			[backend storeCString:*(char**)address withName:name];
			return sizeof(char*);
		case '^':
			printf("Pointer types not yet supported\n");
			return -1;
			//[backend storeData:*(void**)address ofSize:_msize(*(void**)address) withName:name];
			//return sizeof(void*);
		case '@':
			if(*(id*)address != nil)
			{
				[self enqueueObject:*(id*)address];
			}
			[backend storeObjectReference:(unsigned long long)(uintptr_t)(*(id*)address) withName:name];
			return sizeof(id);
		default:
			printf("%c not recognised(%s)\n", type);
			return -1;
	}
}
#define INCREMENT_OFFSET type++; retVal.offset++
- (parsed_type_size_t) parseType:(char*) type atAddress:(void*) address withName:(char*) name
{
	parsed_type_size_t  retVal;
	switch(type[0])
	{
		case '{':
			{
//printf("Parsing %s\n", type);
				size_t structSize = 0;
				unsigned int nameEnd = 1;
				unsigned int nameSize = 0;
				char * structName;
				while(type[nameEnd] != '=')
				{
					nameEnd++;
				}
				//Give the length of the string now
				nameSize = nameEnd - 1;
				//TODO: Use the struct name to allow type encodings to be specified for opaque types.
				//printf("Parsing struct...\n");
				[backend beginStructNamed:name];
				//First char after the name
				type = type + nameEnd + 1;
				retVal.offset = nameSize + 2;
				while(*type != '}')
				{
					size_t substructSize;
					//Skip over the name of struct members.  We don't care about them.
					if(*type == '"')
					{
						//Skip open "
						INCREMENT_OFFSET;
						//Skip name
						while(*type != '"')
						{
							INCREMENT_OFFSET;
						}
						//Skip close "
						INCREMENT_OFFSET;
					}
					parsed_type_size_t substruct = [self parseType:type atAddress:address withName:"?"];
					substructSize = substruct.size;
					type += substruct.offset;
					if(substructSize < WORD_SIZE)
					{
						substructSize = WORD_SIZE;
					}
					address += substructSize;
					structSize += substructSize;
				}
				[backend endStruct];
//printf("Remainder: %s\n", type);
				retVal.size = structSize;
				retVal.offset++;
				break;
			}
		case '[':
			{
//printf("Parsing %s\n", type);
				unsigned int elements;
				unsigned int typeOffset = 0;
				//Get the number of array elements:
				type++;
				char * sizeEnd = type;
				unsigned int sizeLength = 0;
				while(isdigit((int)*sizeEnd))
				{
					sizeEnd++;
					sizeLength++;
				}
				unsigned char size[sizeLength+1];
				size[sizeLength] = 0;
				memcpy(size, type, sizeLength);
				elements = strtol(type, NULL, 10);
				type = sizeEnd;
				retVal.offset = sizeLength + 2;
				
				[backend beginArrayNamed:name withLength:elements];
				retVal.size = 0;
				for(unsigned int i=0 ; i<elements ; i++)
				{
					parsed_type_size_t substruct = [self parseType:type atAddress:address withName:"?"];
					retVal.size += substruct.size;
					typeOffset = substruct.offset;
					address += substruct.size;
				}
				retVal.offset += typeOffset;
				[backend endArray];
				break;
			}
		case ']':
			{
				retVal.size = 0;
				retVal.offset = 1;
				break;
			}
		//Ignore type specifiers:
		case 'r':
		case 'n':
		case 'N':
		case 'o':
		case 'O':
		case 'V':
			{
				parsed_type_size_t realtype = [self parseType:type+1 atAddress:address withName:name];
				retVal.offset = realtype.offset + 1;
				retVal.size = realtype.size;
				break;
			}
		default:
			retVal.offset = 1;
			retVal.size = [self storeIntrinsicOfType:type[0] fromAddress:address withName:name];
			if(retVal.size == (unsigned)-1)
			{
				NSLog(@"Unable to serialise %s in %@ (type: %s)", name, currentClass, type);
			}
	}
	return retVal;
}
- (void) serialiseObject:(id)anObject named:(char*)aName
{
	//NSLog(@"Starting object %s", aName);
	currentClass = anObject->class_pointer;
	[backend beginObjectWithID:(unsigned long long)(uintptr_t)anObject 
	                  withName:aName
	                 withClass:currentClass];
	do
	{
		struct objc_ivar_list* ivarlist = currentClass->ivars;
		//NSLog(@"Serialising ivars belonging to class %s", currentClass->name);
		if(ivarlist != NULL)
		{
			for(int i=0 ; i<ivarlist->ivar_count ; i++)
			{
				void * address = ((char*)anObject + (ivarlist->ivar_list[i].ivar_offset));
				char * name = (char*)ivarlist->ivar_list[i].ivar_name;
				char * type = (char*)ivarlist->ivar_list[i].ivar_type;
				//NSLog(@"Found ivar: %s", name);
				/* Don't bother with the isa pointer; we get that filled in for us automatically */
				if(strcmp("isa", name) != 0)
				{
					//NSLog(@"Serialising ivar: %s", name);
					if(![anObject serialise:name using:backend])
					{
						//TODO: Print the name of the ivar and class if this fails.
						[self parseType:type atAddress:address withName:name];
					}
				}
			}
		}
		currentClass = currentClass->super_class;
	}
	while(currentClass != NULL);
	[backend endObject];

	[storedObjects addObject:anObject];
	[unstoredObjects removeObject:anObject];
}
- (unsigned long long) serialiseObject:(id)anObject withName:(char*)name
{
	//TODO: Remove this and fix anything that breaks
/*	if(anObject == nil || anObject->class_pointer == nil)
	{
		[backend beginObjectWithID:(unsigned long long)(uintptr_t)anObject
		                  withName:name
		                 withClass:[Object class]];
		[backend endObject];
		return;
	}*/
	[self enqueueObject:anObject];
	[self serialiseObject:anObject named:name];
	id leftoverObject;
	while((leftoverObject = [unstoredObjects anyObject]) != nil)
	{
		[self serialiseObject:leftoverObject named:"?"];
	}
	return (unsigned long long)(uintptr_t)anObject;
}
@end
