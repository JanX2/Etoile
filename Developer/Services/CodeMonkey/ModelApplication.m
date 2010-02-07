#import <LanguageKit/LanguageKit.h>
#import "ModelApplication.h"
#import "ModelClass.h"
#import "IDE.h"

@interface LKAST (pretty)
- (NSMutableAttributedString*) prettyprint;
@end

@implementation ModelApplication

- (id) init
{
	self = [super init];
	nibs = [NSMutableArray new];
	path = nil;
	mainNibIndex = -1;
	return self;
}

- (void) dealloc
{
	[nibs release];
	[super dealloc];
}

- (void) addNib
{
	NSLog(@"addNib in app");
	NSString* nibName = nil;
	BOOL correctName = NO;
	int attempts = 1;
	while (!correctName) {
		nibName = [NSString stringWithFormat: @"newNib%d", attempts];
		if (![nibs containsObject: nibName])
			correctName = YES;
		else
			attempts++;
	}
	NSLog(@"added nib %@", nibName);
	[nibs addObject: nibName];
}

- (void) renameNibAtIndex: (int) index withName: (NSString*) aName
{
	if (index < 0 || index > [nibs count]) return;
	if (![nibs containsObject: aName]) {
		[nibs replaceObjectAtIndex: index withObject: aName];
		return;
	}
	return;
}

- (void) removeNibAtIndex: (int) index
{
	if (index != -1 && index < [nibs count])
		[nibs removeObjectAtIndex: index];
}

- (void) editNibAtIndex: (int) index
{
	if (index != -1 && index < [nibs count]) {
		[self ensureExists];
		NSString* nib = [nibs objectAtIndex: index];
		NSString* nibPath = [NSString stringWithFormat: @"%@/Resources/%@.gorm", path, nib];
		[[NSWorkspace sharedWorkspace] openFile: nibPath];
	}
}

- (void) makeMainNibAtIndex: (int) index
{
	if (index != -1 && index < [nibs count])
		mainNibIndex = index;
}

- (void) setPath: (NSString*) aPath
{
	[aPath retain];
	[path release];
	path = aPath;
}

- (void) setName: (NSString*) aName
{
	[aName retain];
	[name release];
	name = aName;
}

- (void) ensureExists
{
	if ([path length]) return;

	NSSavePanel* panel = [NSSavePanel savePanel];
	[panel setRequiredFileType: @"app"];
	if ([panel runModal] == NSFileHandlingPanelOKButton) 
	{
		NSLog(@" save file <%@>", [panel filename]);
		[self setPath: [panel filename]];
		[self generateAppBundle]; 
	}
}

- (void) generateBundleExecutable
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* executable = [[path lastPathComponent] stringByDeletingPathExtension];
	NSString* mainPath = [NSString stringWithFormat: @"%@/%@", path, executable];
	NSString* edlc = @"#!/bin/sh\nedlc -b `dirname $0`";
	[edlc writeToFile: mainPath atomically: YES];
	[fm changeFileAttributes: [NSDictionary dictionaryWithObject:
		 [NSNumber numberWithInt: 511] forKey: NSFilePosixPermissions] atPath: mainPath];
}

- (void) generateBundleClasses
{
	NSMutableString* lkclasses = [NSMutableString stringWithString: @"{\nSources = ("];
	NSArray* classes = [[IDE default] classes];
	NSString* principalClass = nil;
	for (int i=0; i<[classes count]; i++) {
	    ModelClass* class = [classes objectAtIndex: i];
	    NSMutableString* output = [NSMutableString new];
	    NSString* representation = [class representation];
	    id compiler = [LKCompiler compilerForLanguage: @"Smalltalk"];
	    id parser = [[[compiler parserClass] new] autorelease];
	    LKAST* ast = [parser parseString: representation];
	    [output appendString: [[ast prettyprint] string]];
	    NSString* fileName = [NSString stringWithFormat: @"%@/Resources/%@.st", path, [class name]];
	    [output writeToFile: fileName atomically: YES];
	    if (i>0)
		[lkclasses appendString: @", "];
	    [lkclasses appendString: [NSString stringWithFormat: @"\"%@.st\"", [class name]]];
	    if (i==0)
		principalClass = [NSString stringWithString: [class name]];
	}
	[lkclasses appendString: [NSString stringWithFormat: @");\nPrincipalClass=%@;\n}", principalClass]];
	NSString* lkclassesPath = [NSString stringWithFormat: @"%@/Resources/LKInfo.plist", path];
	[lkclasses writeToFile: lkclassesPath atomically: YES];
}

- (void) generateBundleInfosGNUstep
{
	NSString* infoGnustepPath = [NSString stringWithFormat: @"%@/Resources/Info-gnustep.plist", path];
	if ([nibs count] && mainNibIndex == -1)
		mainNibIndex = 0;

	if (mainNibIndex != -1) {
		NSString* mainNibName = [nibs objectAtIndex: mainNibIndex];
	        NSString* infoGnustepContent = [NSString stringWithFormat: @"{ NSMainNibFile=%@; }", mainNibName];
		[infoGnustepContent writeToFile: infoGnustepPath atomically: YES]; 
	} else {
		[@"{}" writeToFile: infoGnustepPath atomically: YES];
	}
}

- (void) generateNibs
{
	for (int i=0; i<[nibs count]; i++)
	{
		NSFileManager* fm = [NSFileManager defaultManager];
                NSString *defaultNibPath = [[NSBundle mainBundle] pathForResource: @"default" ofType: @"gorm"];
		if (nil == path) return;
		NSString *finalPath = [NSString stringWithFormat: @"%@/Resources/%@.gorm",
					path, [nibs objectAtIndex: i]];
		if (![fm fileExistsAtPath: finalPath]) {
			[fm copyPath: defaultNibPath toPath: finalPath handler: nil];
		}
	}
}

- (void) generateAppBundle
{
	NSFileManager* fm = [NSFileManager defaultManager];
	NSString* rscPath = [NSString stringWithFormat: @"%@/Resources", path];
	[fm createDirectoryAtPath: path attributes: nil];
	[fm createDirectoryAtPath: rscPath attributes: nil];
	[self generateBundleExecutable];
	[self generateBundleClasses];
	[self generateBundleInfosGNUstep];
	[self generateNibs];
}

- (void) addNib: (NSString*) aName
{
	// copy the default nib
	// [[NSBundle mainBundle] pathForResource: nibName
}

- (NSArray*) nibs
{
	return nibs;
}


@end
