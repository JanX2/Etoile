/* All Rights reserved */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "PreferencesController.h"

static NSUserDefaults *ud = nil;
static NSMutableDictionary *prefsDict = nil;
static NSNotificationCenter *nc = nil;

/*
 * Notifications
 */
 
NSString *TestsSetsChangedNotification = @"UnitTestsTestsSetsChanged";

/*
 * Defaults
 */

NSString *ToolPathDefault = @"ToolPath";
NSString *TestsSetsDefault = @"TestsSets";
NSString *ActiveTestsSetDefault = @"ActiveTestsSet";
NSString *LastEditedTestsSetDefault = @"LastEditedTestsSet";


@implementation PreferencesController

+ (NSDictionary *) defaultValues
{
	NSMutableDictionary *defaultPrefs = [NSMutableDictionary dictionary];
	NSMutableDictionary *emptyTestsSetDict = [NSMutableDictionary dictionary];
	NSMutableArray *variousTests = [NSMutableArray array];
	
	[emptyTestsSetDict setObject: variousTests  forKey: @"Default"]; 
	/* For Default tests set with empty identifier */
	
	[defaultPrefs setObject: @"/GNUstep/Local/Tools/ukrun" forKey: ToolPathDefault];
	[defaultPrefs setObject: emptyTestsSetDict forKey: TestsSetsDefault];
	[defaultPrefs setObject: @"Default" forKey: ActiveTestsSetDefault];
	[defaultPrefs setObject: @"Default" forKey: LastEditedTestsSetDefault];
	
	return defaultPrefs;
}

+ (void) defaultStoreValue: (id)value forKey: (id)key
{
	[ud setObject: value forKey: key];
	[ud synchronize];
}

- (NSUserDefaults *) userDefaults
{
	return ud;
}

+ (void) initialize
{
	NSLog(@"initialize:");
	
	ud = [NSUserDefaults standardUserDefaults];
	nc = [[NSNotificationCenter defaultCenter] retain];
	
	// FIXME: GNUstep NSUserDefaults, when -registerDefaults is called, should observe defaultPrefs
	// and try to synchronize defaultPrefs within a persisten domain when defaultPrefs has changed
	[ud registerDefaults: [self defaultValues]];
	[ud synchronize];
}

- (void) awakeFromNib
{
	NSString *toolPath;
	NSEnumerator *e;
	id key;
	
	ud = [[NSUserDefaults standardUserDefaults] retain];
	
	// FIXME: We shoudn't have to do that, it is just a temporary hack until GNUstep
	// knows how to do it by itself when -synchronize is called
	// More explanations in +initialize.
	/*
	prefsDict = [[ud persistentDomainForName: @"UnitTests"] mutableCopy];
	if (prefsDict == nil || [prefsDict count] == 0)
	{
        [ud setPersistentDomain: [PreferencesController defaultValues] forName: @"UnitTests"];
		[ud synchronize];
		prefsDict = [[ud persistentDomainForName: @"UnitTests"] mutableCopy];
    }
	 */
	
	NSLog(@"Default prefs dict %@", prefsDict);
	
	toolPath = [ud objectForKey: ToolPathDefault];
	NSLog(@"Default tool path %@", toolPath);
	
	if ([toolPath isEqualToString: @""] == NO)
		[toolPathField setStringValue: toolPath];
		
	e = [[[ud objectForKey: TestsSetsDefault] allKeys] reverseObjectEnumerator];	
	while ((key = [e nextObject]) != nil)
	{
		if ([key isEqualToString: @"Default"] == NO) /* Don't do it with Default set item */
		{
			[popupTestsSets insertItemWithTitle: key 
				atIndex: [popupTestsSets indexOfItemWithTag:10]];
		}
	}
	NSLog(@"popupTestsSets %@", popupTestsSets);
	[nc postNotificationName: TestsSetsChangedNotification object: self];
}

- (void) dealloc
{

	[super dealloc];
}

- (void) checkWithTests: (id)sender
{
  /* insert your code here */
}


