#include <stdlib.h>
#include <ctype.h>
#include <objc/objc.h>
#include <objc/objc-api.h>
#include <objc/Object.h>
#import "ETSerialiser.h"
#import "ETSerialiserNullBackend.h"

//TODO: Put this in the Makefile
//#define WARN_IF_GUESS

#ifdef WARN_IF_GUESS
#define GUESSWARN NSLog
#else
#define GUESSWARN(...)
#endif

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
- (BOOL) deserialise:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion
{
	return NO;
}
@end

//Must be set to the size along which things are aligned.
const unsigned int WORD_SIZE = sizeof(int);

id nullBackend;

static NSMapTable * serialiserFunctions;

unsigned simpleStringHash(NSMapTable *table, const void *anObject)
{
	if(strlen(anObject) > 3)
	{
		return *(unsigned *)anObject;
	}
	return 0;
}
BOOL isCStringEqual(NSMapTable *table, const void * str1, const void * str2)
{
	return strcmp(str1, str2) == 0;
}

parsed_type_size_t serialiseNSZone(char* aName, void* aZone, id<ETSerialiserBackend> aBackend, BOOL shouldMalloc)
{
	//Just a placeholder to be used to trigger the reloading function
	NSLog(@"Serialising NSZone");
	[aBackend storeChar:'Z' withName:aName];
	parsed_type_size_t retVal;
	retVal.size = 1;
	retVal.offset = strlen(@encode(NSZone));
	return retVal;
}

@implementation ETSerialiser
+ (void) initialize
{
	[super initialize];
	/* Null backend we can reuse */
	nullBackend = [[ETSerialiserNullBackend alloc] init];
	const NSMapTableKeyCallBacks keycallbacks = {simpleStringHash, isCStringEqual, NULL, NULL, NULL, NSNotAnIntMapKey};
	const NSMapTableValueCallBacks valuecallbacks = {NULL, NULL, NULL};
	serialiserFunctions = NSCreateMapTable(keycallbacks, valuecallbacks, 100);
	/* Custom serialisers for known types */
	[self registerSerialiser:serialiseNSZone forStruct:"_NSZone"];
	[self registerSerialiser:serialiseNSZone forStruct:"NSZone"];
}
+ (void) registerSerialiser:(custom_serialiser)aFunction forStruct:(char*)aName
{
	NSMapInsert(serialiserFunctions, aName, (void*)aFunction);
}
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
		case ':':
			[backend storeSelector:*(SEL*)address withName:name];
			return sizeof(SEL);
		case '*':
			GUESSWARN(@"WARNING: Guessing that %s in %@ is NULL-terminated", name, currentClass);
			[backend storeCString:*(char**)address withName:name];
			return sizeof(char*);
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
#define PARSE_STRUCT_BODY() \
				size_t structSize = 0;\
				while(*type != '}')\
				{\
					size_t substructSize;\
					/*Skip over the name of struct members.  We don't care about them. */\
					if(*type == '"')\
					{\
						/*Skip open " */\
						INCREMENT_OFFSET;\
						/*Skip name */\
						while(*type != '"')\
						{\
							INCREMENT_OFFSET;\
						}\
						/* Skip close " */\
						INCREMENT_OFFSET;\
					}\
					parsed_type_size_t substruct = [self parseType:type atAddress:address withName:"?"];\
					substructSize = substruct.size;\
					type += substruct.offset;\
					if(substructSize < WORD_SIZE)\
					{\
						substructSize = WORD_SIZE;\
					}\
					address += substructSize;\
					structSize += substructSize;\
				}

- (parsed_type_size_t) parseType:(char*) type atAddress:(void*) address withName:(char*) name
{
	parsed_type_size_t  retVal;
	switch(type[0])
	{
		case '{':
			{
				//NSLog(@"Parsing %s\n", type);
				unsigned int nameEnd = 1;
				unsigned int nameSize = 0;
				type++;
				while(type[nameEnd] != '=')
				{
					nameEnd++;
				}
				//Give the length of the string now
				nameSize = nameEnd;
				char structName[nameSize + 1];
				memcpy(structName, type, nameSize);
				structName[nameSize] = '\0';
				custom_serialiser function = NSMapGet(serialiserFunctions, structName);
				if(function != NULL)
				{
					retVal = function(name, address, backend, NO);
					break;
				}
				
				[backend beginStructNamed:name];
				//First char after the name
				type += nameSize + 1;
				retVal.offset = nameSize + 2;
				PARSE_STRUCT_BODY();
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
		case '^':
			{
				if(type[1] == '{')
				{
					/* Get the size of the pointed structute */
					id realBackend = backend;
					backend = nullBackend;
					parsed_type_size_t indirect = [self parseType:type + 1 atAddress:address withName:name];
					backend = realBackend;
					unsigned int nameEnd = 2;
					while(type[nameEnd] != '=')
					{
						nameEnd++;
					}
					nameEnd -= 2;
					//Give the length of the string now
					char structName[nameEnd + 1];
					memcpy(structName, type + 2, nameEnd);
					structName[nameEnd] = '\0';
					custom_serialiser function = NSMapGet(serialiserFunctions, structName);
					if(function != NULL)
					{
						retVal = function(name, address, backend, YES);
						break;
					}
					else if((int)indirect.size >= 0)
					{
						GUESSWARN(@"WARNING: Guessing that %s in %@ is not an array.  If it is, you need to serialise it manually.", name, currentClass);
						type += nameEnd + 3;
						retVal.offset += nameEnd + 3;
						NSLog(@"Begin struct pointer");
						PARSE_STRUCT_BODY();
						NSLog(@"End struct pointer");
						break;
					}
				}
				retVal.size = (unsigned)-1;
				NSLog(@"Unable to serialise %s in %@ (type: %s)", name, currentClass, type);
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
	int lastVersion = -1;
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
			int version = [currentClass version];
			if(version != lastVersion)
			{
				lastVersion = version;
				[backend setClassVersion:[currentClass version]];
			}
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
