#include <stdlib.h>
#include <ctype.h>
#include <objc/objc.h>
#include <objc/objc-api.h>
#include <objc/Object.h>
#import "ETSerializer.h"
#import "ETDeserializer.h"
#import "ETSerializerNullBackend.h"
#import "ETObjectStore.h"
#import "StringMap.h"
#import "ESCORefTable.h"

//TODO: Put this in the Makefile
//#define WARN_IF_GUESS

#ifdef WARN_IF_GUESS
#define GUESSWARN NSLog
#else
#define GUESSWARN(...)
#endif

/**
 * Objects that inherit from Object instead of NSObject don't understand
 * isKindOfClass:
 */
@implementation Object (UglyHack)
- (BOOL)isKindOfClass:(Class)aClass
{
	return aClass == [Object class];
}
@end

/**
 * Informal protocol for serialization-aware objects.
 */
@implementation NSObject (ETSerializable)
/**
 * Returns NO, indicating that the object does not serialize the variable manually.
 */
- (BOOL) serialize:(char*)aVariable using:(ETSerializer*)aBackend
{
	return NO;
}
/**
 * Automatically deserialize everything, unless a subclass overrides this to
 * provide special handling.
 */
- (void*) deserialize:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion
{
	return AUTO_DESERIALIZE;
}
@end

//Must be set to the size along which things are aligned.
//FIXME: This is broken on pretty much every architecture.
const unsigned int WORD_SIZE = sizeof(int);

/**
 * Instance of the NULL backend, used to try serializing structures to find
 * their size.
 */
static id nullBackend;

/**
 * Custom serializer functions for named structures.
 */
static NSMapTable * serializerFunctions;

/**
 * Custom serializer function for storing NSZones.  NSZones contain function
 * pointers and so should just be thrown away and replaced with the default
 * zone unless a class includes some special handling.
 */
parsed_type_size_t serializeNSZone(char* aName, void* aZone, id <ETSerializerBackend> aBackend)
{
	//Just a placeholder to be used to trigger the reloading function
	[aBackend beginStruct:"_NSZone" withName:aName];
	[aBackend endStruct];
	parsed_type_size_t retVal;
	retVal.size = 1;
	retVal.offset = strlen(@encode(NSZone));
	return retVal;
}

@interface ETSerializer (Private)
- (id) initWithBackend: (Class)aBackend forURL:(NSURL*)anURL;
@end

@implementation ETSerializer
+ (void) initialize
{
	[super initialize];
	/* Null backend we can reuse */
	nullBackend = [[ETSerializerNullBackend alloc] init];
	const NSMapTableValueCallBacks valuecallbacks = {NULL, NULL, NULL};
	serializerFunctions = NSCreateMapTable(STRING_MAP_KEY_CALLBACKS, valuecallbacks, 100);
	/* Custom serializers for known types */
	[self registerSerializer:serializeNSZone forStruct:"_NSZone"];
}
+ (void) registerSerializer:(custom_serializer)aFunction forStruct:(char*)aName
{
	NSMapInsert(serializerFunctions, aName, (void*)aFunction);
}
- (void) setBackend:(id <ETSerializerBackend>)aBackend
{
	ASSIGN(backend, aBackend);
}

+ (ETSerializer*) serializerWithBackend:(Class)aBackendClass forURL:(NSURL*)anURL
{
	ETSerializer * serializer = [[[self alloc] initWithBackend:aBackendClass
		forURL:anURL] autorelease];
	
	return serializer;
}

- (ETDeserializer *) deserializer
{
	id back = [backend deserializer];
	ETDeserializer *deserializer = [ETDeserializer deserializerWithBackend:back];
	[deserializer setBranch:branch];
	return deserializer;
}

- (int) newVersion
{
	return [self setVersion:objectVersion+1];
}

- (int) setVersion:(int)aVersion
{
	objectVersion = aVersion;
	[store startVersion:aVersion inBranch:branch];
	[backend startVersion:aVersion];
	return objectVersion;
}

