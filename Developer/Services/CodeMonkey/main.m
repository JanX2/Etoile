#import <AppKit/AppKit.h>
#import <SmalltalkKit/SmalltalkKit.h>
#import <LanguageKit/LKMessageSend.h>

@interface NSFont (italic)
- (NSFont*) italic;
@end

@implementation NSFont (italic)
- (NSFont*) italic
{
	NSFontManager* fm = [NSFontManager sharedFontManager];
	return [fm convertFont: self toHaveTrait: NSItalicFontMask];
}
@end

int main (int argc, char** argv)
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	[SmalltalkCompiler loadApplicationScriptNamed: @"PrettyPrint"];
	[pool release];
	return NSApplicationMain(argc, (const char**) argv);
}
