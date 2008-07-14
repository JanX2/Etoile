#include "CGObjCRuntime.h"

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

// C++ Implementation
using namespace llvm;
using std::string;
using clang::CodeGen::CGObjCRuntime;
extern "C" {
  int DEBUG_DUMP_MODULES = 0;
}
// Debugging macros:
#define DUMP(x) do { if (DEBUG_DUMP_MODULES) x->dump(); } while(0)
#define DUMPT(x) DUMP((x->getType()))
#define LOG(x,...) do { if (DEBUG_DUMP_MODULES) fprintf(stderr, x,##__VA_ARGS__); } while(0)

//TODO: Static constructors should be moved into a function called from the
//Objective-C code's +initialize method

// Object pointers are opaque.
PointerType *IdTy;
const Type *IntTy;
const Type *IntPtrTy;
const Type *SelTy;
const PointerType *IMPTy;
const char *MsgSendSmallIntFilename;

static void SkipTypeQualifiers(const char **typestr) {
  if (*typestr == NULL) return;
  while(**typestr == 'V' || **typestr == 'r')
  {
    (*typestr)++;
  }
}


static const Type *LLVMTypeFromString(const char * typestr) {
  // FIXME: Other function type qualifiers
  SkipTypeQualifiers(&typestr);
  switch(*typestr) {
    case 'c':
    case 'C':
      return IntegerType::get(sizeof(char) * 8);
    case 's':
    case 'S':
      return IntegerType::get(sizeof(short) * 8);
    case 'i':
    case 'I':
      return IntegerType::get(sizeof(int) * 8);
    case 'l':
    case 'L':
      return IntegerType::get(sizeof(long) * 8);
    case 'q':
    case 'Q':
      return IntegerType::get(sizeof(long long) * 8);
    case 'f':
      return Type::FloatTy;
    case 'd':
      return Type::DoubleTy;
    case 'B':
      return IntegerType::get(sizeof(bool) * 8);
    case '^': {
      const Type *pointeeType = LLVMTypeFromString(typestr+1);
      if (pointeeType == Type::VoidTy) {
        pointeeType = Type::Int8Ty;
      }
      return PointerType::getUnqual(pointeeType);
    }
      //FIXME:
    case ':':
    case '@':
    case '#':
    case '*':
      return PointerType::getUnqual(Type::Int8Ty);
    case 'v':
      return Type::VoidTy;
    default:
    //FIXME: Structure and array types
      return NULL;
  }
}

#define NEXT(typestr) \
  while (!isdigit(*typestr)) { typestr++; }\
  while (isdigit(*typestr)) { typestr++; }
static FunctionType *LLVMFunctionTypeFromString(const char *typestr) {
  std::vector<const Type*> ArgTypes;
  if (NULL == typestr) {
    ArgTypes.push_back(LLVMTypeFromString("@"));
    ArgTypes.push_back(LLVMTypeFromString(":"));
    return FunctionType::get(LLVMTypeFromString("@"), ArgTypes, true);
  }
  // Function encodings look like this:
  // v12@0:4@8 - void f(id, SEL, id)
  const Type * ReturnTy = LLVMTypeFromString(typestr);
  NEXT(typestr);
  while(*typestr) {
    ArgTypes.push_back(LLVMTypeFromString(typestr));
    NEXT(typestr);
  }
  return FunctionType::get(ReturnTy, ArgTypes, false);
}

Constant *Zeros[2];

class CodeGenBlock {
  SmallVector<Value*, 8> Args;
  const Type *BlockTy;
  Module *TheModule;
  Value *BlockSelf;
public:
  Value *Block;
  Function *BlockFn;
  IRBuilder *Builder;

