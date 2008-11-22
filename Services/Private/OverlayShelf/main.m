#import <EtoileFoundation/EtoileFoundation.h>
#import <AppKit/AppKit.h>
#import <SmalltalkKit/SmalltalkKit.h>

int main(int argc, char **argv)
{
	[[NSAutoreleasePool alloc] init];

	[[NSUserDefaults standardUserDefaults]
		setObject: [NSNumber numberWithBool: YES] forKey: @"GSSuppressAppIcon"];

	[SmalltalkCompiler loadAllScriptsForApplication];
	[[NSClassFromString(@"OverlayShelfController") alloc] init];

	return NSApplicationMain(argc,  (const char **) argv);
}

