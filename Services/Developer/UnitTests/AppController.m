/* All Rights reserved */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "PreferencesController.h"
#import "AppController.h"

static NSUserDefaults *ud = nil;
static NSNotificationCenter *nc = nil;

/*
 * NSScanner extensions category
 */
 
@interface NSScanner (UnitTestsExtensions)
- (BOOL) checkStrings: (NSArray *)strings stopForNewLine: (BOOL)stop;
- (BOOL) checkString: (NSString *)string stopForNewLine: (BOOL)stop;
@end

@implementation NSScanner (UnitTestsExtensions)

- (BOOL) checkStrings: (NSArray *)strings stopForNewLine: (BOOL)stop
{
	NSEnumerator *e = [strings objectEnumerator];
	NSString *str;
	
	while ((str = [e nextObject]) != nil)
	{
		if ([self checkString: str stopForNewLine: stop])
			return YES;
	}
	
	return NO;
}

- (BOOL) checkString: (NSString *)string stopForNewLine: (BOOL)stop
{
	int location = [self scanLocation];
	BOOL isFound = NO;
	NSCharacterSet *cset;
	
	if (stop)
	{
		cset = [[self charactersToBeSkipped] retain];
		[self setCharactersToBeSkipped: [NSCharacterSet whitespaceCharacterSet]];
	}
	
	NSString *checked = nil;
	if ([self isAtEnd] == NO && [self scanUpToString: string intoString: &checked])
		isFound = YES;
	
	//NSDebugLog(@"checkString:ForNewLine: %d checked %@", stop, checked);

	[self setScanLocation: location];
		
	if (stop)
	{
		[self setCharactersToBeSkipped: cset];
		[cset release];
	}
	
	return isFound;
}

@end

/*
 * AppController implementation
 */

@implementation AppController

- (void) awakeFromNib
{
	NSString *defaultSet;
	
	NSLog(@"AppController awakeFromNib");
	
	// FIXME: We aren't able to read NSRegistration domain set in
	// +[PreferencesController initialize], may be it is a GNUstep bug
	//ud = [[NSUserDefaults standardUserDefaults] retain];
	ud = [preferencesController userDefaults];
	nc = [[NSNotificationCenter defaultCenter] retain];
	
	[nc addObserver: self selector: @selector(testsSetsChanged:) 
		name: TestsSetsChangedNotification object: nil];

	[self testsSetsChanged: nil]; // Init popup tests sets menu
	
	[self showPreferencesPanel: nil];
}

- (void) showPreferencesPanel: (id)sender
{
	[preferencesPanel makeKeyAndOrderFront: self];
}

- (void) popupTestsSets: (id)sender
{
	NSString *key;
	
	if ([sender indexOfSelectedItem] == 0)
	{
		 key = @"Default";
	}
	else
	{
		key = [[sender selectedItem] title];
	}
	
	NSDebugLog(@"popupTestsSet with key %@", key);
	
	if ([key isEqualToString: [ud stringForKey: ActiveTestsSetDefault]] == NO)
	{
		NSLog(@"Sync default for popup");
		[ud setObject: key forKey: ActiveTestsSetDefault];
		[ud synchronize];
		[self noLight];
	}
}

- (void) testsSetsChanged: (NSNotification *)not
{	
	NSDictionary *variousTests = [ud dictionaryForKey: TestsSetsDefault];
	NSArray *testsSetsNames = [variousTests allKeys];
	NSEnumerator *e = [testsSetsNames reverseObjectEnumerator];
	NSString *testsSetName;
	NSString *defaultSetName = [ud stringForKey: ActiveTestsSetDefault];
	
	NSDebugLog(@"testsSetsChanged: %@", testsSetsNames);
	
	while ([popupTestsSets numberOfItems] != 1)
		[popupTestsSets removeItemAtIndex: [popupTestsSets numberOfItems] - 1]; 
	
	while ((testsSetName = [e nextObject]) != nil)
	{
		if ([testsSetName isEqualToString: @"Default"] == NO)
			[popupTestsSets addItemWithTitle: testsSetName];
	}
	
	if ([defaultSetName isEqualToString: @"Default"])
	{
		[popupTestsSets selectItemAtIndex: 0];
	}
	else
	{
		[popupTestsSets selectItemWithTitle: defaultSetName];
	}
}