  CodeGenBlock(Module *M, int args, int locals, Value **promoted, int count,
      IRBuilder *MethodBuilder) {
    TheModule = M;
    const Type *IdPtrTy = PointerType::getUnqual(IdTy);
    BlockTy = StructType::get(
        IdTy,                          // 0 - isa.
        IMPTy,                         // 1 - Function pointer.
        ArrayType::get(IdPtrTy, 5),    // 2 - Bound variables.
        ArrayType::get(IdTy, 5),       // 3 - Promoted variables.
        Type::Int32Ty,                 // 4 - Number of args.
        IdTy,                          // 5 - Return value.
        Type::Int8Ty,                  // 6 - Start of jump buffer.
        (void*)0);
    BlockTy = PointerType::getUnqual(BlockTy);
    std::vector<const Type*> argTy;
    argTy.push_back(BlockTy);
    // FIXME: Broken on Etoile runtime.
    argTy.push_back(SelTy);
    for (int i=0 ; i<args ; ++i) {
      argTy.push_back(IdTy);
    }
    FunctionType *BlockFunctionTy = FunctionType::get(IdTy, argTy, false);

    // Create the block object
    Function *BlockCreate =
      cast<Function>(TheModule->getOrInsertFunction("NewBlock", IdTy,
            (void*)0));
    Block = MethodBuilder->CreateCall(BlockCreate);
    Block = MethodBuilder->CreateBitCast(Block, BlockTy);
    // Create the block function
    BlockFn = Function::Create(BlockFunctionTy, GlobalValue::InternalLinkage,
        "BlockFunction", TheModule);
    BasicBlock * EntryBB = llvm::BasicBlock::Create("entry", BlockFn);
    Builder = new IRBuilder(EntryBB);

    // Set up the arguments
    llvm::Function::arg_iterator AI = BlockFn->arg_begin();
    BlockSelf = Builder->CreateAlloca(BlockTy, 0, "block_self");
    Builder->CreateStore(AI, BlockSelf);
    ++AI; ++AI;
    for(Function::arg_iterator end = BlockFn->arg_end() ; AI != end ;
        ++AI) {
      Value * arg = Builder->CreateAlloca(AI->getType(), 0, "arg");
      Args.push_back(arg);
      // Initialise the local to nil
      Builder->CreateStore(AI, arg);
    }
    MethodBuilder->CreateStore(ConstantInt::get(Type::Int32Ty, args),
        MethodBuilder->CreateStructGEP(Block, 4));

    // Store the block function in the object
    Value *FunctionPtr = MethodBuilder->CreateStructGEP(Block, 1);
    MethodBuilder->CreateStore(MethodBuilder->CreateBitCast(BlockFn, IMPTy),
        FunctionPtr);
    
    //FIXME: I keep calling these promoted when I mean bound.  Change all of
    //the variable / method names to reflect this.

    //Store the promoted vars in the block
    Value *promotedArray = MethodBuilder->CreateStructGEP(Block, 2);
    // FIXME: Reference self, promote self
    for (int i=1 ; i<count ; i++) {
      MethodBuilder->CreateStore(promoted[i], 
          MethodBuilder->CreateStructGEP(promotedArray, i));
    }
  }

  Value *LoadArgumentAtIndex(unsigned index) {
    return Builder->CreateLoad(Args[index]);
  }

  void SetReturn(Value* RetVal) {
    const Type *RetTy = BlockFn->getReturnType();
    if (RetVal == 0) {
        Builder->CreateRet(UndefValue::get(BlockFn->getReturnType()));
    } else {
      if (RetVal->getType() != RetTy) {
        RetVal = Builder->CreateBitCast(RetVal, RetTy);
      }
      Builder->CreateRet(RetVal);
    }
  }

  Value *LoadBlockVar(unsigned index, unsigned offset) {
    Value *block = Builder->CreateLoad(BlockSelf);
    // Object array
    Value *object = Builder->CreateStructGEP(block, 2);
    object = Builder->CreateStructGEP(object, index);
    object = Builder->CreateLoad(object);
    if (offset > 0)
    {
      Value *addr = Builder->CreatePtrToInt(object, IntTy);
      addr = Builder->CreateAdd(addr, ConstantInt::get(IntTy, offset));
      addr = Builder->CreateIntToPtr(addr, PointerType::getUnqual(IdTy));
      return Builder->CreateLoad(addr);
    }
    object = Builder->CreateLoad(object);
    return object;
  }

  Value *EndBlock(void) {
    return Block;
  }
};

