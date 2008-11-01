#import <EtoileFoundation/EtoileFoundation.h>
#import <AppKit/AppKit.h>
#import <SmalltalkKit/SmalltalkKit.h>

int main(int argc, char **argv)
{
	[SmalltalkCompiler loadAllScriptsForApplication];
	NSLog(@"Loaded smalltalk scripts.");
	return NSApplicationMain(argc, (const char **) argv);
}