#define UNKNOWN 0
#define PASSED  2
#define FAILED  4
#define WARNING 6

- (NSArray*) scanOutput: (NSString*) str
{	
	NSLog (@"SCAN : <%@>", str);
	
	NSString* Failed   = @".fail";
	NSString* Passed   = @".pass";
	NSString* warning  = @": warning:";
	NSString* postWarning  = @":: warning:";
	NSString* Result   = @"Result";
	NSString* ukrun    = @"ukrun";
	NSString* looking  = @"looking";
	NSString* classes  = @"classes,";
	NSString* methods  = @"methods,";
	NSString* tests    = @"tests,";
	NSString* failed   = @"failed";
	NSString* fileName = nil;
	NSString* resultString = nil;	
	NSMutableArray* results = [[NSMutableArray alloc] init];

	int testLine   = 0;
	int nbClasses  = 0;
	int nbMethods  = 0;
	int nbTests    = 0;
	int nbFailures = 0;
	int location   = 0;
	
	BOOL ukrunFound = NO;
	BOOL lookingFound = NO;
	
	NSArray *manyFailed = [NSArray arrayWithObjects: Failed, @"msgUKFail", nil];
	NSArray *manyPassed = [NSArray arrayWithObjects: Passed, @"msgUKPass", nil];
	unsigned int result = UNKNOWN;

	NSScanner* theScanner = [NSScanner scannerWithString: str];
	
	while ([theScanner isAtEnd] == NO)
	{
		result = UNKNOWN;
		fileName = nil;
		int stamp;
		
		// And any NSLog ...
		location = [theScanner scanLocation];
		if([theScanner scanInt: &stamp])
		{
			[theScanner scanUpToString: @"\n" intoString: NULL];
		}
		else [theScanner setScanLocation: location];
		
		// We skip the ukrun first line... 
		location = [theScanner scanLocation];
		if ([theScanner scanString: ukrun intoString: NULL])
		{
			ukrunFound = YES;
			[theScanner scanUpToString: @"\n" intoString: NULL];
		}
		else [theScanner setScanLocation: location];

		// And the looking into bundle line...
		location = [theScanner scanLocation];
		if ([theScanner scanString: looking intoString: NULL])
		{
			lookingFound = YES;
			[theScanner scanUpToString: @"\n" intoString: NULL];
		}
		else [theScanner setScanLocation: location];
	
		// And any NSLog ...
		location = [theScanner scanLocation];
		while ([theScanner scanInt: &stamp])
		{
			[theScanner scanUpToString: @"\n" intoString: NULL];
			location = [theScanner scanLocation];
		}
		
		if (ukrunFound && lookingFound)
		{
			[theScanner scanUpToString: @":" intoString: &fileName];
			[theScanner setScanLocation: [theScanner scanLocation] + 1];
		}
		
		NSDebugLog(@"fileName %@", fileName);
		
		if ([fileName isEqualToString: Result])
		{
			// It could be the result line:
			// Result: 1 classes, 1 methods, 2 tests, 1 failed

			[theScanner scanInt: &nbClasses];
			[theScanner scanString: classes intoString: NULL];
			[theScanner scanInt: &nbMethods];
			[theScanner scanString: methods intoString: NULL];
			[theScanner scanInt: &nbTests];
			[theScanner scanString: tests intoString: NULL];
			[theScanner scanInt: &nbFailures];
			[theScanner scanString: failed intoString: NULL];
			[theScanner scanUpToString: @"\n" intoString: NULL];

			NSMutableDictionary* test = [[NSMutableDictionary alloc] init];
			
			[test setObject: [NSString stringWithString: fileName] 
				 forKey: @"file"];
			[test setObject: [NSNumber numberWithInt: nbClasses] 
				 forKey: @"nbclasses"];
			[test setObject: [NSNumber numberWithInt: nbMethods] 
				 forKey: @"nbmethods"];
			[test setObject: [NSNumber numberWithInt: nbTests] 
				 forKey: @"nbtests"];
			[test setObject: [NSNumber numberWithInt: nbFailures] 
				 forKey: @"nbfailures"];
			[results addObject: test];
			[test release];
		}
		else if (fileName != nil)
		{
			// Or it could be a test line:
			// main.m:21: warning: Failed, expected 41, got 42
			// main.m:22 Passed, expected 42, got 42

			[theScanner scanInt: &testLine];
			location = [theScanner scanLocation];

			// We check eventual pre warning now...
			if ([theScanner scanString: warning intoString: NULL]) 
			{
				result |= WARNING;	
			}
			else
			{
				// FIXME: there is may be a bug in GNUstep here because we get
				// an out of range exception when location has the scanning 
				// process end value.
				// We avoid it with [theScanner isAtEnd] workaround test case
				if ([theScanner isAtEnd] == NO)
					[theScanner setScanLocation: location];
			}

			if ([theScanner checkStrings: manyPassed stopForNewLine: YES]) 
			{
				result |= PASSED;
			}
			else if ([theScanner checkStrings: manyFailed stopForNewLine: YES]) 
			{	
				result |= FAILED;
			}

			// FIXME: there is may be a bug in GNUstep here because we get
			// an out of range exception when location has the scanning 
			// process end value.
			// We avoid it with [theScanner isAtEnd] workaround test case
			if ([theScanner isAtEnd] == NO)
			{
				[theScanner setScanLocation: location];
				[theScanner scanUpToString: @"\n" intoString: &resultString];
				
				location = [theScanner scanLocation];
			}
			else
			{
				resultString = @"";
			}
			
			// We check eventual post warning now (located on next line)...
			if ([theScanner scanString: postWarning intoString: NULL]) 
			{
				NSString *postErr = @"";
				
				result |= WARNING;	
				[theScanner scanUpToString: @"\n" intoString: &postErr];
				postErr = [@" " stringByAppendingString: postErr];
				resultString = [resultString stringByAppendingString: postErr];
			}
			else if ([theScanner isAtEnd] == NO) // FIXME: Not really pretty.
			{
				[theScanner setScanLocation: location];	
			}	
			
			NSDebugLog (@"\nfile : %@", fileName);
			NSDebugLog (@"line : %d", testLine);
			NSDebugLog (@"res  : %@", resultString);
			NSDebugLog (@"result : %x\n", result);
			
			NSMutableDictionary* test = [[NSMutableDictionary alloc] init];

			[test setObject: [NSString stringWithString: fileName] 
				 forKey: @"file"];
			[test setObject: [NSNumber numberWithInt: testLine] 
				 forKey: @"line"];
			[test setObject: [NSString stringWithString: resultString]
				 forKey: @"result"];

			if (result & FAILED)
			{
				[test setObject: @"Failed" forKey: @"status"];
			}	
			else if (result & PASSED) 
			{
				[test setObject: @"Passed" forKey: @"status"];
			}

			[results addObject: test];
			[test release];
		}

	}

	return results;
	
}

