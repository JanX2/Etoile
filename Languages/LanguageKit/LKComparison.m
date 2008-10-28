#import "LKComparison.h"

@implementation LKCompare
+ (LKCompare*) compare:(LKAST*)expr1 to:(LKAST*)expr2
{
	return [[[LKCompare alloc] initComparing:expr1 to:expr2] autorelease];
}
- (id) initComparing:(LKAST*)expr1 to:(LKAST*)expr2
{
	SELFINIT;
	ASSIGN(lhs, expr1);
	ASSIGN(rhs, expr2);
	return self;
}
- (NSString*) description
{
	return [NSString stringWithFormat:@"%@ = %@", lhs, rhs];
}
- (void) check
{
	[lhs setParent:self];
	[rhs setParent:self];
	[lhs check];
	[rhs check];
}
- (void*) compileWith:(id<LKCodeGenerator>)aGenerator
{
	void * l = [lhs compileWith:aGenerator];
	void * r = [rhs compileWith:aGenerator];
	return [aGenerator comparePointer:l to:r];
}
@end
