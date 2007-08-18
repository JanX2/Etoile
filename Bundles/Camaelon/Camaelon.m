#include "Camaelon.h"

@implementation Camaelon

#define ThemeExtension (@"theme")

static Camaelon* theme;


+ (Camaelon*) sharedTheme
{
	if (theme == nil)
	{
		theme = [[self alloc] init];
	}
	return theme;
}

- (NSString *) themePath 
{ 
	if (themePath == nil)
	{
		NSArray* paths = NSSearchPathForDirectoriesInDomains(NSAllLibrariesDirectory, 
			NSAllDomainsMask & ~NSNetworkDomainMask, YES);   
		NSString *path;
		NSEnumerator *e = [paths objectEnumerator];
		NSFileManager *fm = [NSFileManager defaultManager];
		BOOL themeFound = NO;
		BOOL isDir;
		
		while ((path = [e nextObject]) != nil)
		{
			path = [path stringByAppendingPathComponent: @"Themes"];
			path = [path stringByAppendingPathComponent: themeName];
			path = [path stringByAppendingPathExtension: ThemeExtension];	
			if ([fm fileExistsAtPath: path isDirectory:	&isDir])
			{
				themeFound = YES;
				break;
			}
		}
		
		if (themeFound == NO)
		{
			NSDebugLLog (@"Theme", @"No theme %@ found in search paths: %@", themeName, paths);

			/* We use a default theme in resource.
		 	 * We don't use main bundle because Camaelon is loaded
			 * by other applications. */
			paths = [[NSBundle bundleForClass: [self class]] pathsForResourcesOfType: ThemeExtension inDirectory: nil];
			e = [paths objectEnumerator];
			while ((path = [e nextObject]))
			{
				if ([[[path lastPathComponent] stringByDeletingPathExtension] isEqualToString: themeName])
				{
					themeFound = YES;
					break;
				}
			}
			if ((themeFound == NO) && ([paths count] > 0))
			{
				path = [paths objectAtIndex: 0];
				themeFound = YES;
			}
		}
		if (themeFound == NO)
		{
		   NSLog(@"Internal Error: Cannot found theme");
		   /* Something is wrong because default theme should come 
                      with this bundle */
		   return nil;
		}
		
		ASSIGN (themePath, path);	
		NSDebugLLog(@"Theme", @"Found theme with path: %@", themePath);		
	}
	
	return themePath;
}

+ (void) initialize
{
    [CLImage setNSImageClass : [NSImage class]];
    [CLImage poseAsClass: [NSImage class]];
    [NSColor setSystemColorList];
}

- (id) init
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary* dict = [defaults persistentDomainForName: @"Camaelon"];
    
    //NSLog(@"Camaelon Theme Engine v2.0pre 20/11/05 - nicolas@roard.com\n");
    
    self = [super init];
    
    //[CLImage setNSImageClass : [NSImage class]];
    //[CLImage poseAsClass: [NSImage class]];
    
    //NSLog (@"Camaelon dictionary: %@", dict);
   
    NSNumber* themeActive = [dict objectForKey: @"Activated"];
    if ((themeActive == nil) || ([themeActive boolValue] == YES))
    {   
    	/* Preventive check: Remove possible incorrect path extension set by user in 
       	   NSDefaults. */
        ASSIGN (themeName, [[dict objectForKey: @"Theme"] stringByDeletingPathExtension]);
	//NSLog (@"Theme named %@ is set in defaults", themeName);
	themePath = [self themePath];
	if (themePath == nil)
	{
		RELEASE(self);
		return nil;
	}
		
	theme = self;
    }
    else
    {
	NSLog (@"Camaelon is not activated");
	return nil;
    }
    
//    [GSDrawFunctions setTheme: [CamaelonDrawFunctions new]];
//    [NSApplication setTheme: [GSDrawFunctions new]];
    
    return self;
}

@end
