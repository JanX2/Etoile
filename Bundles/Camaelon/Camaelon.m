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

- (NSString*) themePath { return themePath; }

- init
{
    NSLog(@"Camaelon Theme Engine v2.0 04/02/05 - nicolas@roard.com\n");

    self = [super init];

    [Image setNSImageClass : [NSImage class]];
    [Image poseAsClass: [NSImage class]];

    NSColorList* systemColors = [NSColorList colorListNamed: @"System"];
    [systemColors setColor: [NSColor whiteColor] forKey: @"selectedControlColor"];
    [systemColors setColor: [NSColor whiteColor] forKey: @"selectedTextColor"];

    NSLog (@"Camaelon dictionary: %@",[[NSUserDefaults standardUserDefaults] persistentDomainForName: @"Camaelon"]);

	NSDictionary* dict = [[NSUserDefaults standardUserDefaults] 
		persistentDomainForName: @"Camaelon"];
    ASSIGN (themeName, [dict objectForKey: @"Theme"]);

	NSLog (@"themeName: %@", themeName);

    NSString* path = [[NSString stringWithFormat: @"~/GNUstep/Library/Themes/%@.theme/", 
    			themeName] stringByExpandingTildeInPath];
	
	ASSIGN (themePath, path);

	NSLog (@"themePath: %@", themePath);

    theme = self;
    return self;
}

@end