- (void) redLight
{
	[status setColor: [NSColor redColor]];
}

- (void) greenLight
{
	[status setColor: [NSColor greenColor]];
}

- (void) noLight
{
	[status setColor: [NSColor blackColor]];
}

- (void) runTests: (id)sender
{
	NSTask *ukrun = [NSTask new];
	NSArray *variousTests = [[ud objectForKey: TestsSetsDefault] 
		objectForKey: [ud objectForKey: ActiveTestsSetDefault]];
	NSArray *args = [variousTests valueForKey: @"path"];
	
	NSLog(@"Tests sets %@", [ud objectForKey: TestsSetsDefault]);
	NSLog(@"Active tests set %@", [ud objectForKey: ActiveTestsSetDefault]);
	NSLog(@"Run tests with bundles %@", [[ud objectForKey: TestsSetsDefault] objectForKey: ActiveTestsSetDefault]);
	
	NSString *path = [ud stringForKey: ToolPathDefault];
	NSLog (@"ukrun default path : %@", path);
	
	BOOL isDir;
	if (path == nil 
		|| [[NSFileManager defaultManager] fileExistsAtPath: path isDirectory: &isDir] == NO)
	{
		NSLog(@"Try system provided ukrun path");
		
		path = [[NSWorkspace sharedWorkspace] fullPathForApplication: @"ukrun"];
	}
	
	NSLog (@"ukrun path : %@", path);
	
	[ukrun setLaunchPath: path];
	[ukrun setArguments: args];
	
	NSData* inData;
	NSFileHandle* readHandle;
	NSPipe* pipe;

	pipe = [NSPipe pipe];
	readHandle = [pipe fileHandleForReading];
	
	[ukrun setStandardOutput: pipe];	
	[ukrun setStandardError: pipe];	

	[ukrun launch];

	while ((inData = [readHandle availableData]) && [inData length])
	{
		NSString* str = [[NSString alloc] initWithData: inData encoding: NSISOLatin1StringEncoding];
		
		resultsTests = [self scanOutput: str];
		
		[list reloadData];
		
		int i;
		for (i=0; i< [resultsTests count]; i++)
		{
			NSDictionary* test = [resultsTests objectAtIndex: i];
			
			if ([[test objectForKey: @"file"] isEqualToString: @"Result"])
			{
				int nbfailures = [[test objectForKey: @"nbfailures"] 
							intValue];
							
				nbfailures > 0 ? [self redLight] : [self greenLight];
				
				NSString* sum = [NSString stringWithFormat: 
					@"%@ classes, %@ methods, %@ tests, %@ failed", 
					[test objectForKey: @"nbclasses"],
					[test objectForKey: @"nbmethods"],
					[test objectForKey: @"nbtests"],
					[test objectForKey: @"nbfailures"]
					];
				 
				[summary setStringValue: sum];
			}
		}	
	}
	
	[ukrun release];
}

