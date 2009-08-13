#include "CodeGenModule.h"

#include "llvm/LinkAllPasses.h"
#include <llvm/Bitcode/ReaderWriter.h>
#include <llvm/Constants.h>
#include <llvm/DerivedTypes.h>
#include <llvm/ExecutionEngine/ExecutionEngine.h>
#include <llvm/ExecutionEngine/GenericValue.h>
#include <llvm/GlobalVariable.h>
#include <llvm/Module.h>
#include <llvm/ModuleProvider.h>
#include <llvm/PassManager.h>
#include "llvm/Analysis/Verifier.h"
#include <llvm/Support/IRBuilder.h>
#include <llvm/Support/MemoryBuffer.h>
#include <llvm/Target/TargetData.h>

#include <string>
#include <algorithm>
#include <errno.h>

#include "ABI.h"

// C++ Implementation
using namespace llvm;
using std::string;

void SkipTypeQualifiers(const char **typestr)
{
	if (*typestr == NULL) return;
	while(**typestr == 'V' || **typestr == 'r')
	{
		(*typestr)++;
	}
}
PointerType *IdTy;
const Type *IntTy;
const Type *IntPtrTy;
const Type *SelTy;
const PointerType *IMPTy;
const char *MsgSendSmallIntFilename;
Constant *Zeros[2];


static const Type *LLVMTypeFromString2(LLVMContext &Context, const char ** typestr)
{
	// FIXME: Other function type qualifiers
	SkipTypeQualifiers(typestr);
	switch(**typestr)
	{
		case 'c':
		case 'C':
			(*typestr)++;
			return IntegerType::get(sizeof(char) * 8);
		case 's':
		case 'S':
			(*typestr)++;
			return IntegerType::get(sizeof(short) * 8);
		case 'i':
		case 'I':
			(*typestr)++;
			return IntegerType::get(sizeof(int) * 8);
		case 'l':
		case 'L':
			(*typestr)++;
			return IntegerType::get(sizeof(long) * 8);
		case 'q':
		case 'Q':
			(*typestr)++;
			return IntegerType::get(sizeof(long long) * 8);
		case 'f':
			(*typestr)++;
			return Type::FloatTy;
		case 'd':
			(*typestr)++;
			return Type::DoubleTy;
		case 'B':
			(*typestr)++;
			return IntegerType::get(sizeof(bool) * 8);
		case '^':
		{
			(*typestr)++;
			const Type *pointeeType = LLVMTypeFromString2(Context, typestr);
			if (pointeeType == Type::VoidTy)
			{
				pointeeType = Type::Int8Ty;
			}
			return PointerType::getUnqual(pointeeType);
		}
			//FIXME:
		case ':':
		case '@':
		case '#':
		case '*':
			(*typestr)++;
			return PointerType::getUnqual(Type::Int8Ty);
		case 'v':
			(*typestr)++;
			return Type::VoidTy;
		case '{':
		{
			while (**typestr != '=') { 
				(*typestr)++; }
			(*typestr)++;
			std::vector<const Type*> types;
			while (**typestr != '}')
			{
				// FIXME: Doesn't work with nested structs
				types.push_back(LLVMTypeFromString2(Context, typestr));
			}
			(*typestr)++;
			return StructType::get(Context, types);
		}
		default:
		//FIXME: Structure and array types
			return NULL;
	}
}

const Type *CodeGenModule::LLVMTypeFromString(const char * typestr)
{
	return LLVMTypeFromString2(Context, &typestr);
}

#define NEXT(typestr) \
	while (!isdigit(*typestr)) { typestr++; }\
	while (isdigit(*typestr)) { typestr++; }

static void const countIntsAndFloats(const Type *ty,
                                     unsigned &ints,
                                     unsigned &floats)
{
	if(ty->getTypeID() == Type::VoidTyID)
	{
		return;
	}
	if (ty->isInteger())
	{
		ints++;
	}
	else if (ty->isFloatingPoint())
	{
		floats++;
	}
	// Assume that pointers count as integers for now.
	else if(ty->getTypeID() == Type::PointerTyID)
	{
		ints++;
	}
	else if (ty->isAggregateType())
	{
		for (Type::subtype_iterator i=ty->subtype_begin(), end=ty->subtype_end()
		     ; i!=end ; ++i)
		{
			countIntsAndFloats(i->get(), ints, floats);
		}
	}
	else
	{
		ty->dump();
		assert(0 && "Unrecgnised type.");
	}
}

/**
 * Determines whether a specific structure should be returned on the stack.
 * 
 * Note that this is not expressive enough for all ABIs - we will eventually
 * need to have it handle complex and structure types differently.
 */
static inline bool shouldReturnValueOnStack(const Type *sTy)
{
	unsigned ints = 0;
	unsigned floats = 0;
	if (isa<StructType>(sTy))
	{
		countIntsAndFloats(sTy, ints, floats);
		LOG("Found %d ints and %d floats in ", ints, floats);
		DUMP(sTy);
		if (ints > MAX_INTS_IN_REGISTERS || floats > MAX_FLOATS_IN_REGISTERS)
		{
			LOG("Returning value on stack\n");
			return true;
		}
	}
	return false;
}

FunctionType *CodeGenModule::LLVMFunctionTypeFromString(const char *typestr, bool &isSRet,
		const Type *&realRetTy)
{
	std::vector<const Type*> ArgTypes;
	if (NULL == typestr)
	{
		ArgTypes.push_back(LLVMTypeFromString("@"));
		ArgTypes.push_back(LLVMTypeFromString(":"));
		return FunctionType::get(LLVMTypeFromString("@"), ArgTypes, true);
	}
	// Function encodings look like this:
	// v12@0:4@8 - void f(id, SEL, id)
	const Type * ReturnTy = LLVMTypeFromString(typestr);
	isSRet = shouldReturnValueOnStack(ReturnTy);
	
	realRetTy = ReturnTy;
	if (SMALL_FLOAT_STRUCTS_ON_STACK && isa<StructType>(ReturnTy)
		&&                              
		ReturnTy == StructType::get(Context, Type::FloatTy, Type::FloatTy, NULL))
	{   
		isSRet = false;
		ReturnTy = Type::Int64Ty;
	}
	NEXT(typestr);
	while(*typestr)
	{
		ArgTypes.push_back(LLVMTypeFromString(typestr));
		NEXT(typestr);
	}
	return FunctionType::get(ReturnTy, ArgTypes, false);
}

CGObjCRuntime::~CGObjCRuntime() {}
