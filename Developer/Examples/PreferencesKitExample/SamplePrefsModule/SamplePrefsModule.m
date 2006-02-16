
#import <Foundation/NSDebug.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSValue.h>

#import <AppKit/NSButton.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSOpenPanel.h>

#import "SamplePrefsModule.h"


@interface SamplePrefsModule (Private)
- (void) initWithUI;
@end

@implementation SamplePrefsModule

static SamplePrefsModule		*sharedInstance = nil;
static id <PrefsApplication>	owner = nil;

- (id) initWithOwner: (id <PrefsApplication>) anOwner
{
	if (sharedInstance) {
		[self dealloc];
	} else {
		self = [super init];
		owner = anOwner;
		controller = [owner prefsController];
		[controller registerPrefsModule: self];
        
        [self initUI];
		// window can be any size, as long as it's 486x228 :)
		view = [[window contentView] retain];
        [view removeFromSuperview];

		sharedInstance = self;
	}
	return sharedInstance;
}

- (void) initUI
{
    if ([NSBundle loadNibNamed: @"SamplePrefsModule" owner: self] == NO) 
    {
        NSLog (@"Impossible to load nib for SamplePrefsModule.");
        [self dealloc];
    }
}

- (void) showView: (id) sender;
{
	[controller setCurrentModule: self];
	[view setNeedsDisplay: YES];
}

- (NSView *) view
{
	return view;
}

- (NSString *) buttonCaption
{
	return @"My Preferences Module";
}

- (NSImage *) buttonImage
{
    // FIXME: the next line doesn't work on GNUstep
    // return [NSImage imageNamed: @"Preferences.tiff"];
    
    NSString *path = [[NSBundle bundleForClass: [SamplePrefsModule class]] 
        pathForImageResource: @"Preferences.tiff"];
        
    return [[[NSImage alloc] initWithContentsOfFile: path] autorelease];
}

- (SEL) buttonAction
{
	return @selector(showView:);
}


@end	// SamplePrefsModule
