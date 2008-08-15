#import "AssignExpr.h"
#import "DeclRef.h"

static char *RetainTypes;
static char *ReleaseTypes;
@interface NSMethodSignature (TypeEncodings)
- (const char*) _methodTypes;
@end
@implementation NSMethodSignature (TypeEncodings)
- (const char*) _methodTypes
{
	return _methodTypes;
}
@end
@implementation AssignExpr
+ (void) initialize
{
	RetainTypes = 
		strdup([[NSObject instanceMethodSignatureForSelector:@selector(retain)]
		        _methodTypes]);
	ReleaseTypes = 
		strdup([[NSObject instanceMethodSignatureForSelector:@selector(release)]
		        _methodTypes]);
}
- (void) check
{
	[expr setParent:self];
	[target setParent:self];
	[target check];
	[expr check];
}
- (NSString*) description
{
	return [NSString stringWithFormat:@"%@ := %@", target->symbol, expr];
}
- (void*) compileWith:(id<CodeGenerator>)aGenerator
{
	void * rval = [expr compileWith:aGenerator];
	switch([symbols scopeOfSymbol:target->symbol])
	{
		case local:
			[aGenerator storeValue:rval
			        inLocalAtIndex:[symbols offsetOfLocal:target->symbol]];
			break;
		case object:
		{
			// Move this to -check
			if ([[symbols typeOfSymbol:target->symbol] characterAtIndex:0] != '@')
			{
				[NSException raise:@"InvalidAssignmentException"
				            format:@"Can not yet generate code for assignment"];
			}
			// Assign
			[aGenerator storeValue:rval
			                ofType:@"@"
			              atOffset:[symbols offsetOfIVar:target->symbol]
			            fromObject:[aGenerator loadSelf]];
			break;
		}
		case promoted:
		{
		}
		default:
			NSLog(@"Scope of %@ is %d.", target->symbol, [symbols scopeOfSymbol:target->symbol]);
			// Throws exception
			[super compileWith:aGenerator];
	}
	// Assignments aren't expressions in Smalltalk, but they might be in some
	// other language that wants to use this code and it doesn't cost more than
	// returning NULL.
	return rval;
}
@end
