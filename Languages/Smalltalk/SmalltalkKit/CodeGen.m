#import "LLVMCodeGen.h"
#import "SymbolTable.h"
#include <objc/objc-api.h>

@implementation LLVMCodeGen 
+ (void) initialize
{
	if (self == [LLVMCodeGen class])
	{
		const char *path;
		NSFileManager *f = [NSFileManager defaultManager];
		if ([f fileExistsAtPath:@"MsgSendSmallInt.bc"])
		{
			path = "MsgSendSmallInt.bc";
		}
		else 
		{
			path = [[[NSBundle bundleForClass:self] 
				pathForResource:@"MsgSendSmallInt" ofType:@"bc"] UTF8String];
		}
		NSAssert(path, @"Unable to find the location of MsgSendSmallInt.bc.  This must be in either the current working directory or in the Resources directory of the SmalltalkKit framework installed on your system.");
		LLVMinitialise(path);
	}
}
- (void) startModule
{
	Builder = newModuleBuilder(NULL);
}

- (void) endModule
{
	Compile(Builder);
}

- (void) createSubclass:(NSString*)aClass
            subclassing:(NSString*)aSuperclass
          withIvarNames:(const char**)iVarNames 
                  types:(const char**)iVarTypes
                offsets:(int*)offsets
{
	int supersize = 0;
	Class sup = NSClassFromString(aSuperclass);
	if (Nil != sup)
	{
		supersize = sup->instance_size;
	}
	else
	{
		ObjectSymbolTable * symbols = (ObjectSymbolTable*)
			[ObjectSymbolTable symbolTableForNewClassNamed:aSuperclass];
		if (nil != symbols)
		{
			supersize = [symbols instanceSize];
		}
	}
	BeginClass(Builder, [aClass UTF8String], [aSuperclass UTF8String],
			iVarNames, iVarTypes, offsets, supersize);
}
- (void) endClass
{
	EndClass(Builder);
}
- (void) createCategoryOn:(NSString*)aClass
                    named:(NSString*)aCategory
{
	BeginCategory(Builder, [aClass UTF8String], [aClass UTF8String]);
}
- (void) endCategory
{
	EndCategory(Builder);
}

- (void) beginMethod:(const char*) aName
           withTypes:(const char*)types
              locals:(unsigned)locals
{
	BeginMethod(Builder, aName, types, locals);
}

- (void*) sendMessage:(const char*)aMessage
                types:(const char*)types
             toObject:(void*)receiver
             withArgs:(void**)argv
                count:(unsigned)argc
{
  return MessageSendId(Builder, receiver, aMessage, types, (LLVMValue*)argv,
      argc);
}
- (void*) sendSuperMessage:(const char*)sel
                     types:(const char*)seltypes
                  withArgs:(void**)argv
                     count:(unsigned)argc
{
	return MessageSendSuper(Builder, sel, seltypes, (LLVMValue*)argv, argc);
}
- (void*) sendMessage:(const char*)aMessage
                types:(const char*)types
                   to:(void*)receiver
             withArgs:(void**)argv
                count:(unsigned)argc
{
  return MessageSend(Builder, receiver, aMessage, types, (LLVMValue*)argv,
      argc);
}
- (void) storeValue:(void*)aVal inLocalAtIndex:(unsigned)index
{
	StoreValueInLocalAtIndex(Builder, aVal, index);
}
- (void) storeValue:(void*)aValue
              ofType:(NSString*)aType
            atOffset:(unsigned)anOffset
          fromObject:(void*)anObject
{
	StoreValueOfTypeAtOffsetFromObject(Builder, aValue, [aType UTF8String],
			anOffset, anObject);
}
- (void*) loadValueOfType:(NSString*)aType
                 atOffset:(unsigned)anOffset
               fromObject:(void*)anObject
{
	return LoadValueOfTypeAtOffsetFromObject(Builder, [aType UTF8String],
			anOffset, anObject);
}
- (void) beginBlockWithArgs:(unsigned)args
					 locals:(unsigned)locals
				  boundVars:(void**)promoted
					  count:(int)index
{
	BeginBlock(Builder, args, locals, (LLVMValue*)promoted, index);
}
- (void*) endBlock
{
	return EndBlock(Builder);
}
- (void) endMethod
{
	EndMethod(Builder);
}

- (void) setReturn:(void*)aValue
{
	SetReturn(Builder, aValue);
}
- (void) blockReturn:(void*)aValue
{
	SetBlockReturn(Builder, aValue);
}
- (void*) loadBlockVarAtIndex:(unsigned)index
					   offset:(unsigned)offset
{
	return LoadBlockVar(Builder, index, offset);
}
- (void*) loadSelf
{
	return LoadSelf(Builder);
}
- (void*) loadPointerToLocalAtIndex:(unsigned)index
{
	return LoadPointerToLocalAtIndex(Builder, index);
}
- (void*) loadPointerToArgumentAtIndex:(unsigned)index
{
	return LoadPointerToArgumentAtIndex(Builder, index);
}

- (void*) loadLocalAtIndex:(unsigned)index
{
	return LoadLocalAtIndex(Builder, index);
}
- (void*) loadArgumentAtIndex:(unsigned) index
{
	return LoadArgumentAtIndex(Builder, index);
}
- (void*) loadClass:(NSString*)aClass
{
	return LoadClass(Builder, [aClass UTF8String]);
}
- (void*) intConstant:(NSString*)aString
{
	return IntConstant(Builder, [aString UTF8String]);
}
- (void*) stringConstant:(NSString*)aString
{
	return StringConstant(Builder, [aString UTF8String]);
}
- (void*) nilConstant
{
	return NilConstant();
}
- (void*) comparePointer:(void*)lhs to:(void*)rhs
{
	return ComparePointers(Builder, lhs, rhs);
}
- (void) dealloc
{
	freeModuleBuilder(Builder);
	[super dealloc];
}
- (void*) generateConstantSymbol:(NSString*)aSymbol
{
	return SymbolConstant(Builder, [aSymbol UTF8String]);
}
@end
id <CodeGenerator> defaultCodeGenerator(void)
{
	return [LLVMCodeGen new];
}
