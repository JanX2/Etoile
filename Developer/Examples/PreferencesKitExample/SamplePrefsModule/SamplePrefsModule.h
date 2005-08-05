#import <AppKit/NSNibDeclarations.h>
#import <PreferencesKit/PrefsModule.h>

@interface SamplePrefsModule: NSObject <PrefsModule>
{
	IBOutlet id				window;
	IBOutlet id				view;
	id <PrefsController>	controller;
}

@end