class CodeGen {
  Module *TheModule;
  CGObjCRuntime * Runtime;
  const Type *CurrentClassTy;
  Function *CurrentMethod;
  Value *Self;
  Value *Cmd;
  IRBuilder *Builder;
  string ClassName;
  string SuperClassName;
  string CategoryName;
  int InstanceSize;
  SmallVector<Value*, 8> Locals;
  SmallVector<Value*, 8> Args;
  SmallVector<CodeGenBlock*, 8> BlockStack;
  llvm::SmallVector<string, 8> IvarNames;
  // All will be "@" for now.
  llvm::SmallVector<string, 8> IvarTypes;
  llvm::SmallVector<int, 8> IvarOffsets;
  llvm::SmallVector<string, 8> InstanceMethodNames;
  llvm::SmallVector<string, 8> InstanceMethodTypes;
  llvm::SmallVector<string, 8> ClassMethodNames;
  llvm::SmallVector<string, 8> ClassMethodTypes;
  llvm::SmallVector<std::string, 8> Protocols;

private:
  Constant *MakeConstantString(const std::string &Str, const
          std::string &Name="", unsigned GEPs=2) {
    Constant * ConstStr = ConstantArray::get(Str);
    ConstStr = new GlobalVariable(ConstStr->getType(), true,
        GlobalValue::InternalLinkage, ConstStr, Name, TheModule);
    return ConstantExpr::getGetElementPtr(ConstStr, Zeros, GEPs);
  }

  string FunctionNameFromSelector(const char *sel) {
    // Special cases
    switch (*sel) {
      case '+':
        return "SmallIntMsgadd_";
      case '-':
        return "SmallIntMsgsub_";
      case '/':
        return "SmallIntMsgdiv_";
      case '*':
        return "SmallIntMsgmul_";
      default: {
        string str = "SmallIntMsg" + string(sel);
        replace(str.begin(), str.end(), ':', '_');
        return str;
      }
    }
  }

  Value *BoxValue(IRBuilder *B, Value *V, const char *typestr) {
    // Untyped selectors return id
    if (NULL == typestr) return V;
    // FIXME: Other function type qualifiers
    while(*typestr == 'V' || *typestr == 'r')
    {
      typestr++;
    }
    switch(*typestr) {
      // All integer primitives smaller than a 64-bit value
      case 'B': case 'c': case 'C': case 's': case 'S': case 'i': case 'I':
      case 'l': case 'L':
        V = B->CreateSExt(V, Type::Int64Ty);
      // Now V is 64-bits.
      case 'q': case 'Q':
      {
        // This will return a SmallInt or a promoted integer.
       Constant *BoxFunction = TheModule->getOrInsertFunction("MakeSmallInt",
            IdTy, Type::Int64Ty, (void*)0);
        return B->CreateCall(BoxFunction, V);
      }
      // Other types, just wrap them up in an NSValue
      default:
      {
        // TODO: Store this in a global.
        Value *NSValueClass = Runtime->LookupClass(*B,
            MakeConstantString("NSValue"));
        // TODO: We should probably copy this value somewhere, maybe with a
        // custom object instead of NSValue?
        // TODO: Should set sender to self.
        LOG("Generating NSValue boxing type %s\n", typestr);
        return Runtime->GenerateMessageSend(*B, IdTy, NULL, NSValueClass,
            Runtime->GetSelector(*B, "valueWithBytes:objCType:", NULL), &V, 1);
      }
      // Map void returns to nil
      case 'v':
      {
        return ConstantPointerNull::get(IdTy);
      }
      // If it's already an object, we don't need to do anything
      case '@': case '#':
        return V;
    }
  }

  void UnboxArgs(IRBuilder *B, Function *F,  Value ** argv, Value **args,
      unsigned argc, const char *selTypes) {
    // FIXME: For objects, we need to turn SmallInts into ObjC objects
    if (NULL == selTypes) {
      // All types are id, so do nothing
      memcpy(args, argv, sizeof(Value*) * argc);
    } else {
      SkipTypeQualifiers(&selTypes);
      //Skip return, self, cmd
      NEXT(selTypes);
      NEXT(selTypes);
      for (unsigned i=0 ; i<argc ; ++i) {
        NEXT(selTypes);
        SkipTypeQualifiers(&selTypes);
        const char *castSelName;
        // TODO: Factor this out into a name-for-type function
        switch(*selTypes) {
          case 'c':
            castSelName = "charValue";
            break;
          case 'C':
            castSelName = "unsignedCharValue";
            break;
          case 's':
            castSelName = "shortValue";
            break;
          case 'S':
            castSelName = "unsignedShortValue";
            break;
          case 'i':
            castSelName = "intValue";
            break;
          case 'I':
            castSelName = "unsignedIntValue";
            break;
          case 'l':
            castSelName = "longValue";
            break;
          case 'L':
            castSelName = "unsignedLongValue";
            break;
          case 'q':
            castSelName = "longLongValue";
            break;
          case 'Q':
            castSelName = "unsignedLongLongValue";
            break;
          case 'f':
            castSelName = "floatValue";
            break;
          case 'd':
            castSelName = "doubleValue";
            break;
          case 'B':
            castSelName = "boolValue";
            break;
          case '@':
            args[i] = argv[i];
            continue;
          default:
            castSelName = "";
            assert(false && "Unable to transmogriy object to compound type");
        }
        //TODO: We don't actually use the size numbers for anything, but someone else does, so make these sensible:
        char typeStr[] = "I12@0:4";
        typeStr[0] = *selTypes;
        args[i] = MessageSend(B, F, argv[i], castSelName,
            typeStr, 0, 0);
      }
    }
  }