- (void) popupRunTestsSets: (id)sender
{
	NSMutableDictionary *testsSets = [ud objectForKey: TestsSetsDefault];
	int r; 
	
	NSLog(@"popupRunTestsSet: %@ tag %d", sender, [[sender selectedItem] tag]);
	
	// Check reentrancy !

	switch ([[sender selectedItem] tag])
	{
		case 10: /* Separator */
		
			[popupTestsSets selectItemWithTitle: [ud stringForKey: LastEditedTestsSetDefault]];
			NSBeep();
			
			break;
			
		case 1: /* New tests set */
			
			if ([[ud stringForKey: LastEditedTestsSetDefault] isEqualToString: @"Default"]) /* Default tests set is selected */
			{
				[popupTestsSets selectItemAtIndex: [popupTestsSets indexOfItemWithTag: 0]];
			}
			else
			{
				[popupTestsSets selectItemWithTitle: [ud stringForKey: LastEditedTestsSetDefault]];			
			}
			
			r = [NSApp runModalForWindow: windowNewSet relativeToWindow: windowPreferences];
			
			//[NSApp beginSheet: windowNewSet modalForWindow: windowPreferences modalDelegate: self
			//	didEndSelector: @selector(endNewSet:returnCode:contextInfo:) contextInfo: nil];
				
			break;	
			
		case 2: /* Remove tests set */
		
			if ([[ud stringForKey: LastEditedTestsSetDefault] isEqualToString: @"Default"]) /* Default tests set is selected */
			{
				/* You cannot remove Default set */
				
				NSBeep();
				[popupTestsSets selectItemAtIndex: [popupTestsSets indexOfItemWithTag: 100]];
			}
			else
			{
				[popupTestsSets removeItemWithTitle: [ud stringForKey: LastEditedTestsSetDefault]];
				[testsSets removeObjectForKey: [ud stringForKey: LastEditedTestsSetDefault]];
				[PreferencesController defaultStoreValue: testsSets forKey: TestsSetsDefault];
				[popupTestsSets selectItemAtIndex: [popupTestsSets indexOfItemWithTag: 100]];
			}
			
			break;
			
		case 3: /* Rename tests set */
		
			[popupTestsSets selectItemWithTitle: [ud stringForKey: LastEditedTestsSetDefault]];
			
			if ([[ud stringForKey: LastEditedTestsSetDefault] isEqualToString: @"Default"]) /* Default tests set is selected */
			{
				/* You cannot rename Default set */
				
				NSBeep();
			}
			else
			{
				r = [NSApp runModalForWindow: windowRenameSet relativeToWindow: windowPreferences];
				
				//[NSApp beginSheet: windowRenameSet modalForWindow: windowPreferences modalDelegate: self
				//	didEndSelector: @selector(endRenameSet:returnCode:contextInfo:) contextInfo: nil];
			}
			
			break;
		
		default: /* Selected tests set has changed */
		
			if ([[popupTestsSets selectedItem] tag] == 100)
			{
				[ud setObject: @"Default" forKey: LastEditedTestsSetDefault];
			}
			else
			{
				[ud setObject: [[popupTestsSets selectedItem] title] forKey: LastEditedTestsSetDefault];
			}		
	}
	
	NSLog(@"Update selectedSetKey");
	
	if ([[popupTestsSets selectedItem] tag] == 100)
	{
		[ud setObject: @"Default" forKey: LastEditedTestsSetDefault];
	}
	else
	{
		NSLog(@"Selection change taken in account");
		[ud setObject: [[popupTestsSets selectedItem] title] forKey: LastEditedTestsSetDefault];
	}
	
	[ud synchronize];
	
	[tvBundles reloadData];	
	
	[nc postNotificationName: TestsSetsChangedNotification object: self];
}

- (void) ukrunPath: (id)sender
{
	NSLog(@"ukrunPath: %@", sender);
	
	[ud setObject: [sender stringValue] forKey: ToolPathDefault];
}

- (void) addTestsBundle: (id)sender
{
	NSDictionary *testsSets = [ud objectForKey: TestsSetsDefault];
	NSMutableArray *variousTests = 
		[testsSets objectForKey: [ud stringForKey: LastEditedTestsSetDefault]];
	NSMutableDictionary *testBundleDict = [NSMutableDictionary dictionary];
	
	NSLog(@"addTestsBundle: %@", sender);
	
	[testBundleDict setObject: [NSNumber numberWithBool: YES] forKey: @"check"];
	[testBundleDict setObject: @"No name" forKey: @"name"];
	[testBundleDict setObject: @"No bundle path" forKey: @"path"];
	
	[variousTests addObject: testBundleDict];
	
	NSLog(@"Tests bundle list %@", variousTests);
	
	[PreferencesController defaultStoreValue: testsSets forKey: TestsSetsDefault];
	
	NSLog(@"Tests bundle list sync %@", [ud objectForKey: @"TestsSet"]);
	
	[tvBundles reloadData];
}

- (void) removeTestsBundle: (id)sender
{
	// FIXME: We need to disable the remove button correctly
	if ([tvBundles numberOfSelectedRows] == 0)
		return;
	
	NSDictionary *testsSets = [ud objectForKey: TestsSetsDefault];
	NSMutableArray *variousTests = 
		[testsSets objectForKey: [ud stringForKey: LastEditedTestsSetDefault]];
		
	NSLog(@"removeTestsBundle: %@", sender);
	
	[variousTests removeObjectAtIndex: [tvBundles selectedRow]];
	
	[PreferencesController defaultStoreValue: testsSets forKey: TestsSetsDefault];
	
	[tvBundles reloadData];
}