/** <init /> */
- (id) initWithBackend:(Class)aBackend forURL:(NSURL*)anURL
{
	if(nil == (self = [super init]))
	{
		return nil;
	}
	//TODO: Replace these with NSHashMaps if we aren't fast enough
	unstoredObjects = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 100);
	storedObjects = NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 100);
	branch = @"root";
	objectVersion = -1;

	/* Only works on local files for now */
	if(![anURL isFileURL])
	{
		store = [[ETSerialObjectStdout alloc] init];
	}
	else
	{
		NSFileManager * manager = [NSFileManager defaultManager];
		NSString * path = [anURL path];
		if(![manager fileExistsAtPath:path])
		{
			[manager createDirectoryAtPath:path
									  attributes:nil];
		}
		store = [[ETSerialObjectBundle alloc] init];
		[store setPath:path];
	}
	[self setBackend:[aBackend serializerBackendWithStore:store]];
	return self;
}

- (void) dealloc
{
	[backend release];
	NSFreeHashTable(unstoredObjects);
	NSFreeHashTable(storedObjects);
	[super dealloc];
}
- (id<ETSerializerBackend>) backend
{
	return backend;
}

/**
 * Add an object to the queue of unstored objects if we haven't loaded it yet,
 * or increment its reference count if we have.
 */
- (void) enqueueObject:(id)anObject
{
	if(anObject != nil)
	{
		if(!NSHashGet(storedObjects, anObject) &&
		   !NSHashGet(unstoredObjects, anObject))
		{
			NSHashInsert(unstoredObjects, anObject);
		}
		[backend incrementReferenceCountForObject:COREF_FROM_ID(anObject)];
	}
}

/**
 * Parse simple types and fire off events to the back end serializing them.
 */
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
			return [self storeObjectFromAddress: address withName: name];
		default:
			printf("%c not recognised(%s)\n", type, name);
			return -1;
	}
}

- (size_t) storeObjectFromAddress:(void*) address withName:(char*) name
{
	if(*(id*)address != nil)
	{
		[self enqueueObject:*(id*)address];
	}
	[backend storeObjectReference:COREF_FROM_ID(*(id*)address) withName:name];
	return sizeof(id);
}


/**
 * Consume one character from the type stream.
 */
#define INCREMENT_OFFSET type++; retVal.offset++
/**
 * Parse the body of a structure.  
 */
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

/**
 * Parse the type string for an instance variable and serialize it.  If it is a
 * complex type, store the individual components as well.  Note that this can
 * be called recursively for nested types.
 */