  // Preform a real message send.  Reveicer must be a real object, not a
  // SmallInt.
  Value *MessageSendId(IRBuilder *B, Value *receiver, const char *selName,
      const char *selTypes, Value **argv, unsigned argc) {
    Value *Self = LoadSelf();
    FunctionType *MethodTy = LLVMFunctionTypeFromString(selTypes);
    llvm::Value *cmd = Runtime->GetSelector(*B, selName, selTypes);
    return Runtime->GenerateMessageSend(*B, MethodTy->getReturnType(), Self,
        receiver, cmd, argv, argc);
  }
  Value *MessageSend(IRBuilder *B, Function *F, Value *receiver, const char
      *selName, const char *selTypes, Value **argv, unsigned argc) {
    Value *Int = B->CreatePtrToInt(receiver, IntPtrTy);
    Value *IsSmallInt = B->CreateTrunc(Int, Type::Int1Ty, "is_small_int");

    // Basic block for messages to SmallInts.
    BasicBlock *SmallInt = BasicBlock::Create(string("small_int_message") + selName, F);
    IRBuilder SmallIntBuilder = IRBuilder(SmallInt);
    Value *Result = 0;

    // See if there is a function defined to implement this message
    Value *SmallIntFunction =
      TheModule->getFunction(FunctionNameFromSelector(selName));

    if (0 != SmallIntFunction) {
      SmallVector<Value*, 8> Args;
      Args.push_back(receiver);
      Args.insert(Args.end(), argv, argv+argc);
      for (unsigned i=0 ; i<Args.size() ;i++) {
        const Type *ParamTy =
          cast<Function>(SmallIntFunction)->getFunctionType()->getParamType(i);
        if (Args[i]->getType() != ParamTy) {
          Args[i] = SmallIntBuilder.CreateBitCast(Args[i], ParamTy);
        }
      }
      Result = SmallIntBuilder.CreateCall(SmallIntFunction, Args.begin(),
          Args.end(), "small_int_message_result");
    } else {
      //Promote to big int and send a real message.
      Value *BoxFunction = TheModule->getFunction("BoxSmallInt");
      Result = SmallIntBuilder.CreateBitCast(receiver, IdTy);
      Result = SmallIntBuilder.CreateCall(BoxFunction, Result,
          "boxed_small_int");
      Result = MessageSendId(&SmallIntBuilder, Result, selName, selTypes, argv,
          argc);
    }
    BasicBlock *RealObject = BasicBlock::Create(string("real_object_message") + selName,
        F);
    IRBuilder RealObjectBuilder = IRBuilder(RealObject);
    Value *ObjResult = MessageSendId(&RealObjectBuilder, receiver, selName,
        selTypes, argv, argc);

    if ((Result->getType() != ObjResult->getType())
        && (ObjResult->getType() != Type::VoidTy)) {
      Result = new BitCastInst(Result, ObjResult->getType(),
          "cast_small_int_result", SmallInt);
    }
    
    B->CreateCondBr(IsSmallInt, SmallInt, RealObject);
    BasicBlock *Continue = BasicBlock::Create("Continue", F);
    B->SetInsertPoint(Continue);

    RealObjectBuilder.CreateBr(Continue);
    SmallIntBuilder.CreateBr(Continue);
    if (ObjResult->getType() != Type::VoidTy) {
      PHINode *Phi = B->CreatePHI(Result->getType(),  selName);
      Phi->reserveOperandSpace(2);
      Phi->addIncoming(Result, SmallInt);
      Phi->addIncoming(ObjResult, RealObject);
      return Phi;
    }
    return ConstantPointerNull::get(IdTy);
  }

public:
  CodeGen(const char *ModuleName) {
    TheModule = ParseBitcodeFile(MemoryBuffer::getFile(MsgSendSmallIntFilename));
    Runtime = clang::CodeGen::CreateObjCRuntime(*TheModule, IntTy,
        IntegerType::get(sizeof(long) * 8));
  }