- (id) tableView: (NSTableView*) tv objectValueForTableColumn: (NSTableColumn*) tc
	row: (int) row
{
	if (row < [resultsTests count])
	{
		NSDictionary* test = [resultsTests objectAtIndex: row];

		if ([[tc identifier] isEqualToString: @"file"])
			return [test objectForKey: @"file"];

		if ([[tc identifier] isEqualToString: @"line"])
			return [test objectForKey: @"line"];
			
		if ([[tc identifier] isEqualToString: @"status"])
			return [test objectForKey: @"status"];
			
		if ([[tc identifier] isEqualToString: @"reason"])
			return [test objectForKey: @"result"];
	}
	
	return nil;
}

- (int) numberOfRowsInTableView: (NSTableView*) tv
{
	return [resultsTests count] - 1;
}

- (void) tableView: (NSTableView*) tv willDisplayCell: (id) cell 
	forTableColumn: (NSTableColumn*) tc row: (int) row
{
	if (row < [resultsTests count])
	{
		NSDictionary* test = [resultsTests objectAtIndex: row];
		
		[cell setDrawsBackground: YES];

		if ([[test objectForKey: @"status"] isEqualToString: @"Passed"])
		{
			[cell setBackgroundColor: [NSColor greenColor]];
		}
		else if ([[test objectForKey: @"status"] isEqualToString: @"Failed"])
		{
			[cell setBackgroundColor: [NSColor redColor]];
		}
	}
}

@end
