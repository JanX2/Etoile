#import <EtoileFoundation/EtoileFoundation.h>

@interface LangaugeKit : NSObject {}
+ (BOOL) loadPluginsForApplication;
@end

/**
 * Script loader.  Loads LanguageKit if the app doesn't explcitily link to it
 * and it is installed, and then loads all LanguageKit plugin bundles for this
 * application.
 */
@interface ETScriptLoader : NSObject {}
@end
@implementation ETScriptLoader
+ (void) initialize
{
	Class LKCompiler = NSClassFromString(@"LKCompiler");
	if (Nil == LKCompiler)
	{
		NSFileManager *fm = [NSFileManager defaultManager];
		NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
			NSAllDomainsMask, YES);
		FOREACH(dirs, dir, NSString*)
		{
			NSString *f = 
				[[[dir stringByAppendingPathComponent:@"Frameworks"]
					stringByAppendingPathComponent:@"LanguageKit"]
						stringByAppendingPathExtension:@"framework"];
			// Check that the framework exists and is a directory.
			BOOL isDir = NO;
			if ([fm fileExistsAtPath:f isDirectory:&isDir] && isDir)
			{
				NSBundle *bundle = [NSBundle bundleWithPath:f];
				if ([bundle load]) 
				{
					break;
				}
			}
		}
		LKCompiler = NSClassFromString(@"LKCompiler");
	}
	[LKCompiler loadPluginsForApplication];
}

@end