  void BeginClass(const char *Class, const char *Super, const char ** Names,
      const char ** Types, int *Offsets) {
    ClassName = string(Class);
    SuperClassName = string(Super);
    CategoryName = "";
    InstanceMethodNames.clear();
    InstanceMethodTypes.clear();
    IvarNames.clear();
    while (*Names) {
      IvarNames.push_back(*Names);
      Names++;
    }
    IvarTypes.clear();
    while (*Types) {
      IvarTypes.push_back(*Types);
      Types++;
    }
    IvarOffsets.clear();
    while (*Offsets) {
      IvarOffsets.push_back(*Offsets);
      Offsets++;
    }
    CurrentClassTy = IdTy;
  }

  void EndClass(void) {
    // FIXME: Get the instance size from somewhere sensible.
    Runtime->GenerateClass(ClassName.c_str(), SuperClassName.c_str(), 100,
        IvarNames, IvarTypes, IvarOffsets, InstanceMethodNames,
        InstanceMethodTypes, ClassMethodNames, ClassMethodTypes, Protocols);
  }

  void BeginMethod(const char *MethodName, const char *MethodTypes, int locals) {
    // Log the method name and types so that we can use it to set up the class
    // structure.
    InstanceMethodNames.push_back(MethodName);
    InstanceMethodTypes.push_back(MethodTypes);

    // Generate the method function
    FunctionType *MethodTy = LLVMFunctionTypeFromString(MethodTypes);
    unsigned argc = MethodTy->getNumParams() - 2;
    const Type *argTypes[argc];
    FunctionType::param_iterator arg = MethodTy->param_begin();
    ++arg; ++arg;
    for (unsigned i=0 ; i<argc ; ++i) {
      argTypes[i] = MethodTy->getParamType(i+2);
    }


    CurrentMethod = Runtime->MethodPreamble(ClassName, CategoryName, MethodName,
        MethodTy->getReturnType(), CurrentClassTy, 
        argTypes, argc, false, false);
    BasicBlock * EntryBB = llvm::BasicBlock::Create("entry", CurrentMethod);
    Builder = new IRBuilder(EntryBB);
    llvm::Function::arg_iterator AI = CurrentMethod->arg_begin();
    const llvm::Type *IPTy = AI->getType();
    llvm::Value *DeclPtr = Builder->CreateAlloca(IPTy, 0, (AI->getName() +
        ".addr").c_str());
    // Store the initial value into the alloca.
    Builder->CreateStore(AI, DeclPtr);
    Self = DeclPtr;
    ++AI;
    IPTy = AI->getType();
    DeclPtr = Builder->CreateAlloca(IPTy, 0, (AI->getName() +
        ".addr").c_str());
    // Store the initial value into the alloca.
    Builder->CreateStore(AI, DeclPtr);
    Cmd = DeclPtr;
    ++AI;

    Args.clear();
    //TODO: Handle non-id types
    for(Function::arg_iterator end = CurrentMethod->arg_end() ; AI != end ;
        ++AI) {
      Value * arg = Builder->CreateAlloca(AI->getType(), 0, "arg");
      Args.push_back(arg);
      // Initialise the local to nil
      Builder->CreateStore(AI, arg);
    }

    Locals.clear();
    // Create the locals and initialise them to nil
    for (int i = 0 ; i < locals ; i++) {
      Value * local = Builder->CreateAlloca(IdTy, 0, "local");
      Locals.push_back(local);
      // Initialise the local to nil
      Builder->CreateStore(ConstantPointerNull::get(IdTy),
          local);
    }
  }

  Value *LoadArgumentAtIndex(unsigned index) {
    if (BlockStack.empty()) {
      return Builder->CreateLoad(Args[index]);
    }
    return BlockStack.back()->LoadArgumentAtIndex(index);
  }

