#import <AppKit/AppKit.h>
#import <LanguageKit/LanguageKit.h>

void loadScript(NSString* name) {
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType: @"st"];
        if (nil == path)
        {
                NSLog(@"Unable to find %@.%@ in bundle %@.", name, @"st", [NSBundle mainBundle]);
                return;
        }
        [[LKCompiler compilerForExtension: @"st"] compileString:[NSString stringWithContentsOfFile:path]];
}
int main (int argc, char** argv)
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	loadScript(@"PrettyPrintWriter");
	loadScript(@"PrettyPrintCategories");
	[pool release];
	return NSApplicationMain(argc, (const char**) argv);
}
