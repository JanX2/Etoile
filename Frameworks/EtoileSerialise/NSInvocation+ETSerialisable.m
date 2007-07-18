#import <Foundation/Foundation.h>
#import "ETSerialiser.h"

#define SET_SUFFIX(suf) strcpy(suffix, suf); suffix[strlen(suf)] = '\0' 
#define STORE_FIELD(type, name) SET_SUFFIX(#name); [aBackend store ## type:sig[i].name withName:saveName]
void serialiseArgumentInfos(NSArgumentInfo * sig, unsigned int count, char * name, id<ETSerialiserBackend> aBackend)
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

#define LOAD_FIELD(type, field) if(strcmp(name, #field) == 0) { sig->field = *(type*)aBlob; return; }
void deserialiseArgumentInfo(NSArgumentInfo * sig, char * name, void * aBlob)
{
	//Get the element in the array we need
	sig += name[1] - 060;
	//Get the field name
	char * aVariable = name + 3;
	LOAD_FIELD(int, offset);
	LOAD_FIELD(unsigned int, size);
	LOAD_FIELD(unsigned int, align);
	LOAD_FIELD(unsigned int, qual);
	LOAD_FIELD(unsigned char, isReg);
	if(strcmp(name, "type") == 0) 
	{ 
		sig->type = strdup(aBlob); 
	}
}
#define CASE(x) if(strcmp(aVariable, #x) == 0)
@implementation NSMethodSignature (ETSerialisable)
- (BOOL) serialise:(char*)aVariable using:(id<ETSerialiserBackend>)aBackend
{
	CASE(_info)
	{
		serialiseArgumentInfos(_info, _numArgs, aVariable, aBackend);
		return YES;
	}
	return [super serialise:aVariable using:aBackend];
}
- (BOOL) deserialise:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion 
{
	CASE(_numArgs)
	{
		//Allocate space for _info when we know how much space we need
		_info = calloc(*(int*)aBlob, sizeof(NSArgumentInfo));
	}
	CASE(_info)
	{
		NSAssert(_numArgs, @"Can't deserialise _info before _numArgs in NSMethodSignature");
		deserialiseArgumentInfo(_info, aVariable + 5, aBlob);
	}
	return [super deserialise:aVariable fromPointer:aBlob version:aVersion];
}
@end

static void * discardRetVal = NULL;
static int discardRetValSize = 0;
@implementation NSInvocation (ETSerialisable)
- (BOOL) serialise:(char*)aVariable using:(id<ETSerialiserBackend>)aBackend
{
	CASE(_info)
	{
		serialiseArgumentInfos(_info, 1, aVariable, aBackend);
		return YES;
	}
	CASE(_retval)
	{
		[aBackend storeInt:0 withName:aVariable];
		return YES;
	}
			
	return [super serialise:aVariable using:aBackend];
}
- (BOOL) deserialise:(char*)aVariable fromPointer:(void*)aBlob version:(int)aVersion 
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
		_retval = discardRetVal;
		return YES;
	}
	return [super deserialise:aVariable fromPointer:aBlob version:aVersion];
}
@end
