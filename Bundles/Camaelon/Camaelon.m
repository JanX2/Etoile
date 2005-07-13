#include "Camaelon.h"

@implementation Camaelon

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
		
		while ((path = [e nextObject]) != nil)
		{
			BOOL isDir;
			
			path = [path stringByAppendingPathComponent: @"Themes"];
			path = [path stringByAppendingPathComponent: themeName];
			path = [path stringByAppendingPathExtension: @"theme"];	
			if ([fm fileExistsAtPath: path isDirectory:	&isDir])
			{
				themeFound = YES;
				break;
			}
		}
		
		if (themeFound == NO)
		{
		   NSLog (@"No theme %@ found in search paths: %@", themeName, paths);
		   
		   // FIXME: Implement fall back on NeXT default theme. We probably need to 
		   // hack a bit with the runtime in order to reactivate overriden methods (by
		   // Camaelon categories).
		   
		   return nil;
		}
		
		ASSIGN (themePath, path);	
		NSLog (@"Found theme with path: %@", themePath);		
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
    NSBundle *hostBundle;
    
    NSLog(@"Camaelon Theme Engine v2.0 13/07/05 - nicolas@roard.com\n");
    
    self = [super init];
    
    /*
     * Warn Camaelon needs to be disabled with Gorm.
     * FIXME: Makes Camaelon compatible with Gorm.
     */
     
    hostBundle = [NSBundle mainBundle];
    /*
    if ([[[hostBundle infoDictionary] objectForKey: @"ApplicationName"] 
    	isEqualToString: @"Gorm"])
    {    
        NSLog(@"Camaelon isn't supported with Gorm currently, then theme won't \
        	be loaded");
        
		RELEASE(self);
        return nil;
    }
    */
    
    //[CLImage setNSImageClass : [NSImage class]];
    //[CLImage poseAsClass: [NSImage class]];
    
    NSLog (@"Camaelon dictionary: %@", dict);
   
    /* Preventive check: Remove possible incorrect path extension set by user in 
       NSDefaults. */
    ASSIGN (themeName, [[dict objectForKey: @"Theme"] stringByDeletingPathExtension]);
    
	NSLog (@"Theme named %@ is set in defaults", themeName);
    
    themePath = [self themePath];
    if (themePath == nil)
    {
		RELEASE(self);
		return nil;
	}
    	
    theme = self;
    
    return self;
}

@end
