#import "LKCategory.h"

@implementation LKCategoryDef
- (id) initWithName:(NSString*)aName
              class:(NSString*)aClass
            methods:(NSArray*)aMethodList
{
	SELFINIT;
	ASSIGN(classname, aClass);
	ASSIGN(categoryName, aName);
	ASSIGN(methods, aMethodList);
	return self;
}
+ (id) categoryWithName:(NSString*)aName 
                  class:(NSString*)aClass 
                methods:(NSArray*)aMethodList
{
	return [[[self alloc] initWithName:aName
	                             class:aClass
	                           methods:aMethodList] autorelease];
}
+ (id) categoryWithClass:(NSString*)aName methods:(NSArray*)aMethodList
{
	return [self categoryWithName:@"AnonymousCategory"
	                        class:aName
	                      methods:aMethodList];
}
- (void) check
{
	Class class = NSClassFromString(classname);
	//Construct symbol table.
	if (Nil != class)
	{
		symbols = [[LKObjectSymbolTable alloc] initForClass:class];
	}
	else
	{
		ASSIGN(symbols,
			   [LKObjectSymbolTable symbolTableForNewClassNamed:classname]);
	}
	FOREACH(methods, method, LKAST*)
	{
		[method setParent:self];
		[method check];
	}
}
- (NSString*) description
{
	NSMutableString *str = [NSMutableString stringWithFormat:@"%@ extend [ \n",
		classname];
	FOREACH(methods, method, LKAST*)
	{
		[str appendString:[method description]];
	}
	[str appendString:@"\n]"];
	return str;
}
- (void*) compileWith:(id<LKCodeGenerator>)aGenerator
{
	[aGenerator createCategoryOn:classname
	                       named:categoryName];
	FOREACH(methods, method, LKAST*)
	{
		[method compileWith:aGenerator];
	}
	[aGenerator endCategory];
	if ([[LKAST code] objectForKey: classname] == nil)
	{
		[[LKAST code] setObject: [NSMutableArray array] forKey: classname];
	}
	[[[LKAST code] objectForKey: classname] addObject: self];
	return NULL;
}
- (void) visitWithVisitor:(id<LKASTVisitor>)aVisitor
{
	[self visitArray:methods withVisitor:aVisitor];
}
@end
