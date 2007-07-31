//
//  LaunchBox.m
//  LaunchBox
//
//  Created by David Chisnall on 05/01/2005.
//  Copyright 2005 David Chisnall. 
//

/*
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "LaunchBox.h"


@implementation LaunchBox
- (id) init
{
	self = [super init];
	if(self == nil)
	{
		return nil;
	}
	apps = [[NSMutableDictionary alloc] init];
	[self refreshAppsList:self];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(activate:)
												 name:NSApplicationDidBecomeActiveNotification
											   object:NSApp];
	return self;
}

- (void) activate:(id)sender
{
	[[NSApp mainWindow] makeFirstResponder:commandBox];
}

- (void) addAppsInDirectory:(NSString*)directory
{
	NSFileManager * fileManager = [NSFileManager defaultManager];
	NSEnumerator * enumerator = [[fileManager directoryContentsAtPath:directory] objectEnumerator];
	NSString * file;
	while(nil != (file = [enumerator nextObject]))
	{
		NSString * path = [NSString pathWithComponents:[NSArray arrayWithObjects:directory, file, nil]];
		BOOL isDirectory;
		unsigned int length = [file length];
		[fileManager fileExistsAtPath:path isDirectory:&isDirectory];
		if(isDirectory)
		{
			if(length > 4 && [[file substringWithRange:NSMakeRange(length-4,4)] isEqualToString:@".app"])
			{
				NSLog(@"Found app %@",file);
				[apps setObject:path forKey:[file substringToIndex:length-4]];
			}
			else
			{
				[self addAppsInDirectory:path];
			}
		}
	}
}

- (IBAction) refreshAppsList:(id)sender
{
	NSArray * applicationDirectories = NSSearchPathForDirectoriesInDomains(NSApplicationDirectory, NSAllDomainsMask, YES);
	NSEnumerator * enumerator = [applicationDirectories objectEnumerator];
	NSString * appdir;
	while(nil != (appdir = [enumerator nextObject]))
	{
		[self addAppsInDirectory:appdir];
	}
	[appNames release];
	appNames = [[[apps allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
	NSLog(@"Setting data source.");
	NSLog(@"Setting data source.");
	[commandBox setUsesDataSource:YES];
	NSLog(@"Setting data source.");
	NSLog(@"Setting data source.");
	[commandBox setDataSource:self];
}

- (NSString *)comboBox:(NSComboBox *)aComboBox completedString:(NSString *)uncompletedString
{
	NSEnumerator * enumerator = [appNames objectEnumerator];
	NSString * appName;
	unsigned int length = [uncompletedString length];
	while(nil != (appName = [enumerator nextObject]))
	{
		if(length < [appName length])
		{
			switch([uncompletedString caseInsensitiveCompare:[appName substringToIndex:length]])
			{
				case NSOrderedSame:
					return appName;
				case NSOrderedAscending:
					return uncompletedString;
				default:
					{}
			}
		}
	}
	return uncompletedString;
}

- (unsigned int)comboBox:(NSComboBox *)aComboBox indexOfItemWithStringValue:(NSString *)aString
{
	return [appNames indexOfObjectIdenticalTo:aString];
}

- (id)comboBox:(NSComboBox *)aComboBox objectValueForItemAtIndex:(int)index
{
	return [appNames objectAtIndex:index];
}

- (IBAction) launch:(id)sender
{
	NSLog(@"Launching app..");
	NSString * app = [apps objectForKey:[commandBox stringValue]];
	if(app != nil)
	{
		[[NSWorkspace sharedWorkspace] launchApplication:app];
		[commandBox setStringValue:@""];
	}
	[self activate:self];
}

- (int)numberOfItemsInComboBox:(NSComboBox *)aComboBox
{
	return [appNames count];
}
@end