  Value *MessageSendId(Value *receiver, const char *selName, const char
      *selTypes, Value **argv, unsigned argc) {
    IRBuilder *B = Builder;
    Function *F = CurrentMethod;
    if (!BlockStack.empty()) {
      CodeGenBlock *b = BlockStack.back();
      B = b->Builder;
      F = b->BlockFn;
    }
    Value *args[argc];
    UnboxArgs(B, F, argv, args, argc, selTypes);
    return BoxValue(B, MessageSendId(B, receiver, selName, selTypes, argv,
          argc), selTypes);
  }

  Value *MessageSend(Value *receiver, const char *selName, const char
      *selTypes, Value **argv, unsigned argc) {
    IRBuilder *B = Builder;
    Function *F = CurrentMethod;
    if (!BlockStack.empty()) {
      CodeGenBlock *b = BlockStack.back();
      B = b->Builder;
      F = b->BlockFn;
    }
    Value *args[argc];
    UnboxArgs(B, F, argv, args, argc, selTypes);
    return BoxValue(B, MessageSend(B, F, receiver, selName, selTypes, args,
          argc), selTypes);
  }

  void SetReturn(Value * RetVal = 0) {
    const Type *RetTy = CurrentMethod->getReturnType();
    if (RetVal == 0) {
      if (RetTy == Type::VoidTy) {
        Builder->CreateRetVoid();
      } else if (const PointerType *PTy = dyn_cast<const PointerType>(RetTy)) {
        Builder->CreateRet(ConstantPointerNull::get(PTy));
      } else {
        Builder->CreateRet(UndefValue::get(CurrentMethod->getReturnType()));
      }
    } else {
      if (RetTy == Type::VoidTy) {
        LOG("Returning a value from a method expected to return void!\n");
        return;
      }
      if (RetVal->getType() != RetTy) {
        RetVal = Builder->CreateBitCast(RetVal, RetTy);
      }
      Builder->CreateRet(RetVal);
    }
  }

  void EndMethod() {
    if (0 == Builder->GetInsertBlock()->getTerminator()) {
      SetReturn();
    }
  }

  Value *LoadSelf(void) {
    return Builder->CreateLoad(Self);
  }
  
  Value *LoadLocalAtIndex(unsigned index) {
    return Builder->CreateLoad(Locals[index]);
  }
	Value *LoadPointerToLocalAtIndex(unsigned index) {
    return Locals[index];
  }

  void StoreValueInLocalAtIndex(Value * value, unsigned index) {
    Builder->CreateStore(value, Locals[index]);
  }

  Value *LoadClass(const char *classname) {
    return Runtime->LookupClass(*Builder, MakeConstantString(classname));
  }

  Value *LoadValueOfTypeAtOffsetFromObject( const char* type, unsigned offset,
      Value *object) {
    // FIXME: This is really ugly.  We should really create an LLVM type for
    // the object and use a GEP.
    // FIXME: Non-id loads
    assert(*type == '@');
    Value *addr = Builder->CreatePtrToInt(object, IntTy);
    addr = Builder->CreateAdd(addr, ConstantInt::get(IntTy, offset));
    addr = Builder->CreateIntToPtr(addr, PointerType::getUnqual(IdTy));
    return Builder->CreateLoad(addr);
  }

  void StoreValueOfTypeAtOffsetFromObject(Value *value,
      const char* type, unsigned offset, Value *object) {
    // FIXME: This is really ugly.  We should really create an LLVM type for
    // the object and use a GEP.
    // FIXME: Non-id stores
    assert(*type == '@');
    Value *addr = Builder->CreatePtrToInt(object, IntTy);
    addr = Builder->CreateAdd(addr, ConstantInt::get(IntTy, offset));
    addr = Builder->CreateIntToPtr(addr, PointerType::getUnqual(IdTy));
    Builder->CreateStore(value, addr);
  }

  //void SendMessageToIvar(char *ivar, Value *selector, 
  
  void BeginBlock(unsigned args, unsigned locals, Value **promoted, int count) {
    BlockStack.push_back(new CodeGenBlock(TheModule, args, locals, promoted,
          count, Builder));
  }
  Value *LoadBlockVar(unsigned index, unsigned offset) {
    return BlockStack.back()->LoadBlockVar(index, offset);
  }

  void SetBlockReturn(Value *value) {
    BlockStack.back()->SetReturn(value);
  }

