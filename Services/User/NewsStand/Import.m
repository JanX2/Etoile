//
//  Import.m
//  Vienna
//
//  Created by Steve on 5/27/05.
//  Copyright (c) 2007 Yen-Ju Chen. All rights reserved.
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

#import "Import.h"
#import "StringExtensions.h"
#import "ViennaApp.h"
#import <TRXML/TRXMLDeclaration.h>
#import <TRXML/TRXMLParser.h>

@implementation AppController (Import)

/* importSubscriptions
 * Import an OPML file which lists RSS feeds.
 */
-(IBAction)importSubscriptions:(id)sender
{
	NSOpenPanel * panel = [NSOpenPanel openPanel];
	[panel beginSheetForDirectory:nil
							 file:nil
							types:nil
				   modalForWindow:mainWindow
					modalDelegate:self
				   didEndSelector:@selector(importOpenPanelDidEnd:returnCode:contextInfo:)
					  contextInfo:nil];
}

/* importOpenPanelDidEnd
 * Called when the user completes the Import open panel
 */
-(void)importOpenPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	if (returnCode == NSOKButton)
	{
		[panel orderOut:self];
		[self importFromFile:[panel filename]];
	}
}

/* importSubscriptionGroup
 * Import one group of an OPML subscription tree.
 */
-(int)importSubscriptionGroup:(TRXMLNode *)tree underParent:(int)parentId
{
	int countImported = 0;
	int count = [[tree elements] count];
	int index;
	for (index = 0; index < count; ++index)
	{
		TRXMLNode *outlineItem = [[tree elements] objectAtIndex: index];
		/* We only deal with TRXMLNode */
		if ([outlineItem isKindOfClass: [TRXMLNode class]] == NO)
			continue;

		NSString *feedTitle = [[outlineItem get: @"title"] stringByUnescapingExtendedCharacters];
		NSString *feedDescription = [[outlineItem get: @"description"] stringByUnescapingExtendedCharacters];
		NSString *feedURL= [[outlineItem get: @"xmlUrl"] stringByUnescapingExtendedCharacters];
		NSString *feedHomePage = [[outlineItem get: @"htmlUrl"] stringByUnescapingExtendedCharacters];
		NSString *bloglinesSubId = [[outlineItem get: @"bloglinessubid"] stringByUnescapingExtendedCharacters];
		int bloglinesId = bloglinesSubId ? [bloglinesSubId intValue] : MA_NonBloglines_Folder;

		// Some OPML exports use 'text' instead of 'title'.
		if (feedTitle == nil)
			feedTitle = [[outlineItem get: @"text"] stringByUnescapingExtendedCharacters];

		// Do double-decoding of the title to get around a bug in some commercial newsreaders
		// where they double-encode characters
		feedTitle = [feedTitle stringByUnescapingExtendedCharacters];
		
		if (feedURL == nil)
		{
			// This is a new group so try to create it. If there's an error then default to adding
			// the sub-group items under the parent.
			if (feedTitle != nil)
			{
				int folderId = [db addFolder:parentId afterChild:-1 folderName:feedTitle type:MA_Group_Folder canAppendIndex:NO];
				if (folderId == -1)
					folderId = MA_Root_Folder;
				countImported += [self importSubscriptionGroup:outlineItem underParent:folderId];
			}
		}
		else if (feedTitle != nil)
		{
			Folder * folder;
			int folderId;

			if ((folder = [db folderFromFeedURL:feedURL]) != nil)
				folderId = [folder itemId];
			else
			{
				folderId = [db addRSSFolder:feedTitle underParent:parentId afterChild:-1 subscriptionURL:feedURL];
				++countImported;
			}
			[db setBloglinesId:folderId newBloglinesId:bloglinesId];
			if (feedDescription != nil)
				[db setFolderDescription:folderId newDescription:feedDescription];
			if (feedHomePage != nil)
				[db setFolderHomePage:folderId newHomePage:feedHomePage];
		}
	}
	return countImported;
}

/* importFromFile
 * Import a list of RSS subscriptions.
 */
-(void)importFromFile:(NSString *)importFileName
{
	NSData *data = [NSData dataWithContentsOfFile:[importFileName stringByExpandingTildeInPath]];
	NSString *string = nil;
	if (data != nil)
	{
		/* We know this one must be UTF-8 encoding */
		string = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] autorelease];
	}
	BOOL hasError = NO;
	int countImported = 0;

	if (string != nil)
	{
		TRXMLDeclaration *decl = [TRXMLDeclaration TRXMLDeclaration];
		TRXMLParser *parser = [TRXMLParser parserWithContentHandler: decl];
		if (![parser parseFromSource: string])
		{
			NSRunAlertPanel(NSLocalizedString(@"Error importing subscriptions title", nil),
							NSLocalizedString(@"Error importing subscriptions body", nil),
							NSLocalizedString(@"OK", nil), nil, nil);
			hasError = YES;
		}
		else
		{
			/* Find opml/body */
			TRXMLNode *opmlTree = nil, *bodyTree = nil;
			if ([[decl elements] count] > 0)
			{
				// Should only have one "opml" child
				opmlTree = [[decl getChildrenWithName: @"opml"] anyObject];
			}
			else
			{
				NSLog(@"No <opml>");
				hasError = YES;
			}
			if ((opmlTree != nil) && ([[opmlTree elements] count] > 0))
			{
				// Should only have one "body" child
				bodyTree = [[opmlTree getChildrenWithName: @"body"] anyObject];
			}
			else
			{
				NSLog(@"No <body>");
				hasError = YES;
			}
			[db beginTransaction];
			countImported = [self importSubscriptionGroup:bodyTree underParent:MA_Root_Folder];
			[db commitTransaction];
		}
	}

	// Announce how many we successfully imported
	if (!hasError)
	{
		NSString * successString = [NSString stringWithFormat:NSLocalizedString(@"%d subscriptions successfully imported", nil), countImported];
		NSRunAlertPanel(NSLocalizedString(@"RSS Subscription Import Title", nil), successString, NSLocalizedString(@"OK", nil), nil, nil);
	}
}
@end
