#import <EtoileFoundation/EtoileFoundation.h>
#import <LanguageKit/LKCompiler.h>
#import <AppKit/AppKit.h>

int main(int argc, char **argv)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[LKCompiler loadLanguageKitBundle: [NSBundle mainBundle]];

	int ret = NSApplicationMain(argc, (const char **) argv);
	[pool release];
	return ret;
}