  Value *EndBlock(void) {
    CodeGenBlock *block = BlockStack.back();
    BlockStack.pop_back();
    block->EndBlock();
    return block->Block;
  }

  Value *IntConstant(const char *value) {
    long long val = strtoll(value, NULL, 10);
    intptr_t ptrVal = (val << 1);
    if ((0 == val && errno == EINVAL) || ((ptrVal >> 1) != val)) {
      //FIXME: Implement BigInt
      assert(false && "Number needs promoting to BigInt and BigInt isn't implemented yet");
    }
    ptrVal |= 1;
    Constant *Val = ConstantInt::get(IntPtrTy, ptrVal);
    Val = ConstantExpr::getIntToPtr(Val, IdTy);
    Val->setName("SmallIntConstant");
    return Val;
  }
  Value *StringConstant(const char *value) {
    return Runtime->GenerateConstantString(value, strlen(value));
  }
	Value *ComparePointers(Value *lhs, Value *rhs) {
    lhs = Builder->CreatePtrToInt(lhs, IntPtrTy);
    rhs = Builder->CreatePtrToInt(rhs, IntPtrTy);
    Value *result = Builder->CreateICmpEQ(rhs, lhs, "pointer_compare_result");
    result = Builder->CreateZExt(result, IntPtrTy);
    result = Builder->CreateShl(result, ConstantInt::get(IntPtrTy, 1));
    result = Builder->CreateOr(result, ConstantInt::get(IntPtrTy, 1));
    return Builder->CreateIntToPtr(result, IdTy);
  }

  void compile(void) {
    llvm::Function *init = Runtime->ModuleInitFunction();
    // Make the init function external so the optimisations won't remove it.
    init->setLinkage(GlobalValue::ExternalLinkage);
    //DUMP(TheModule);
    LOG("\n\n\n Optimises to:\n\n\n");
    PassManager pm;
    pm.add(createVerifierPass());
    pm.add(new TargetData(TheModule));
    pm.add(createPromoteMemoryToRegisterPass());
    pm.add(createFunctionInliningPass());
    pm.add(createIPConstantPropagationPass());
    pm.add(createSimplifyLibCallsPass());
    pm.add(createCondPropagationPass());
    pm.add(createAggressiveDCEPass());
    pm.add(createInstructionCombiningPass());
    pm.add(createTailDuplicationPass());
    pm.add(createCFGSimplificationPass());
    pm.add(createStripDeadPrototypesPass());
    pm.run(*TheModule);
    DUMP(TheModule);
    //ExecutionEngine *EE = ExecutionEngine::create(L->getModule());
    ExecutionEngine *EE = ExecutionEngine::create(TheModule);
    LOG("Compiling...\n");
    EE->runStaticConstructorsDestructors(false);
    void(*f)(void) = (void(*)(void))EE->getPointerToFunction(init);
    LOG("Loading %x...\n", (unsigned)(unsigned long)f);
    f();
    LOG("Loaded.\n");
  }

  void optimisedCompile(void) {
    /*
    ExistingModuleProvider OurModuleProvider(TheModule);
    FunctionPassManager OurFPM(&OurModuleProvider);
      
    // Set up the optimizer pipeline.  Start with registering info about how the
    // target lays out data structures.
    OurFPM.add(new TargetData(*TheExecutionEngine->getTargetData()));
    // Do simple "peephole" optimizations and bit-twiddling optzns.
    OurFPM.add(createInstructionCombiningPass());
    // Reassociate expressions.
    OurFPM.add(createReassociatePass());
    // Eliminate Common SubExpressions.
    OurFPM.add(createGVNPass());
    // Simplify the control flow graph (deleting unreachable blocks, etc).
    OurFPM.add(createCFGSimplificationPass());
*/
  }


};
CGObjCRuntime::~CGObjCRuntime() {}


