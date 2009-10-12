#import <Foundation/Foundation.h>
#import "ETSerializer.h"
#import "ETSerializerBackend.h"

#ifndef NSArgumentInfo
typedef struct  {
  int           offset;
  unsigned      size;
  const char    *type;
  const char    *qtype;
  unsigned      align;
  unsigned      qual;
  BOOL          isReg;
} NSArgumentInfo;
#endif 

#define SET_SUFFIX(suf) strcpy(suffix, suf); suffix[strlen(suf)] = '\0' 
#define STORE_FIELD(type, name) SET_SUFFIX(#name); [aBackend store ## type:sig[i].name withName:saveName];
/**
 * Function for storing NSArgumentInfo structures.  Not registered as a custom
 * serializer since GNUstep tends to use dynamic arrays of these, losing the
 * run time type information.
 */
void serializeArgumentInfos(NSArgumentInfo * sig, unsigned int count, char * name, id<ETSerializerBackend> aBackend)
{
	int nameLen = strlen(name);
	//Enough space for name.n.field
	char saveName[nameLen + 10];
	memcpy(saveName, name, nameLen);
	saveName[nameLen] = '.';
	saveName[nameLen+2] = '.';
	int prefixOffset = nameLen + 1;
	char * suffix = saveName + nameLen + 3;
	for(unsigned int i=0 ; i<count ; i++)
	{
		//Ugly hack.
		saveName[prefixOffset] = (char)(i + 060);
		STORE_FIELD(Int, offset);
		STORE_FIELD(UnsignedInt, size);
		STORE_FIELD(CString, type);
		STORE_FIELD(UnsignedInt, align);
		STORE_FIELD(UnsignedInt, qual);
		STORE_FIELD(UnsignedChar, isReg);
	}
}

#define CASE(x) if(strcmp(aVariable, #x) == 0)
#define LOAD_FIELD(type, field) CASE(field) { sig->field = *(type*)aBlob; return; }
/**
 * Deserializer function for NSArgumentInfo structures.
 */
void deserializeArgumentInfo(NSArgumentInfo * sig, char * name, void * aBlob)
{
	//Get the element in the array we need (same ugly hack in reverse)
	sig += name[1] - 060;
	//Get the field name
	char * aVariable = name + 3;
	LOAD_FIELD(int, offset);
	LOAD_FIELD(unsigned int, size);
	LOAD_FIELD(unsigned int, align);
	LOAD_FIELD(unsigned int, qual);
	LOAD_FIELD(unsigned char, isReg);
	CASE(type)
	{ 
		sig->type = strdup(aBlob); 
	}
}
/**
 * Category for correctly serializing NSMethodSignature objects.
 */
@implementation NSMethodSignature (ETSerializable)
/**
 * Store the array of argument info structures.
 */
- (BOOL) serialize:(char*)aVariable using:(ETSerializer*)aSerializer
{
	CASE(_info)
	{
		serializeArgumentInfos(_info, _numArgs + 1, aVariable, [aSerializer backend]);
		return YES;
	}
	return [super serialize:aVariable using:aSerializer];
}
/**
 * Reload the _info array.  Allocates space for it wgen the number of elements is known.
 */
- (void*) deserialize:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion 
{
	CASE(_numArgs)
	{
		//Allocate space for _info when we know how much space we need
		_info = calloc(*(int*)aBlob + 1, sizeof(NSArgumentInfo));
	}
	if(strncmp("_info", aVariable, 5) == 0)
	{
		NSAssert(_numArgs, @"Can't deserialize _info before _numArgs in NSMethodSignature");
		deserializeArgumentInfo(_info, aVariable + 5, aBlob);
	}
	return [super deserialize:aVariable fromPointer:aBlob version:aVersion];
}
@end

static void * discardRetVal = NULL;
static int discardRetValSize = 0;
@implementation NSInvocation (ETSerializable)
/**
 * Most of this method is responsible for discarding instance variables that
 * will be re-created after deserialization.  _info, _retval and _cframe fall
 * into this category.
 */
- (BOOL) serialize:(char*)aVariable using:(ETSerializer*)aSerializer
{
	CASE(_info)
	{
		//Throw away _info.  We re-generate this from the NSArgumentInfo object
		//when we deserialize.
		return YES;
	}
	CASE(_retval)
	{
		//Don't store retval, but use this as a trigger to re-create it.
		[[aSerializer backend] storeInt:0 withName:aVariable];
		return YES;
	}
	CASE(_cframe)
	{
		//Save the arguments later
		return YES;
	}
	return [super serialize:aVariable using:aSerializer];
}
/**
 * Point _retval at a static buffer (we discard the return value unless someone
 * explicitly requests it after deserialization).
 */
- (void*) deserialize:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion 
{
	if(discardRetVal == NULL)
	{
		discardRetVal = malloc(1024);
		discardRetValSize = 1024;
	}
	CASE(_retval)
	{
		//TODO: We should check that this is big enough, but 
		//if you're returning more than 1KB on the stack you're doing something
		//deeply wrong so I don't mind breaking your code for now.
		//FIXME: This should be done in the custom deserializer, which knows
		//how big the retval is.
		_retval = discardRetVal;
		return MANUAL_DESERIALIZE;
	}
	return [super deserialize:aVariable fromPointer:aBlob version:aVersion];
}
@end
