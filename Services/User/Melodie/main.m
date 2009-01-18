#import <EtoileFoundation/EtoileFoundation.h>
#import <AppKit/AppKit.h>
#import <LanguageKit/LanguageKit.h>

void load(NSString *file) {
	NSLog(@"Loading %@", file);
	[[LKCompiler compilerForLanguage:@"Smalltalk"] 
		loadApplicationScriptNamed:file];
}

int main(int argc, char **argv)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	load(@"ETPlaylist");
	load(@"MusicPlayerController");
	load(@"MelodieController");
	NSLog(@"Loaded smalltalk scripts.");
	
	int ret = NSApplicationMain(argc, (const char **) argv);
	[pool release];
	return ret;
}
