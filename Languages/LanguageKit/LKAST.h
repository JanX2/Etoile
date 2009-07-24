#import "LKSymbolTable.h"
#import "LKCodeGen.h"
#import "LKCompiler.h"


@class LKModule;
@class LKInterpreterContext;
/**
 * Root class for AST nodes.  Every node in the abstract syntax tree inherits
 * from this.  It stores the parent, allowing navigation up the tree, and a
 * pointer to the symbol table for this scope.  
 */
@interface LKAST : NSObject {
	/** Node above this one in the tree. */
	LKAST * parent;
	/** Is this a parenthetical expression?  Avoids creating explicit nodes for
	* parenthetical expressions.  Might not be sensible.*/
	BOOL isBracket;
	/** Symbol table for this context.  If no new symbols are defined, this is a
	* pointer to the parent's symbol table. */
	LKSymbolTable * symbols;
}
/**
 * Returns the AST nodes available at runtime for subclasses and categories.
 */
+ (NSMutableDictionary*)code;
/**
 * Returns the module containing the current AST.
 */
- (LKModule*) module;
/**
 * Initialise a new AST node with the specified symbol table.
 */
- (id) initWithSymbolTable:(LKSymbolTable*)aSymbolTable;
/**
 * Set whether the AST node represents a bracketed expression.
 */
- (void) setBracketed:(BOOL)aFlag;
/**
 * Returns whether the AST node represents a bracketed expression.
 */
- (BOOL) isBracketed;
/**
 * Inherits the given symbol table from the parent.
 */
- (void) inheritSymbolTable:(LKSymbolTable*)aSymbolTable;
/**
 * Sets the parent of this node.  Also sets connections between the nodes'
 * symbol tables.
 */
- (void) setParent:(LKAST*)aNode;
/**
 * Returns the parent of this AST node.
 */
- (LKAST*) parent;
/**
 * Returns the symbol table for this node.
 */
- (LKSymbolTable*) symbols;
/**
 * Prints the syntax tree from this node.  Use only for debugging.
 */
- (void) print;
/**
 * Performs semantic analysis on this node and all of its children.
 */
- (BOOL)check;
/**
 * Performs semantic analysis on this node and all of its children, reporting
 * errors and warnings to the object specified by the argument.
 */
- (BOOL)checkWithErrorReporter: (id<LKCompilerDelegate>)errorReporter;
/**
 * Compile this AST node with the specified code generator.
 */
- (void*) compileWithGenerator: (id<LKCodeGenerator>)aGenerator;
/**
 * Returns YES for AST nodes with no code generation
 */
- (BOOL) isComment;
/**
 * Returns YES for AST nodes that branch unconditionally.
 */
- (BOOL) isBranch;
@end

/**
 * Protocol for AST visitors.  Used for classes that perform AST transforms.
 */
@protocol LKASTVisitor
/**
 * Visit the specified AST node.  The argument will be replaced by the return
 * value in the AST if the two differ.
 */
- (LKAST*) visitASTNode:(LKAST*)anAST;
@end
@interface LKAST (Visitor)
/**
 * Visit the abstract syntax tree with the specified visitor.
 */
- (void) visitWithVisitor:(id<LKASTVisitor>)aVisitor;
/**
 * Convenience method.  Visits every element in a specified mutable array,
 * replacing elements with the versions returned by the visitor if they have
 * changed.
 */
- (void) visitArray:(NSMutableArray*)anArray
        withVisitor:(id<LKASTVisitor>)aVisitor;
@end

@interface LKAST (Interpreter)
/**
 * Interprets the AST node with the specified context object.  Returns the
 * result.
 */
- (id)interpretInContext: (LKInterpreterContext*)context;
@end

#define SAFECAST(type, obj) ([obj isKindOfClass:[type class]] ? (type*)obj : ([NSException raise:@"InvalidCast" format:@"Can not cast %@ to %s", obj, #type], (type*)nil))