// C interface:
extern "C" {
#include "LLVMCodeGen.h"

  void LLVMinitialise(const char *bcFilePath) {
    MsgSendSmallIntFilename = strdup(bcFilePath);
    IdTy = PointerType::getUnqual(Type::Int8Ty);
    IntTy = IntegerType::get(sizeof(int) * 8);
    IntPtrTy = IntegerType::get(sizeof(void*) * 8);
    Zeros[0] = Zeros[1] = llvm::ConstantInt::get(llvm::Type::Int32Ty, 0);
    //FIXME: 
    SelTy = IntPtrTy;
    std::vector<const Type*> IMPArgs;
    IMPArgs.push_back(IdTy);
    IMPArgs.push_back(SelTy);
    IMPTy = PointerType::getUnqual(FunctionType::get(IdTy, IMPArgs, true));
  }

  ModuleBuilder newModuleBuilder(const char *ModuleName) {
    if (NULL == ModuleName) ModuleName = "Anonymous";
    return new CodeGen(ModuleName);
  }
  void freeModuleBuilder(ModuleBuilder aModule) {
    delete aModule;
  }

  void Compile(ModuleBuilder B) {
    //B->optimise();
    B->compile();
  }
  void BeginClass(ModuleBuilder B, const char *Class, const char *Super, const
      char ** Names, const char ** Types, int *Offsets) {
    B->BeginClass(Class, Super, Names, Types, Offsets);
  }

  LLVMValue MessageSend(ModuleBuilder B, LLVMValue receiver, const char *selname,
      const char *seltype, LLVMValue *argv, unsigned argc) {
    return B->MessageSend(receiver, selname, seltype, argv, argc);
  }
  LLVMValue MessageSendId(ModuleBuilder B, LLVMValue receiver, const char *selname,
      const char *seltype, LLVMValue *argv, unsigned argc) {
    return B->MessageSendId(receiver, selname, seltype, argv, argc);
  }

  void SetReturn(ModuleBuilder B, LLVMValue retval) {
    B->SetReturn(retval);
  }

  void BeginMethod(ModuleBuilder B, const char *methodname, const char
      *methodTypes, unsigned locals) {
    B->BeginMethod(methodname, methodTypes, locals);
  }

  void EndMethod(ModuleBuilder B) {
    B->EndMethod();
  }
  LLVMValue LoadSelf(ModuleBuilder B) {
    return B->LoadSelf();
  }
  void StoreValueInLocalAtIndex(ModuleBuilder B, LLVMValue value, unsigned
      index) {
    B->StoreValueInLocalAtIndex(value, index);
  }
  void StoreValueOfTypeAtOffsetFromObject(ModuleBuilder B, LLVMValue value,
      const char* type, unsigned offset, LLVMValue object) {
    B->StoreValueOfTypeAtOffsetFromObject(value, type, offset, object);
  }

	LLVMValue LoadPointerToLocalAtIndex(ModuleBuilder B, unsigned index) {
    return B->LoadPointerToLocalAtIndex(index);
  }
  LLVMValue LoadLocalAtIndex(ModuleBuilder B, unsigned index) {
    return B->LoadLocalAtIndex(index);
  }

  LLVMValue LoadArgumentAtIndex(ModuleBuilder B, unsigned index) {
    return B->LoadArgumentAtIndex(index);
  }

  Value *LoadValueOfTypeAtOffsetFromObject(ModuleBuilder B, const char* type,
      unsigned offset, Value *object) {
    return B->LoadValueOfTypeAtOffsetFromObject(type, offset, object);
  }

  void EndClass(ModuleBuilder B) {
    B->EndClass();
  }

  LLVMValue LoadClass(ModuleBuilder B, const char *classname) {
    return B->LoadClass(classname);
  }
  void BeginBlock(ModuleBuilder B, unsigned args, unsigned locals, LLVMValue
      *promoted, int count) {
    B->BeginBlock(args, locals, promoted, count);
  }
  LLVMValue LoadBlockVar(ModuleBuilder B, unsigned index, unsigned offset) {
    return B->LoadBlockVar(index, offset);
  }

  LLVMValue IntConstant(ModuleBuilder B, const char *value) {
    return B->IntConstant(value);
  }
  LLVMValue StringConstant(ModuleBuilder B, const char *value) {
    return B->StringConstant(value);
  }

  LLVMValue EndBlock(ModuleBuilder B) {
    return B->EndBlock();
  }
  LLVMValue NilConstant() {
    return ConstantPointerNull::get(IdTy);
  }
	LLVMValue ComparePointers(ModuleBuilder B, LLVMValue lhs, LLVMValue rhs) {
    return B->ComparePointers(rhs, lhs);
  }
  
  void SetBlockReturn(ModuleBuilder B, LLVMValue value) {
    B->SetBlockReturn(value);
  }

}
