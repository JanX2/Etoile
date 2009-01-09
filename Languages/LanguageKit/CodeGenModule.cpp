#include "CodeGenModule.h"
#include "CodeGenBlock.h"
#include "LLVMCodeGen.h"

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
#include <iostream>
#include <fstream>

namespace llvm 
{
	// Flag used to indicate whether exception handling stuff should be emitted.
	extern bool ExceptionHandling;
}

// A copy of the Small Int message module, used when static compiling.
static Module *SmallIntMessages = NULL;

// Remove unrequired box-then-unbox pass.
FunctionPass *createUnboxPass(void);

Constant *CodeGenModule::MakeConstantString(const std::string &Str,
                                            const std::string &Name,
                                            unsigned GEPs)
{
	Constant * ConstStr = ConstantArray::get(Str);
	ConstStr = new GlobalVariable(ConstStr->getType(), true,
		GlobalValue::InternalLinkage, ConstStr, Name, TheModule);
	return ConstantExpr::getGetElementPtr(ConstStr, Zeros, GEPs);
}

void CodeGenModule::CreateClassPointerGlobal(const char *className, const char *globalName)
{
	// Create the global
	Value *global = new GlobalVariable(IdTy, false,
			llvm::GlobalValue::InternalLinkage, ConstantPointerNull::get(IdTy),
			globalName, TheModule);

	// Initialise it in the module load function
	InitialiseBuilder.CreateStore(InitialiseBuilder.CreateBitCast(
				Runtime->LookupClass(InitialiseBuilder,
					MakeConstantString(className)), IdTy), global);
}

CodeGenModule::CodeGenModule(const char *ModuleName, bool jit) 
{
	// When we JIT code, we put the Small Int message functions inside the
	// module, to allow them to be inlined by module passes.  When static
	// compiling, we reference them externally and let the link-time optimiser
	// inline them.
	if (jit)
	{
		TheModule = 
			ParseBitcodeFile(MemoryBuffer::getFile(MsgSendSmallIntFilename));
		SmallIntModule = TheModule;
	}
	else
	{
		if (NULL == SmallIntMessages)
		{
			SmallIntMessages = ParseBitcodeFile(
					MemoryBuffer::getFile(MsgSendSmallIntFilename));
		}
		TheModule = new Module(ModuleName);
		SmallIntModule = SmallIntMessages;
	}
	std::vector<const llvm::Type*> VoidArgs;
	LiteralInitFunction = llvm::Function::Create(
		llvm::FunctionType::get(llvm::Type::VoidTy, VoidArgs, false),
		llvm::GlobalValue::ExternalLinkage, string(".languagekit_constants:") +
		ModuleName, TheModule);
	BasicBlock *EntryBB = 
		llvm::BasicBlock::Create("entry", LiteralInitFunction);
	InitialiseBuilder.SetInsertPoint(EntryBB);

	Runtime = CreateObjCRuntime(*TheModule, IntTy,
			IntegerType::get(sizeof(long) * 8));
	// Store the class to be used for block closures in a global
	CreateClassPointerGlobal("StackBlockClosure", ".smalltalk_block_stack_class");
	CreateClassPointerGlobal("StackContext", ".smalltalk_context_stack_class");
	CreateClassPointerGlobal("RetainedStackContext", ".smalltalk_context_retained_class");
	CreateClassPointerGlobal("Symbol", ".smalltalk_symbol_class");
	CreateClassPointerGlobal("NSValue", ".smalltalk_nsvalue_class");
}

void CodeGenModule::BeginClass(const char *Class,
                               const char *Super,
                               const char ** cVarNames,
                               const char ** cVarTypes,
                               const char ** iVarNames,
                               const char ** iVarTypes,
                               int *iVarOffsets,
                               int SuperclassSize) 
{
	ClassName = string(Class);
	SuperClassName = string(Super);
	CategoryName = "";
	InstanceMethodNames.clear();
	InstanceMethodTypes.clear();
	ClassMethodNames.clear();
	ClassMethodTypes.clear();
	IvarNames.clear();
	while (*iVarNames)
	{
		IvarNames.push_back(*iVarNames);
		iVarNames++;
	}
	IvarTypes.clear();
	while (*iVarTypes)
	{
		IvarTypes.push_back(*iVarTypes);
		iVarTypes++;
	}
	IvarOffsets.clear();
	while (*iVarOffsets)
	{
		IvarOffsets.push_back(*iVarOffsets);
		iVarOffsets++;
	}
	SmallVector<string, 8> cvarnames, cvartypes;
	while(*cVarNames)
	{
		cvarnames.push_back(*cVarNames);
		cvartypes.push_back(*cVarTypes);
		cVarTypes++;
		cVarNames++;
	}
	Runtime->DefineClassVariables(ClassName, cvarnames, cvartypes);
	
	InstanceSize = SuperclassSize + sizeof(void*) * IvarNames.size();
	CurrentClassTy = IdTy;
}

