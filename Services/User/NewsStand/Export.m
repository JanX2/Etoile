//
//  Export.m
//  Vienna
//
//  Created by Steve on 5/27/05.
//  Copyright (c) 2007 Yen-Ju. All rights reserved.
//  Copyright (c) 2004-2005 Steve Palmer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "Export.h"
#import "FoldersTree.h"
#import "XMLFunctions.h"
#import "StringExtensions.h"
#import <TRXML/TRXMLParser.h>
#import <TRXML/TRXMLDeclaration.h>

@implementation AppController (Export)

/* exportSubscriptions
 * Export the list of RSS subscriptions as an OPML file.
 */
-(IBAction)exportSubscriptions:(id)sender
{
	NSSavePanel * panel = [NSSavePanel savePanel];

	// If multiple selections in the folder list, default to selected folders
	// for simplicity.
	if ([foldersTree countOfSelectedFolders] > 1)
	{
		[exportSelected setState:NSOnState];
		[exportAll setState:NSOffState];
	}
	else
	{
		[exportSelected setState:NSOffState];
		[exportAll setState:NSOnState];
	}

	// Localise the strings
	[exportAll setTitle:NSLocalizedString(@"Export all subscriptions", nil)];
	[exportSelected setTitle:NSLocalizedString(@"Export selected subscriptions", nil)];
	[exportWithGroups setTitle:NSLocalizedString(@"Preserve group folders in exported file", nil)];

	[panel setAccessoryView:exportSaveAccessory];
	[panel setAllowedFileTypes:[NSArray arrayWithObject:@"opml"]];
	[panel beginSheetForDirectory:nil
							 file:@""
				   modalForWindow:mainWindow
					modalDelegate:self
				   didEndSelector:@selector(exportSavePanelDidEnd:returnCode:contextInfo:)
					  contextInfo:nil];
}

/* exportSavePanelDidEnd
 * Called when the user completes the Export save panel
 */
-(void)exportSavePanelDidEnd:(NSSavePanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton)
	{
		[panel orderOut:self];

		NSArray * foldersArray = ([exportSelected state] == NSOnState) ? [foldersTree selectedFolders] : [db arrayOfFolders:MA_Root_Folder];
		int countExported = [self exportToFile:[panel filename] from:foldersArray withGroups:([exportWithGroups state] == NSOnState)];
		
		if (countExported < 0)
		{
			NSBeginCriticalAlertSheet(NSLocalizedString(@"Cannot open export file message", nil),
									  NSLocalizedString(@"OK", nil),
									  nil,
									  nil, [NSApp mainWindow], self,
									  NULL, NULL, nil,
									  NSLocalizedString(@"Cannot open export file message text", nil));
		}
		else
		{
			// Announce how many we successfully imported
			NSString * successString = [NSString stringWithFormat:NSLocalizedString(@"%d subscriptions successfully exported", nil), countExported];
			NSRunAlertPanel(NSLocalizedString(@"RSS Subscription Export Title", nil), successString, NSLocalizedString(@"OK", nil), nil, nil);
		}
	}
}

/* exportSubscriptionGroup
 * Export one group of folders.
 */
-(int)exportSubscriptionGroup:(TRXMLNode *)xmlTree fromArray:(NSArray *)feedArray withGroups:(BOOL)groupFlag
{
	NSEnumerator * enumerator = [feedArray objectEnumerator];
	int countExported = 0;
	Folder * folder;

	while ((folder = [enumerator nextObject]) != nil)
	{
		NSMutableDictionary * itemDict = [NSMutableDictionary dictionary];
		NSString * name = [folder name];
		if (IsGroupFolder(folder))
		{
			NSArray * subFolders = [db arrayOfFolders:[folder itemId]];
			
			if (!groupFlag)
				countExported += [self exportSubscriptionGroup:xmlTree fromArray:subFolders withGroups:groupFlag];
			else
			{
				[itemDict setObject:quoteAttributes((name ? name : @"")) forKey:@"text"];
				TRXMLNode *subTree = [TRXMLNode TRXMLNodeWithType: @"outline" attributes: itemDict];
				[xmlTree addChild: subTree];
				countExported += [self exportSubscriptionGroup:subTree fromArray:subFolders withGroups:groupFlag];
			}
		}
		else if (IsRSSFolder(folder))
		{
			NSString * link = [folder homePage];
			NSString * description = [folder feedDescription];
			NSString * url = [folder feedURL];

			[itemDict setObject:@"rss" forKey:@"type"];
			[itemDict setObject:quoteAttributes((name ? name : @"")) forKey:@"text"];
			[itemDict setObject:quoteAttributes((link ? link : @"")) forKey:@"htmlUrl"];
			[itemDict setObject:quoteAttributes((url ? url : @"")) forKey:@"xmlUrl"];
			[itemDict setObject:quoteAttributes(description) forKey:@"description"];
			TRXMLNode *subTree = [TRXMLNode TRXMLNodeWithType: @"outline" attributes: itemDict];
			[xmlTree addChild: subTree];
			++countExported;
		}
	}
	return countExported;
}

/* exportToFile
 * Export a list of RSS subscriptions to the specified file. If onlySelected is set then only those
 * folders selected in the folders tree are exported. Otherwise all RSS folders are exported.
 * Returns the number of subscriptions exported, or -1 on error.
 */
-(int)exportToFile:(NSString *)exportFileName from:(NSArray *)foldersArray withGroups:(BOOL)groupFlag
{
	TRXMLNode *node = nil;
	TRXMLDeclaration *newTree = [TRXMLDeclaration TRXMLDeclaration];
	TRXMLNode *opmlTree = [TRXMLNode TRXMLNodeWithType: @"opml" attributes: [NSDictionary dictionaryWithObject:@"1.0" forKey:@"version"]];
	[newTree addChild: opmlTree];
	TRXMLNode *headTree = [TRXMLNode TRXMLNodeWithType: @"head"];
	[opmlTree addChild: headTree];

	node = [TRXMLNode TRXMLNodeWithType: @"title"];
	[node setCData: @"Vienna Subscriptions"];
	[headTree addChild: node];
	node = [TRXMLNode TRXMLNodeWithType: @"dateCreated"];
	[node setCData: [[NSCalendarDate date] description]];
	[headTree addChild: node];
	
	// Create the body section
	TRXMLNode *bodyTree = [TRXMLNode TRXMLNodeWithType: @"body"];
	[opmlTree addChild: bodyTree];

	int countExported = [self exportSubscriptionGroup:bodyTree fromArray:foldersArray withGroups:groupFlag];

	// Now write the complete XML to the file
	NSString * fqFilename = [exportFileName stringByExpandingTildeInPath];
	if (![[NSFileManager defaultManager] createFileAtPath:fqFilename contents:nil attributes:nil])
	{
		return -1; // Indicate an error condition (impossible number of exports)
	}

	// Put some newlines in for readability
	NSString * xmlString = [newTree stringValue];
    NSData *xmlData = [xmlString dataUsingEncoding:NSUTF8StringEncoding]; // [xmlString writeToFile:atomically:] will write xmlString in other encoding than UTF-8
    [xmlData writeToFile:fqFilename atomically:YES];
	
	return countExported;
}
@end
