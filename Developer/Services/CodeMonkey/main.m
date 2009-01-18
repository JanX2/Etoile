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

@protocol writer
- (void) red: (NSString*) str;
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
		[writer red: [selector description]];
	}
	else
	{
		[writer red: [sel objectAtIndex: 0]];
	}
	NSLog (@"<%@>(%d)", selector, [arguments count]);
	if ([arguments count])
	{
		[writer red: @": "];
		[[arguments objectAtIndex: 0] prettyprintToWriter: writer];
		//[writer append: [[arguments objectAtIndex: 0] description]];
	}
	for (int i=1; i<[arguments count]; i++)
	{
		if (i < [sel count])
		{
			[writer append: @" "];
			[writer red: [sel objectAtIndex: i]];
		}
		[writer red: @": "];
		//[writer append: [[arguments objectAtIndex: i] description]];
		[[arguments objectAtIndex: i] prettyprintToWriter: writer];
	}	 
}
@end

int main (int argc, char** argv)
{
	NSAutoreleasePool* pool = [NSAutoreleasePool new];
	[SmalltalkCompiler loadApplicationScriptNamed: @"PrettyPrint"];
	[pool release];
	return NSApplicationMain(argc, (const char**) argv);
}
