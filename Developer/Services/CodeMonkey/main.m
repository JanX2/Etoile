#import <AppKit/AppKit.h>
#import <SmalltalkKit/SmalltalkKit.h>
#import <LanguageKit/LKMessageSend.h>

int main (int argc, char** argv)
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	[SmalltalkCompiler loadApplicationScriptNamed: @"PrettyPrint"];
	[pool release];
	return NSApplicationMain(argc, (const char**) argv);
}