void CodeGenModule::EndClass(void)
{
	Runtime->GenerateClass(ClassName.c_str(), SuperClassName.c_str(),
		InstanceSize, IvarNames, IvarTypes, IvarOffsets, InstanceMethodNames,
		InstanceMethodTypes, ClassMethodNames, ClassMethodTypes, Protocols);
}

void CodeGenModule::BeginCategory(const char *Class, const char *Category)
{
	ClassName = string(Class);
	SuperClassName = "";
	CategoryName = string(CategoryName); 
	InstanceMethodNames.clear();
	InstanceMethodTypes.clear();
	IvarNames.clear();
	CurrentClassTy = IdTy;
}

void CodeGenModule::EndCategory(void)
{
	Runtime->GenerateCategory(ClassName.c_str(), CategoryName.c_str(),
		InstanceMethodNames, InstanceMethodTypes, ClassMethodNames,
		ClassMethodTypes, Protocols);
}

CodeGenMethod::CodeGenMethod(CodeGenModule *Mod,
                             const char *MethodName,
                             const char *MethodTypes,
                             int locals,
                             bool isClass)
                             : CodeGenLexicalScope(Mod) 
{
	// Generate the method function
	bool isSRet;
	FunctionType *MethodTy = LLVMFunctionTypeFromString(MethodTypes, isSRet);
	unsigned argc = MethodTy->getNumParams() - 2;
	const Type *argTypes[argc];
	FunctionType::param_iterator arg = MethodTy->param_begin();
	++arg; ++arg;
	for (unsigned i=0 ; i<argc ; ++i)
	{
		argTypes[i] = MethodTy->getParamType(i+2);
	}


	CurrentFunction = CGM->getRuntime()->MethodPreamble(CGM->getClassName(),
		CGM->getCategoryName(), MethodName, MethodTy->getReturnType(),
		CGM->getCurrentClassTy(), argTypes, argc, isClass, isSRet);

	InitialiseFunction(Args, Locals, locals, MethodTypes);
}

void CodeGenModule::BeginInstanceMethod(const char *MethodName,
                                        const char *MethodTypes,
                                        int locals)
{
	// Log the method name and types so that we can use it to set up the class
	// structure.
	InstanceMethodNames.push_back(MethodName);
	InstanceMethodTypes.push_back(MethodTypes);
	inClassMethod = false;
	assert(ScopeStack.empty()
		&& "Creating a method inside something is not sensible");
	ScopeStack.push_back(
		new CodeGenMethod(this, MethodName, MethodTypes, locals));
}

void CodeGenModule::BeginClassMethod(const char *MethodName,
                                     const char *MethodTypes,
                                     int locals)
{
	// Log the method name and types so that we can use it to set up the class
	// structure.
	ClassMethodNames.push_back(MethodName);
	ClassMethodTypes.push_back(MethodTypes);
	assert(ScopeStack.empty() 
		&& "Creating a method inside something is not sensible");
	ScopeStack.push_back(
		new CodeGenMethod(this, MethodName, MethodTypes, locals, true));
	inClassMethod = true;
}

/*
void CodeGenModule::BeginFreestandingMethod(const char *MethodName, const char *MethodTypes, int locals)
{
  assert(ScopeStack.empty() 
		  && "Creating a method inside something is not sensible");
  inClassMethod = false;
  string name = string("Freestanding_Method") + MethodName;
  ScopeStack.push_back(
		  new CodeGenMethod(this, name, MethodTypes, locals, true));
}
*/

void CodeGenModule::EndMethod()
{
	//assert(isa<CodeGenMethod>(ScopeStack.back()));
	ScopeStack.back()->EndScope();
	delete ScopeStack.back();
	ScopeStack.pop_back();
}

void CodeGenModule::BeginBlock(unsigned args, unsigned locals)
{
	ScopeStack.push_back(new CodeGenBlock(args, locals, ScopeStack.back(),
		this));
}

void CodeGenModule::SetBlockReturn(Value *value)
{
	((CodeGenBlock*)ScopeStack.back())->SetBlockReturn(value);
}

Value *CodeGenModule::EndBlock(void)
{
	CodeGenBlock *block = (CodeGenBlock*)(ScopeStack.back());
	ScopeStack.pop_back();
	block->EndBlock();
	return block->Block;
}

