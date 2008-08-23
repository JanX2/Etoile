#import <EtoileFoundation/EtoileFoundation.h>
#import <AppKit/AppKit.h>
#import <SmalltalkKit/SmalltalkKit.h>

int main(int argc, char **argv)
{
	id pool = [NSAutoreleasePool new];
	[SmalltalkCompiler loadApplicationScriptNamed:@"Melodie"];
	[pool release];

	return NSApplicationMain(argc, (const char **) argv);
}
