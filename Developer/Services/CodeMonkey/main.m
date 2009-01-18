#import <AppKit/AppKit.h>
#import <SmalltalkKit/SmalltalkKit.h>
#import <LanguageKit/LKMessageSend.h>

int main (int argc, char** argv)
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	[SmalltalkCompiler loadApplicationScriptNamed: @"PrettyPrintWriter"];
	[SmalltalkCompiler loadApplicationScriptNamed: @"PrettyPrintCategories"];
	[pool release];
	return NSApplicationMain(argc, (const char**) argv);
}
