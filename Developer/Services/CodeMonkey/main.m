#import <AppKit/AppKit.h>
#import <LanguageKit/LanguageKit.h>

@protocol writer
- (void) selectorToken: (NSString*) str;
- (void) append: (NSString*) str;
@end

@interface LKMessageSend (writer)
- (void) prettyprintToWriter: (id<writer>) writer;
@end

@implementation LKMessageSend (writer)
- (void) prettyprintToWriter: (id<writer>) writer
{
	[target prettyprintToWriter: writer];
	[writer append: @" "];
	NSArray* sel = [[selector description] componentsSeparatedByString: @":"];
	if ([sel count] == 1)	
	{
		[writer selectorToken: [selector description]];
	}
	else
	{
		[writer selectorToken: [sel objectAtIndex: 0]];
	}
	NSLog (@"<%@>(%d)", selector, [arguments count]);
	if ([arguments count])
	{
		[writer selectorToken: @": "];
		[[arguments objectAtIndex: 0] prettyprintToWriter: writer];
		//[writer append: [[arguments objectAtIndex: 0] description]];
	}
	for (int i=1; i<[arguments count]; i++)
	{
		if (i < [sel count])
		{
			[writer append: @" "];
			[writer selectorToken: [sel objectAtIndex: i]];
		}
		[writer selectorToken: @": "];
		//[writer append: [[arguments objectAtIndex: i] description]];
		[[arguments objectAtIndex: i] prettyprintToWriter: writer];
	}	 
}
@end
void loadScript(NSString* name) {
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType: @"st"];
        if (nil == path)
        {
                NSLog(@"Unable to find %@.%@ in bundle %@.", name, @"st", [NSBundle mainBundle]);
                return;
        }
        [[[LKCompiler compilerForExtension: @"st"] compiler] compileString:[NSString stringWithContentsOfFile:path]];
}
int main (int argc, char** argv)
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	loadScript(@"PrettyPrintWriter");
	loadScript(@"PrettyPrintCategories");
	[pool release];
	return NSApplicationMain(argc, (const char**) argv);
}
