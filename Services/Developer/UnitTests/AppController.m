/* All Rights reserved */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "PreferencesController.h"
#import "AppController.h"

static NSUserDefaults *ud = nil;
static NSNotificationCenter *nc = nil;

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
	
	NSLog(@"popupTestsSet key %@", key);
	
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
	
	NSLog(@"testsSetsChanged: %@", testsSetsNames);
	
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

#define UNKNOWN 0x000
#define PASSED  0x001
#define FAILED  0x010
#define WARNING 0x100

- (NSArray*) scanOutput: (NSString*) str
{	
	NSLog (@"SCAN : <%@>", str);
	
	NSString* Failed   = @"Failed,";
	NSString* Passed   = @"Passed,";
	NSString* warning  = @": warning:";
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

	unsigned int result = UNKNOWN;

	NSScanner* theScanner = [NSScanner scannerWithString: str];
	
	while ([theScanner isAtEnd] == NO)
	{
		result = UNKNOWN;

		// We skip the ukrun first line... 
		location = [theScanner scanLocation];
		if ([theScanner scanString: ukrun intoString: NULL])
		{
			[theScanner scanUpToString: @"\n" intoString: NULL];
		}
		else [theScanner setScanLocation: location];

		// And the looking into bundle line...
		location = [theScanner scanLocation];
		if ([theScanner scanString: looking intoString: NULL])
		{
			[theScanner scanUpToString: @"\n" intoString: NULL];
		}
		else [theScanner setScanLocation: location];
	
		// And any NSLog ...
		location = [theScanner scanLocation];
		if ([theScanner scanInt: NULL])
		{
			[theScanner scanUpToString: @"\n" intoString: NULL];
		}
		else [theScanner setScanLocation: location];

		// Now we get the first element
		[theScanner scanUpToString: @":" intoString: &fileName];
		[theScanner setScanLocation: [theScanner scanLocation] + 1];

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
		else
		{
			// Or it could be a test line:
			// main.m:21: warning: Failed, expected 41, got 42
			// main.m:22 Passed, expected 42, got 42

			[theScanner scanInt: &testLine];
			location = [theScanner scanLocation];
			if ([theScanner scanString: warning intoString: NULL]) 
			{
				result |= WARNING;	
			}
			else 
			{
				[theScanner setScanLocation: location];
			}
			location = [theScanner scanLocation];

			if ([theScanner scanString: Passed intoString: NULL]) 
			{
				result |= PASSED;
			}
			else 
			{
				[theScanner setScanLocation: location];

				if ([theScanner scanString: Failed intoString: NULL]) 
				{	
					result |= FAILED;
				}
			}

			[theScanner scanUpToString: @"\n" intoString: &resultString];

			NSLog (@"\nfile : %@", fileName);
			NSLog (@"line : %d", testLine);
			NSLog (@"res  : %@", resultString);
			NSLog (@"result : %x\n", result);

			if (fileName != nil)
			{
				NSMutableDictionary* test = [[NSMutableDictionary alloc] init];
				
				[test setObject: [NSString stringWithString: fileName] 
					 forKey: @"file"];
				[test setObject: [NSNumber numberWithInt: testLine] 
					 forKey: @"line"];
				[test setObject: [NSString stringWithString: resultString]
					 forKey: @"result"];
					 
				if (result & FAILED)
					[test setObject: @"Failed" forKey: @"status"];
				if (result & PASSED)
					[test setObject: @"Passed" forKey: @"status"];
					
				[results addObject: test];
				[test release];
			}
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
			NSLog (@"green cell");
			[cell setBackgroundColor: [NSColor greenColor]];
		}
		else
		{
			NSLog (@"red cell");
			[cell setBackgroundColor: [NSColor redColor]];
		}
	}
}

@end
