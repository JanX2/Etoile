#import <EtoileFoundation/EtoileFoundation.h>
#import <AppKit/AppKit.h>
#import <SmalltalkKit/SmalltalkKit.h>

extern int DEBUG_DUMP_MODULES;

static BOOL compileString(NSString *s)
{
	Parser * p = [[Parser alloc] init];
	AST *ast;
	NS_DURING
		ast = [p parseString: s];
	NS_HANDLER
		NSDictionary *e = [localException userInfo];
		NSLog(@"Parse error in %@ on line %@.  Unexpected token at character %@ while parsing:\n%@",
		                                                                   s,
										   [e objectForKey:@"lineNumber"],
										   [e objectForKey:@"character"],
										   [e objectForKey:@"line"]);
		NS_VALUERETURN(NO, BOOL);
	NS_ENDHANDLER	
	id cg = defaultCodeGenerator();
	DEBUG_DUMP_MODULES = 0;
	[ast compileWith:cg];
	return YES;
}

int main(int argc, char **argv)
{
	[NSAutoreleasePool new];
	NSString *Program = [NSString stringWithContentsOfFile:@"Melodie.st"];
	if (!compileString(Program))
	{
		NSLog(@"Failed to compile Melodie.st");
		return 2;
	}

	return NSApplicationMain(argc, (const char **) argv);
}
