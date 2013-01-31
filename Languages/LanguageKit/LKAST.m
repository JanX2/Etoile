#import "LKAST.h"
#import "LKDeclRef.h"
#import "LKModule.h"

static Class DeclRefClass;
static Class ModuleClass;

static NSMutableDictionary *ASTSubclassAndCategoryNodes = nil;

@implementation LKAST

+ (NSMutableDictionary *) code
{
	if (ASTSubclassAndCategoryNodes == nil)
	{
		ASTSubclassAndCategoryNodes = [[NSMutableDictionary alloc] init];
	}
	return ASTSubclassAndCategoryNodes;
}

+ (void) initialize
{
	DeclRefClass = [LKDeclRef class];
	ModuleClass = [LKModule class];
}

- (LKModule*) module
{
	__unsafe_unretained LKAST *module = self;
	while (nil != module && ModuleClass != object_getClass(module))
	{
		module = module->parent;
	}
	return (LKModule*)module;
}


- (id) initWithSymbolTable:(LKSymbolTable*)aSymbolTable
{
	if(nil == (self = [self init]))
	{
		return nil;
	}
	ASSIGN(symbols, aSymbolTable);
	return self;
}
- (void) print
{
	printf("%s", [[self description] UTF8String]);
}
- (void) inheritSymbolTable:(LKSymbolTable*)aSymbolTable
{
	ASSIGN(symbols, aSymbolTable);
}
- (LKAST*) parent;
{
	return parent;
}
- (void) setParent:(LKAST*)aNode
{
	[self inheritSymbolTable: [aNode symbols]];
	parent = aNode;
}
- (void) setBracketed:(BOOL)aFlag
{
	isBracket = aFlag;
}
- (BOOL) isBracketed
{
	return isBracket;
}
- (BOOL) check
{
	// Subclasses should implement this.
	[self doesNotRecognizeSelector:_cmd];
	// Not reached.
	return NO;
}
- (BOOL)checkWithErrorReporter: (id<LKCompilerDelegate>)errorReporter
{
	NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
	id old = [dict objectForKey: @"LKCompilerContext"];
	[dict setObject: errorReporter forKey: @"LKCompilerContext"];
	BOOL success = [self check];
	[dict setValue: old forKey: @"LKCompilerContext"];

	return success;
}
- (void*) compileWithGenerator: (id<LKCodeGenerator>)aGenerator
{
	NSLog(@"Compiling %@ ...", self);
	[NSException raise:@"NotImplementedException"
	            format:@"Code generation not yet implemented for %@", 
		[self class]];
	return NULL;
}
- (LKSymbolTable*) symbols
{
	return symbols;
}
- (BOOL) isComment
{
	return NO;
}
- (BOOL) isBranch
{
	return NO;
}
@end
@implementation LKAST (Visitor)
- (void) visitWithVisitor:(id<LKASTVisitor>)aVisitor
{
	// AST nodes with no children do nothing.
}
- (void) visitArray:(NSMutableArray*)anArray
        withVisitor:(id<LKASTVisitor>)aVisitor
{
	unsigned int count = [anArray count];
	NSMutableIndexSet *remove = [NSMutableIndexSet new];
	for (int i=0 ; i<count ; i++)
	{
		LKAST *old = [anArray objectAtIndex:i];
		LKAST *new = [aVisitor visitASTNode:old];
		if (new != old)
		{
			if (nil == new)
			{
				[remove addIndex: i];
			}
			else
			{
				[anArray replaceObjectAtIndex:i withObject:new];
			}
		}
		[new visitWithVisitor:aVisitor];
	}
	[anArray removeObjectsAtIndexes: remove];
}
- (void)dealloc
{
}
@end