- (void) endSetWindow: (id)sender
{
	NSTextField *text = [[[sender window] contentView] viewWithTag: 111];
	NSString *name = [text stringValue];
	
	NSLog(@"endSetWindow: %@ %d", [text stringValue], [sender tag]);
	
	if ([sender tag] == 0) /* Cancel */
	{
		[NSApp abortModal];
		return;
	}
	
	if ([name isEqualToString: @""] || [[[ud objectForKey: @"TestsSet"] allKeys] containsObject: name])
	{
		[text setStringValue: @"Set name must be not empty and not already used."];
		NSBeep();
		return;
	}
	
	NSLog(@"sender %@", [[sender window] title]);
	
	if ([sender window] == windowNewSet)
	{
		[self endNewSetSheet: [sender window] returnCode: [sender tag] contextInfo: nil];
	}
	else if ([sender window] == windowRenameSet)
	{
		[self endRenameSetSheet: [sender window] returnCode: [sender tag] contextInfo: nil];
	}
	
	[NSApp abortModal];
	//[NSApp stopModal];
	//[NSApp endSheet: [sender window] returnCode: [sender tag]];
	
	//[tvBundles reloadData];
}

/*
 * Sheet delegate methods
 */
 
- (void) endNewSetSheet: (id)sheet returnCode: (int)tag contextInfo: (id)info
{
	NSString *name;
	NSMutableDictionary *testBundleDict;
	NSMutableArray *variousTests;
	NSMutableDictionary *testsSets = [ud objectForKey: TestsSetsDefault];
	
	name = [[[sheet contentView] viewWithTag: 111] stringValue];
	NSLog(@"New set name %@", name);
	
	variousTests = [NSMutableArray array];
	testBundleDict = [NSMutableDictionary dictionary];
	
	[variousTests addObject: testBundleDict];
	[testsSets setObject: variousTests forKey: name];
	
	[PreferencesController defaultStoreValue: testsSets forKey: TestsSetsDefault];
	
	[popupTestsSets insertItemWithTitle: name atIndex: [popupTestsSets indexOfItemWithTag: 10]];
	[popupTestsSets selectItemWithTitle: name];
	
	//[nc postNotificationName: TestsSetsChangedNotification object: self];
}
 
- (void) endRenameSetSheet: (id)sheet returnCode: (int)tag contextInfo: (id)info
{
	NSMutableDictionary *testsSets = [ud objectForKey: TestsSetsDefault];
	NSArray *variousTests;
	NSString *name;
		
	name = [[[sheet contentView] viewWithTag: 111] stringValue];
	
	variousTests = [testsSets objectForKey: [ud stringForKey: LastEditedTestsSetDefault]];
	
	[variousTests retain];
	[testsSets removeObjectForKey: [ud stringForKey: LastEditedTestsSetDefault]];	
	[testsSets setObject: variousTests forKey: name];
	[variousTests release];
	
	[PreferencesController defaultStoreValue: testsSets forKey: TestsSetsDefault];
	[PreferencesController defaultStoreValue: name forKey: LastEditedTestsSetDefault];
	
	NSLog(@"endRenameSetSheet %@", [[popupTestsSets selectedItem] title]);
	
	[[popupTestsSets selectedItem] setTitle: name];
	
	//[nc postNotificationName: TestsSetsChangedNotification object: self];
}

/*
 * Table view data source methods
 */
 
- (int) numberOfRowsInTableView: (NSTableView *)tv
{
	NSArray *variousTests = 
		[[ud objectForKey: TestsSetsDefault] objectForKey: [ud stringForKey: LastEditedTestsSetDefault]];
	int n = [variousTests count];
	
	NSLog(@"numberOfRowsInTableView: %@ %d", [ud objectForKey: @"TestsSet"], n);
	
	return n;
}

- (id) tableView: (NSTableView *)tv objectValueForTableColumn: (NSTableColumn *)col row: (int)row
{
	NSArray *variousTests = 
		[[ud objectForKey: TestsSetsDefault] objectForKey: [ud stringForKey: LastEditedTestsSetDefault]];
	NSDictionary *testBundleDict = [variousTests objectAtIndex: row];
	id value = [testBundleDict objectForKey: [col identifier]];
	
	NSLog(@"tableView:objectValueForTableColumn:row: %@", variousTests);
	
	return value;
}

- (void) tableView: (NSTableView *)tv setObjectValue: (id)value forTableColumn: (NSTableColumn *)col row: (int)row
{
	NSDictionary *testsSets = [ud objectForKey: TestsSetsDefault];
	NSArray *variousTests = 
		[testsSets objectForKey: [ud stringForKey: LastEditedTestsSetDefault]];
	NSMutableDictionary *testBundleDict = [variousTests objectAtIndex: row];
	
	NSLog(@"tableView:setObjectValue:forTableColumn:row: %@ %@ %@", value, variousTests, [col identifier]);
	
	[testBundleDict setObject: value forKey: [col identifier]];
	
	/* Synchronize */
	[PreferencesController defaultStoreValue: testsSets forKey: TestsSetsDefault];
}

/*
 * Preferences window delegate methods
 */
 
- (void) windowDidBecomeMain: (NSNotification *)not
{
	[tvBundles reloadData];
}

- (void) windowDidBecomeKey: (NSNotification *)not
{
	[tvBundles reloadData];
}

@end