- (parsed_type_size_t) parseType:(const char*) type atAddress:(void*) address withName:(char*) name
{
	parsed_type_size_t  retVal;

	//Initialize members to get rid of gcc warnings.
	retVal.size = 0;
	retVal.offset = 0;

	switch(type[0])
	{
		//Start of a structure
		case '{':
			{
				//NSLog(@"Parsing %s\n", type);
				unsigned int nameEnd = 1;
				unsigned int nameSize = 0;
				type++;
				//Find the name of the structure
				while(type[nameEnd] != '=')
				{
					nameEnd++;
				}
				//Give the length of the string now
				nameSize = nameEnd;
				char structName[nameSize + 1];
				memcpy(structName, type, nameSize);
				structName[nameSize] = '\0';
				//See if there is a custom serializer function registered for
				//this structure type.
				custom_serializer function = NSMapGet(serializerFunctions, structName);
				if(function != NULL)
				{
					retVal = function(name, address, backend);
					break;
				}
				
				[backend beginStruct:structName withName:name];
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
		//Arrays (fixed size)
		case '[':
			{
//printf("Parsing %s\n", type);
				unsigned int elements;
				unsigned int typeOffset = 0;
				//Get the number of array elements:
				type++;
				char * sizeEnd = (char*)type;
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
		//Pointer.  We only handle pointers to structs automatically
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
					custom_serializer function = NSMapGet(serializerFunctions, structName);
					if(function != NULL)
					{
						retVal = function(name, address, backend);
						break;
					}
					else if((int)indirect.size >= 0)
					{
						GUESSWARN(@"WARNING: Guessing that %s in %@ is not an array.  If it is, you need to serialize it manually.", name, currentClass);
						type += nameEnd + 3;
						retVal.offset += nameEnd + 3;
						//NSLog(@"Begin struct pointer");
						PARSE_STRUCT_BODY();
						//NSLog(@"End struct pointer");
						break;
					}
				}
				retVal.size = (unsigned)-1;
				NSLog(@"Unable to serialize %s in %@ (type: %s)", name, currentClass, type);
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
		//Everything else is a simple type, so we can parse it easily.
		default:
			retVal.offset = 1;
			retVal.size = [self storeIntrinsicOfType:type[0] fromAddress:address withName:name];
			if(retVal.size == (unsigned)-1)
			{
				NSLog(@"Unable to serialize %s in %@ (type: %s)", name, currentClass, type);
			}
	}
	return retVal;
}
/**
 * Serialize a specified object, including all instance variables, but not
 * referenced objects.
 */
- (void) serializeObject:(id)anObject named:(char*)aName
{
	//NSLog(@"Starting object %s", aName);
	int lastVersion = -1;
	currentClass = anObject->class_pointer;
	[backend beginObjectWithID:COREF_FROM_ID(anObject)
	                  withName:aName
	                 withClass:currentClass];
	//Loop over instance variables.
	do
	{
		struct objc_ivar_list* ivarlist = currentClass->ivars;
		//NSLog(@"Serializing ivars belonging to class %s", currentClass->name);
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
					//NSLog(@"Serializing ivar: %s in %@", name, anObject);
					if(![anObject serialize:name using:self])
					{
						//TODO: Print the name of the ivar and class if this fails.
						[self parseType:type atAddress:address withName:name];
					}
				}
			}
		}
		//NOTE: This is a bit of a hack, but there's no clean way of handling 
		//it that I can think of

		//Special handling for invocation
		if(strcmp(currentClass->name, "NSInvocation") == 0)
		{
			NSMethodSignature * sig = [anObject methodSignature];
			char name[6] = {'a','r','g','.','\0','\0'};
			//FIXME: Calculate the size sensibly and don't use a horribly insecure stack-buffer
			char buffer[1024];
			[backend storeInt:[sig numberOfArguments] withName:"numberOfArguments"];
			for(unsigned int i=2 ; i<[sig numberOfArguments] ; i++)
			{
				name[4] = i + 060;
				[anObject getArgument:buffer atIndex:i];
				[self parseType:[sig getArgumentTypeAtIndex:i] atAddress:buffer withName:name];
			}
		}
		//Get ivars from superclass as well.
		currentClass = currentClass->super_class;
	}
	while(currentClass != NULL);
	[backend endObject];

	NSHashInsert(storedObjects, anObject);
	NSHashRemove(unstoredObjects, anObject);
}
/**
 * Public version of the object serialization method.  Serializes referenced
 * objects as well.
 */
- (unsigned long long) serializeObject:(id)anObject withName:(NSString*)name
{
	COREF_TABLE_USE
	[self newVersion];
	[self enqueueObject:anObject];
	[self serializeObject:anObject named:(char *)[name UTF8String]];
	while(0 != NSCountHashTable(unstoredObjects))
	{
		NSHashEnumerator e = NSEnumerateHashTable(unstoredObjects);
		id leftoverObject = NSNextHashEnumeratorItem(&e);
		[self serializeObject:leftoverObject named:"?"];
		NSEndHashTableEnumeration(&e);
	}
	[backend flush];
	CORef theId = COREF_FROM_ID(anObject);
	COREF_TABLE_DONE
	return theId;
}
@end
