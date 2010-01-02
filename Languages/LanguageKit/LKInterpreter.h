#import "Runtime/BlockClosure.h"
#import <LanguageKit/LKAST.h>
#import <LanguageKit/LKBlockExpr.h>
#import <LanguageKit/LKMethod.h>
#import <LanguageKit/LKSubclass.h>

extern NSString *LKInterpreterException;

LKMethod *LKASTForMethod(Class cls, NSString *selectorName);

@interface LKInterpreterContext : NSObject
{
	LKInterpreterContext *parent;
	id selfObject;
	NSArray *symbols;
	id *objects;
}
- (id) initWithSelf: (id)selfObject
            symbols: (NSArray*)symbols
             parent: (LKInterpreterContext*)aParent;
- (BOOL) setValue: (id)value forSymbol: (NSString*)symbol;
- (id) valueForSymbol: (NSString*)symbol;
@end


@interface LKAST (LKInterpreter)
- (id)interpretInContext: (LKInterpreterContext*)context;
@end

@interface LKBlockExpr (LKInterpreter)
- (id)interpretInContext: (LKInterpreterContext*)context;
- (id)executeWithArguments: (id*)args count: (int)count inContext: (LKInterpreterContext*)context;
@end

@interface LKMethod (LKInterpreter)
- (id)executeInContext: (LKInterpreterContext*)context;
- (id)executeWithReciever: (id)receiver arguments: (id*)args count: (int)count;
@end

@interface LKSubclass (LKInterpreter)
- (void)setValue: (id)value forClassVariable: (NSString*)cvar;
- (id)valueForClassVariable: (NSString*)cvar;
@end
