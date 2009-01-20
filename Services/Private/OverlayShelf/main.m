#import <EtoileFoundation/EtoileFoundation.h>
#import <LanguageKit/LKCompiler.h>
#import <AppKit/AppKit.h>

int main(int argc, char **argv)
{
	[[NSAutoreleasePool alloc] init];

	[[NSUserDefaults standardUserDefaults]
		setObject: [NSNumber numberWithBool: YES] forKey: @"GSSuppressAppIcon"];

	[LKCompiler loadAllScriptsForApplication];
	[[NSClassFromString(@"OverlayShelfController") alloc] init];

	return NSApplicationMain(argc,  (const char **) argv);
}

