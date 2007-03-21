#include <stdlib.h>
#include <objc/objc.h>
#include <objc/objc-api.h>
#include <objc/Object.h>
//#import <Foundation/Foundation.h>

//Must be set to the size along which things are aligned.
const unsigned int WORD_SIZE = sizeof(int);

@interface TestClass : Object {
	int anInteger;
	BOOL aBool;
	float aFloat;
	double aDouble;
	struct
	{
		BOOL boolInStruct;
		int intInStruct;
	} aStruct;
	id anObject;
	int anArray[3];
}
@end
@implementation TestClass

- (id) init
{
	self = [super init];
	if(self==nil)
	{
		printf("Numpty\n");
		return nil;
	}
	anInteger = 10;
	aBool = YES;
	aFloat = 12.345f;
	aDouble = 67.890;
	aStruct.intInStruct = 12;
	aStruct.boolInStruct = YES;
	anObject = [Object new];
	anArray[0] = 0;
	anArray[1] = 1;
	anArray[2] = 2;
	return self;
}
@end

void storeObject(id anObject, char* name);

size_t storeIntrinsic(char type, void* address, char* name)
{
	//printf("Storing %c\n",type);
	switch(type)
	{
		case '#':
			printf("Class %s = [%s class];\n", name, ((id)address)->class_pointer->name);
			return sizeof(id);
		case 'i':
			printf("int %s=%d;\n",name,*(int*)address); 
			return sizeof(int);
		case 'c':
			printf("char %s=",name);
			return sizeof(unsigned char);
		case 'C':
			printf("unsigned char %s=",name);
			return sizeof(unsigned char);
		case 'f':
			printf("float %s=%hf;\n",name,*(float*)address); 
			return sizeof(double);
		case 'd':
			printf("double %s=%f;\n",name,*(double*)address); 
			return sizeof(double);
		case '@':
			storeObject(*(id*)address, name);
			return sizeof(id);
		default:
			printf("%c not recognised.\n", type);
			return 0;
	}
}

size_t parseType(char* type, void* address, char*name)
{
	//printf("Parsing type (%s): %s\n",name,type);
	switch(type[0])
	{
		case '{':
			{
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
				structName = malloc(nameSize);
				structName[nameSize] = 0;
				//printf("Parsing struct...\n");
				memcpy(structName, type+1, nameSize);
				printf("struct %s {\n",structName);
				free(structName);
				//First char after the name
				type = type + nameEnd + 1;
				while(*type != '}')
				{
					size_t substructSize;
					//Skip over the name of struct members.  We don't care about them.
					if(*type = '"')
					{
						//Skip open "
						type++;
						//Skip name
						while(*type != '"')
						{
							type++;
						}
						//Skip close "
						type++;
					}
					substructSize = parseType(type,address,"?");
					if(substructSize < WORD_SIZE)
					{
						substructSize = WORD_SIZE;
					}
					address += substructSize;
					structSize += substructSize;
					type++;
				}
				printf("}\n");
				return structSize;
			}
		case '[':
			{
				unsigned int elements;
				size_t elementSize;
				char elementType;
				sscanf(type, "[%d%c",&elements,&elementType);
				printf("array [%u] {\n",elements);
				for(unsigned int i=0 ; i<elements ; i++)
				{
					elementSize = storeIntrinsic(elementType, address, "?");
					address += elementSize;
				}
				printf("}\n");
				return elementSize * elements;
			}
		default:
			return storeIntrinsic(type[0], address, name);
	}
	
}



void storeObject(id anObject, char* name)
{
	if(anObject == nil || anObject->class_pointer == nil)
	{
		printf("%s nil",name);
		return;
	}
	printf("%s %s {\n", anObject->class_pointer->name, name);
	struct objc_ivar_list* ivarlist = anObject->class_pointer->ivars;
	int i;
	for(i=0 ; i<ivarlist->ivar_count ; i++)
	{
		void * address = ((char*)anObject + (ivarlist->ivar_list[i].ivar_offset));
		char * name = ivarlist->ivar_list[i].ivar_name;
		char * type = ivarlist->ivar_list[i].ivar_type;
		parseType(type, address, name);
	}
	printf("}\n");
}

int main(void)
{
	id foo = [TestClass new];
	storeObject(foo,"foo");
	return 0;
}