Value *CodeGenModule::StringConstant(const char *value)
{
	return Runtime->GenerateConstantString(value, strlen(value));
}

Value *CodeGenModule::IntConstant(const char *value)
{
	errno = 0;
	long long val = strtoll(value, NULL, 10);
	intptr_t ptrVal = (val << 1);
	if ((0 == val && errno == EINVAL) || ((ptrVal >> 1) != val))
	{
		//FIXME: Promote to BigInt
		assert(false && "BigInt constants not yet implemented.");
	}
	ptrVal |= 1;
	Constant *Val = ConstantInt::get(IntPtrTy, ptrVal);
	Val = ConstantExpr::getIntToPtr(Val, IdTy);
	Val->setName("SmallIntConstant");
	return Val;
}

void CodeGenModule::writeBitcodeToFile(char* filename, bool isAsm)
{
	InitialiseBuilder.CreateRetVoid();
	// Set the module init function to be a global ctor
	llvm::Function *init = Runtime->ModuleInitFunction();
	llvm::StructType* CtorStructTy = llvm::StructType::get(llvm::Type::Int32Ty,
		init->getType(), NULL);

	std::vector<llvm::Constant*> Ctors;

	std::vector<llvm::Constant*> S;
	S.push_back(llvm::ConstantInt::get(llvm::Type::Int32Ty, 0xffff, false));
	S.push_back(LiteralInitFunction);
	Ctors.push_back(llvm::ConstantStruct::get(CtorStructTy, S));
	// Add the constant initialisation function
	S.clear();
	S.push_back(llvm::ConstantInt::get(llvm::Type::Int32Ty, 0xffff, false));
	S.push_back(init);
	Ctors.push_back(llvm::ConstantStruct::get(CtorStructTy, S));

	llvm::ArrayType *AT = llvm::ArrayType::get(CtorStructTy, Ctors.size());
	new llvm::GlobalVariable(AT, false, llvm::GlobalValue::AppendingLinkage,
			llvm::ConstantArray::get(AT, Ctors), "llvm.global_ctors", TheModule);

	PassManager pm;
	pm.add(createVerifierPass());
	pm.add(new TargetData(TheModule));
	pm.run(*TheModule);
	DUMP(TheModule);
	std::filebuf fb;
	fb.open (filename, std::ios::out);
	std::ostream os(&fb);
	WriteBitcodeToFile(TheModule, os);
	fb.close();
}

void CodeGenModule::StoreClassVar(const char *cVarName, Value *value)
{
	getCurrentScope()->StoreValueInClassVariable(ClassName, cVarName, value);
}
Value *CodeGenModule::LoadClassVar(const char *cVarName)
{
	return getCurrentScope()->LoadClassVariable(ClassName, cVarName);
}

static ExecutionEngine *EE = NULL;


void CodeGenModule::compile(void)
{
	InitialiseBuilder.CreateRetVoid();
	llvm::Function *init = Runtime->ModuleInitFunction();
	// Make the init function external so the optimisations won't remove it.
	init->setLinkage(GlobalValue::ExternalLinkage);
	DUMP(TheModule);
	LOG("\n\n\n Optimises to:\n\n\n");
	PassManager pm;
	pm.add(createVerifierPass());
	pm.add(new TargetData(TheModule));
	pm.add(createScalarReplAggregatesPass());
	pm.add(createPromoteMemoryToRegisterPass());
	pm.add(createAggressiveDCEPass());
	pm.add(createFunctionInliningPass());
	pm.add(createIPConstantPropagationPass());
	pm.add(createSimplifyLibCallsPass());
	pm.add(createPredicateSimplifierPass());
	pm.add(createCondPropagationPass());
	pm.add(createInstructionCombiningPass());
	pm.add(createTailDuplicationPass());
	pm.add(createStripDeadPrototypesPass());
//	pm.add(createUnboxPass());
	pm.add(createAggressiveDCEPass());
	//pm.add(createCFGSimplificationPass());
	pm.run(*TheModule);
	DUMP(TheModule);
	if (NULL == EE)
	{
		ExceptionHandling = true;
		EE = ExecutionEngine::create(TheModule);
	}
	else
	{
		EE->addModuleProvider(new ExistingModuleProvider(TheModule));
	}
	LOG("Compiling...\n");
	EE->runStaticConstructorsDestructors(TheModule, false);
	void(*f)(void) = (void(*)(void))EE->getPointerToFunction(init);
	LOG("Loading %x...\n", (unsigned)(unsigned long)f);
	f();
	((void(*)(void))EE->getPointerToFunction(LiteralInitFunction))();
	LOG("Loaded.\n");
}
