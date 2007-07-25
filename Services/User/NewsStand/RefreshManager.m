//
//  RefreshManager.m
//  Vienna
//
//  Created by Steve on 7/19/05.
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

#import "RefreshManager.h"
#import "FeedCredentials.h"
#import "ActivityLog.h"
#import "FoldersTree.h"
#import "RichXMLParser.h"
#import "StringExtensions.h"
#import "Preferences.h"
#import "Constants.h"
#import "ViennaApp.h"
#import "Database.h"
#import "AsyncConnection.h"

// Singleton
static RefreshManager * _refreshManager = nil;

// Refresh types
typedef enum {
	MA_Refresh_NilType = -1,
	MA_Refresh_Feed,
	MA_Refresh_FavIcon
} RefreshTypes;

// Private functions
@interface RefreshManager (Private)
	- (BOOL) isRefreshingFolder: (Folder *) folder ofType: (RefreshTypes) type;
	- (void) refreshFavIcon: (Folder *) folder;
	- (void) getCredentialsForFolder;
	- (void) setFolderErrorFlag: (Folder *) folder flag: (BOOL) theFlag;
	- (void) setFolderUpdatingFlag: (Folder *) folder flag: (BOOL) theFlag;
	- (void) pumpSubscriptionRefresh: (Folder *) folder;
	- (void) pumpFolderIconRefresh: (Folder *) folder;
	- (void) refreshFeed: (Folder *) folder fromURL: (NSURL *) url
	             withLog: (ActivityItem *) aItem;
	- (void) beginRefreshTimer;
	- (void) refreshPumper: (NSTimer *) aTimer;
	- (void) addConnection: (AsyncConnection *) conn;
	- (void) removeConnection:(AsyncConnection *) conn;
	- (void) folderIconRefreshCompleted: (AsyncConnection *) connector;
	- (NSString *) getRedirectURL: (NSData *) data;
	- (void) postRefreshingProgress;
@end

// Single refresh item type
@interface RefreshItem : NSObject 
{
	Folder * folder;
	RefreshTypes type;
}

// Accessor functions
- (void) setFolder: (Folder *) newFolder;
- (void) setType: (RefreshTypes) newType;
- (Folder *) folder;
- (RefreshTypes) type;
@end

@implementation RefreshItem

/* init
 * Initialises an empty RefreshItem with default values.
 */
-(id)init
{
	if ((self = [super init]) != nil)
	{
		[self setFolder:nil];
		[self setType:MA_Refresh_NilType];
	}
	return self;
}

/* setFolder
 */
-(void)setFolder:(Folder *)newFolder
{
	[newFolder retain];
	[folder release];
	folder = newFolder;
}

/* folder
 */
-(Folder *)folder
{
	return folder;
}

/* setType
 */
-(void)setType:(RefreshTypes)newType
{
	type = newType;
}

/* type
 */
-(RefreshTypes)type
{
	return type;
}

/* dealloc
 * Clean up behind ourselves.
 */
-(void)dealloc
{
	[folder release];
	[super dealloc];
}
@end

@implementation RefreshManager

/* init
 * Initialise the class.
 */
-(id)init
{
	if ((self = [super init]) != nil)
	{
		maximumConnections = [[Preferences standardPreferences] integerForKey:MAPref_RefreshThreads];
		countOfNewArticles = 0;
		refreshArray = [[NSMutableArray alloc] initWithCapacity:10];
		connectionsArray = [[NSMutableArray alloc] initWithCapacity:maximumConnections];
		authQueue = [[NSMutableArray alloc] init];
		hasStarted = NO;
		statusMessageDuringRefresh = nil;

		NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(handleGotAuthenticationForFolder:) name: MA_Notify_GotAuthenticationForFolder object:nil];
		[nc addObserver:self selector:@selector(handleCancelAuthenticationForFolder:) name: MA_Notify_CancelAuthenticationForFolder object:nil];
		[nc addObserver:self selector:@selector(handleWillDeleteFolder:) name: MA_Notify_WillDeleteFolder object:nil];
	}
	return self;
}

/* sharedManager
 * Returns the single instance of the refresh manager.
 */
+ (RefreshManager *) sharedManager
{
	if (!_refreshManager)
		_refreshManager = [[RefreshManager alloc] init];
	return _refreshManager;
}

/* handleWillDeleteFolder
 * Trap the notification that is broadcast just before a folder is being 
 * deleted. We use this to remove that folder from the refresh queue, 
 * if it is present, and interrupt a connection on that folder. 
 * Otherwise our retain on the folder will prevent it from being 
 * fully released until the end of the refresh by which time
 * the folder list pane will probably have completed its post delete update.
 */
- (void) handleWillDeleteFolder: (NSNotification *) nc
{
	Folder * folder = [[Database sharedDatabase] folderFromID:[[nc object] intValue]];
	if (folder != nil)
	{
		int index = [refreshArray count];
		while (--index >= 0)
		{
			RefreshItem * item = [refreshArray objectAtIndex:index];
			if ([item folder] == folder)
				[refreshArray removeObjectAtIndex:index];
		}

		index = [connectionsArray count];
		while (--index >= 0)
		{
			AsyncConnection * conn = [connectionsArray objectAtIndex:index];
			if ([conn contextData] == folder)
			{
				[conn cancel];
				[self removeConnection:conn];
				break;
			}
		}
	}
}

/* refreshSubscriptions
 * Add the folders specified in the foldersArray to the refreshArray.
 */
- (int) refreshSubscriptions: (NSArray *) foldersArray 
        ignoringSubscriptionStatus: (BOOL) ignoreSubStatus
{
	statusMessageDuringRefresh = NSLocalizedString(@"Refreshing subscriptions...", nil);
	
	int total = 0;
	int count = [foldersArray count];
	int index;
	
	for (index = 0; index < count; ++index)
	{
		Folder * folder = [foldersArray objectAtIndex:index];
		if (IsGroupFolder(folder))
		{
			total += [self refreshSubscriptions:[[Database sharedDatabase] arrayOfFolders:[folder itemId]] ignoringSubscriptionStatus:NO];
		}
		else if (IsRSSFolder(folder))
		{
			if (!IsUnsubscribed(folder) || ignoreSubStatus)
			{
				if (![self isRefreshingFolder:folder ofType:MA_Refresh_Feed])
				{
					RefreshItem * newItem = [[RefreshItem alloc] init];
					[newItem setFolder:folder];
					[newItem setType:MA_Refresh_Feed];
					[refreshArray addObject:newItem];
					[newItem release];
					total++;
				}
			}
		}
	}
	[self beginRefreshTimer];
	return total;
}

/* refreshFolderIconCacheForSubscriptions
 * Add the folders specified in the foldersArray to the refreshArray.
 */
- (int) refreshFolderIconCacheForSubscriptions: (NSArray *) foldersArray
{
	statusMessageDuringRefresh = NSLocalizedString(@"Refreshing folder images...", nil);
	
	int total = 0;
	int count = [foldersArray count];
	int index;
	
	for (index = 0; index < count; ++index)
	{
		Folder * folder = [foldersArray objectAtIndex:index];
		if (IsGroupFolder(folder))
			total += [self refreshFolderIconCacheForSubscriptions:[[Database sharedDatabase] arrayOfFolders:[folder itemId]]];
		else if (IsRSSFolder(folder))
		{
			[self refreshFavIcon:folder];
			total++;
		}
	}
	return total;
}

/* refreshFavIcon
 * Adds the specified folder to the refreshArray.
 */
-(void)refreshFavIcon:(Folder *)folder
{
	if (([folder flags] & MA_FFlag_CheckForImage))
		[[Database sharedDatabase] clearFolderFlag:[folder itemId] flagToClear:MA_FFlag_CheckForImage];
	
	// Do nothing if there's no homepage associated with the feed
	// or if the feed already has a favicon.
	if ([folder homePage] == nil || [[folder homePage] isBlank] || [folder hasCachedImage])
		return;
	
	if (![self isRefreshingFolder:folder ofType:MA_Refresh_FavIcon])
	{
		RefreshItem * newItem = [[RefreshItem alloc] init];
		[newItem setFolder:folder];
		[newItem setType:MA_Refresh_FavIcon];
		[refreshArray addObject:newItem];
		[newItem release];
		[self beginRefreshTimer];
	}
}

/* isRefreshingFolder
 * Returns whether refreshArray has an queue refresh for the specified folder
 * and refresh type.
 */
-(BOOL)isRefreshingFolder:(Folder *)folder ofType:(RefreshTypes)type
{
	NSEnumerator * enumerator = [refreshArray objectEnumerator];
	RefreshItem * item;
	
	while ((item = [enumerator nextObject]) != nil)
	{
		if ([item folder] == folder && [item type] == type)
			return YES;
	}
	return NO;
}

/* statusMessageDuringRefresh
 * Returns the string to be displayed during a refresh.
 */
-(NSString *)statusMessageDuringRefresh
{
	return statusMessageDuringRefresh;
}

/* cancelAll
 * Cancel all active refreshes.
 */
-(void)cancelAll
{
	[refreshArray removeAllObjects];
	while ([connectionsArray count] > 0)
	{
		AsyncConnection * conn = [connectionsArray objectAtIndex:0];
		Folder * folder = (Folder *)[conn contextData];
		[self setFolderUpdatingFlag:folder flag:NO];
		[conn cancel];
		[self removeConnection:conn];
	}
}

/* totalConnections
 * Returns the current number of concurrent active connections.
 */
-(int)totalConnections
{
	return [connectionsArray count];
}

/* countOfNewArticles
 */
-(int)countOfNewArticles
{
	return countOfNewArticles;
}

/* getCredentialsForFolder
 * Initiate the UI to request the credentials for the specified folder.
 */
-(void)getCredentialsForFolder
{
	if (credentialsController == nil)
		credentialsController = [[FeedCredentials alloc] init];
	
	// Pull next folder out of the queue. The UI will post a
	// notification when it is done and we can move on to the
	// next one.
	if ([authQueue count] > 0 && ![[credentialsController window] isVisible])
	{
		Folder * folder = [authQueue objectAtIndex:0];
		[credentialsController credentialsForFolder:[NSApp mainWindow] folder:folder];
	}
}

/* handleRequireAuthenticationForFolder [delegate]
 * Called when somewhere requires us to provide authentication for the specified
 * folder.
 */
-(void)handleRequireAuthenticationForFolder:(NSNotification *)nc
{
	Folder * folder = (Folder *)[nc object];
	if (![authQueue containsObject:folder])
		[authQueue addObject:folder];
	[self getCredentialsForFolder];
}

/* handleCancelAuthenticationForFolder
 * Called when somewhere cancelled our request to authenticate the specified
 * folder.
 */
-(void)handleCancelAuthenticationForFolder:(NSNotification *)nc
{
	Folder * folder = (Folder *)[nc object];
	[authQueue removeObject:folder];

	// Get the next one in the queue, if any
	[self getCredentialsForFolder];
}

/* handleGotAuthenticationForFolder [delegate]
 * Called when somewhere just provided us the needed authentication for the specified
 * folder. Note that we don't know if the authentication is valid yet - just that a
 * user name and password has been provided.
 */
-(void)handleGotAuthenticationForFolder:(NSNotification *)nc
{
	Folder * folder = (Folder *)[nc object];
	[[Database sharedDatabase] clearFolderFlag:[folder itemId] flagToClear:MA_FFlag_NeedCredentials];
	[authQueue removeObject:folder];
	[self refreshSubscriptions:[NSArray arrayWithObject:folder] ignoringSubscriptionStatus:YES];
	
	// Get the next one in the queue, if any
	[self getCredentialsForFolder];
}

/* setFolderErrorFlag
 * Sets or clears the folder error flag then broadcasts an update indicating that the folder
 * has changed.
 */
-(void)setFolderErrorFlag:(Folder *)folder flag:(BOOL)theFlag
{
	if (theFlag)
		[folder setNonPersistedFlag:MA_FFlag_Error];
	else
		[folder clearNonPersistedFlag:MA_FFlag_Error];
	[[NSNotificationCenter defaultCenter] postNotificationName: MA_Notify_FoldersUpdated object:[NSNumber numberWithInt:[folder itemId]]];
}

/* setFolderUpdatingFlag
 * Sets or clears the folder updating flag then broadcasts an update indicating that the folder
 * has changed.
 */
-(void)setFolderUpdatingFlag:(Folder *)folder flag:(BOOL)theFlag
{
	if (theFlag)
		[folder setNonPersistedFlag:MA_FFlag_Updating];
	else
		[folder clearNonPersistedFlag:MA_FFlag_Updating];
	[[NSNotificationCenter defaultCenter] postNotificationName: MA_Notify_FoldersUpdated object:[NSNumber numberWithInt:[folder itemId]]];
}

/* beginRefreshTimer
 * Start the connection refresh timer running.
 */
-(void)beginRefreshTimer
{
	if (pumpTimer == nil)
	{
		pumpTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(refreshPumper:) userInfo:nil repeats:YES] retain];
	}
}

/* refreshPumper
 * This is the heart of the refresh code. We manage the refreshArray by creating a
 * connection for each item in the array up to a maximum number of simultaneous
 * connections as defined in the maximumConnections variable.
 */
-(void)refreshPumper:(NSTimer *)aTimer
{
	while (([connectionsArray count] < maximumConnections) && ([refreshArray count] > 0))
	{
		RefreshItem * item = [refreshArray objectAtIndex:0];
		switch ([item type])
		{
		case MA_Refresh_NilType:
			NSAssert(false, @"Uninitialised RefreshItem in refreshArray");
			break;

		case MA_Refresh_Feed:
			[self pumpSubscriptionRefresh:[item folder]];
			break;
			
		case MA_Refresh_FavIcon:
			[self pumpFolderIconRefresh:[item folder]];
			break;
		}
		[refreshArray removeObjectAtIndex:0];
	}
	
	if ([connectionsArray count] == 0 && [refreshArray count] == 0 && hasStarted)
	{
		[pumpTimer invalidate];
		[pumpTimer release];
		pumpTimer = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName: MA_Notify_RefreshStatus object:nil];
		
		hasStarted = NO;
	}
	[self postRefreshingProgress];
}

/* pumpSubscriptionRefresh
 * Pick the folder at the head of the refresh array and spawn a connection to
 * refresh that folder.
 */
-(void)pumpSubscriptionRefresh:(Folder *)folder
{
	// If this folder needs credentials, add the folder to the list requiring authentication
	// and since we can't progress without it, skip this folder on the connection
	if ([folder flags] & MA_FFlag_NeedCredentials)
	{
		[authQueue addObject:folder];
		[self getCredentialsForFolder];
		return;
	}

	// The activity log name we use depends on whether or not this folder has a real name.
	NSString * name = [[folder name] isEqualToString:[Database untitledFeedFolderName]] ? [folder feedURL] : [folder name];
	ActivityItem * aItem = [[ActivityLog defaultLog] itemByName:name];
	
	// Compute the URL for this connection
	NSString * urlString = [folder feedURL];
	NSURL * url = nil;
	
	if ([urlString hasPrefix:@"file://"])
		url = [NSURL fileURLWithPath:[[urlString substringFromIndex:7] stringByExpandingTildeInPath]];
	else if ([urlString hasPrefix:@"feed://"])
		url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", [urlString substringFromIndex:7]]];
	else
		url = [NSURL URLWithString:urlString];
	
	// Seed the activity log for this feed.
	[aItem clearDetails];
	[aItem setStatus:NSLocalizedString(@"Retrieving articles", nil)];

	// Mark the folder as being refreshed. The updating status is not
	// persistent so we set this directly on the folder rather than
	// through the database.
	[self setFolderUpdatingFlag:folder flag:YES];
	
	// Additional detail for the log
	[aItem appendDetail:[NSString stringWithFormat:NSLocalizedString(@"Connecting to %@", nil), urlString]];
	
	// Kick off the connection
	[self refreshFeed:folder fromURL:url withLog:aItem];
}

/* refreshFeed
 * Refresh a folder's newsfeed using the specified URL.
 */
-(void)refreshFeed:(Folder *)folder fromURL:(NSURL *)url withLog:(ActivityItem *)aItem
{
	AsyncConnection * conn = [[AsyncConnection alloc] init];
	
	@try
	{
		NSMutableDictionary * headers = [NSMutableDictionary dictionary];
#ifndef GNUSTEP		
		[headers setValue:@"gzip" forKey:@"Accept-Encoding"];
#endif
		[headers setValue:[folder lastUpdateString] forKey:@"If-Modified-Since"];
		
		[conn setHttpHeaders:headers];
		
		if ([conn beginLoadDataFromURL:url
							  username:[folder username]
							  password:[folder password]
							  delegate:self
						   contextData:folder
								   log:aItem
						didEndSelector:@selector(folderRefreshCompleted:)])
		{
			[self addConnection:conn];
		}
	}
	@finally
	{
		[conn release];
	}
}

/* pumpFolderIconRefresh
 * Initiate a connect to refresh the icon for a folder.
 */
-(void)pumpFolderIconRefresh:(Folder *)folder
{
	// The activity log name we use depends on whether or not this folder has a real name.
	NSString * name = [[folder name] isEqualToString:[Database untitledFeedFolderName]] ? [folder feedURL] : [folder name];
	ActivityItem * aItem = [[ActivityLog defaultLog] itemByName:name];
	
	[aItem appendDetail:NSLocalizedString(@"Retrieving folder image", nil)];
	
	AsyncConnection * conn = [[AsyncConnection alloc] init];

	@try
	{
		NSString * favIconPath = [NSString stringWithFormat:@"http://%@/favicon.ico", [[[folder homePage] trim] baseURL]];
		
		[self setFolderUpdatingFlag:folder flag:YES];
		if ([conn beginLoadDataFromURL:[NSURL URLWithString:favIconPath]
							  username:nil
							  password:nil
							  delegate:self
						   contextData:folder
								   log:aItem
						didEndSelector:@selector(folderIconRefreshCompleted:)])
			[self addConnection:conn];
	}
	@finally
	{
		[conn release];
	}
}

/* folderRefreshCompleted
 * Called when a folder refresh completed.
 */
-(void)folderRefreshCompleted:(AsyncConnection *)connector
{
	Folder * folder = (Folder *)[connector contextData];
	int folderId = [folder itemId];
	Database * db = [Database sharedDatabase];

	[self setFolderUpdatingFlag:folder flag:NO];
	if ([connector status] == MA_Connect_NeedCredentials)
	{
		if (![authQueue containsObject:folder])
			[authQueue addObject:folder];
		[self getCredentialsForFolder];
	}
	else if ([connector status] == MA_Connect_PermanentRedirect)
	{
		// We got a permanent redirect from the feed so change the feed URL
		// to the new location.
		[db setFolderFeedURL:folderId newFeedURL:[connector URLString]];
		[[connector aItem] appendDetail:[NSString stringWithFormat:NSLocalizedString(@"Feed URL updated to %@", nil), [connector URLString]]];
		return;
	}
	else if ([connector status] == MA_Connect_Stopped)
	{
		// Stopping the connection isn't an error, so clear any
		// existing error flag.
		[self setFolderErrorFlag:folder flag:NO];
		
		// Set the last update date for this folder.
		[db setFolderLastUpdate:folderId lastUpdate:[NSDate date]];
		
		// If this folder also requires an image refresh, add that
		if ([folder flags] & MA_FFlag_CheckForImage)
			[self refreshFavIcon:folder];
	}
	else if ([connector status] == MA_Connect_URLIsGone)
	{
		// We got HTTP 410 which means the feed has been intentionally
		// removed so unsubscribe the feed.
		[db setFolderFlag:folderId flagToSet:MA_FFlag_Unsubscribed];
		[[NSNotificationCenter defaultCenter] postNotificationName: MA_Notify_FoldersUpdated object:[NSNumber numberWithInt:folderId]];
	}
	else if ([connector status] == MA_Connect_Failed)
	{
		// Mark the feed as failed
		[self setFolderErrorFlag:folder flag:YES];
	}
	else if ([connector status] == MA_Connect_Succeeded)
	{
		NSData * receivedData = [connector receivedData];
		[receivedData retain];
		[receivedData autorelease];

		// Check whether this is an HTML redirect. If so, create a new connection using
		// the redirect.
		NSString * redirectURL = [self getRedirectURL:receivedData];
		if (redirectURL != nil)
		{
			[self refreshFeed:folder fromURL:[NSURL URLWithString:redirectURL] withLog:[connector aItem]];
			[self removeConnection:connector];
			return;
		}

		// Remember the last modified date
		NSString * lastModifiedString = [[connector responseHeaders] valueForKey:@"Last-Modified"];
		if (lastModifiedString != nil)
			[db setFolderLastUpdateString:folderId lastUpdateString:lastModifiedString];

		// Empty data feed is OK if we got HTTP 200
		int newArticlesFromFeed = 0;	
		RichXMLParser * newFeed = [[RichXMLParser alloc] init];
		if ([receivedData length] > 0)
		{
			// Create a new rich XML parser instance that will take care of
			// parsing the XML data we just got.
			if (newFeed == nil || ![newFeed parseRichXML:receivedData])
			{
				// Mark the feed as failed
				[self setFolderErrorFlag:folder flag:YES];
				[[connector aItem] setStatus:NSLocalizedString(@"Error parsing XML data in feed", nil)];
				[newFeed release];
				[self removeConnection:connector];
				return;
			}

			// Log number of bytes we received
			[[connector aItem] appendDetail:[NSString stringWithFormat:NSLocalizedString(@"%ld bytes received", nil), [receivedData length]]];
			
			// Extract the latest title and description
			NSString * feedTitle = [newFeed title];
			NSString * feedDescription = [newFeed description];
			NSString * feedLink = [newFeed link];
			
			// Synthesize feed link if it is missing
			if (feedLink == nil || [feedLink isBlank])
				feedLink = [[folder feedURL] baseURL];

			// Check for new articles within 24 hours before the last update, because feeds
			// sometimes set the wrong time or date.
			NSDate * compareDate = [[folder lastUpdate] addTimeInterval:-86400];
			
			// We'll be collecting articles into this array
			NSMutableArray * articleArray = [NSMutableArray array];
			
			// Parse off items.
			NSEnumerator * itemEnumerator = [[newFeed items] objectEnumerator];
			FeedItem * newsItem;
			
			while ((newsItem = [itemEnumerator nextObject]) != nil)
			{
				NSDate * articleDate = [newsItem date];
				if (articleDate == nil)
					articleDate = [NSDate date];
				if ([articleDate compare:compareDate] == NSOrderedDescending)
				{
					NSString * articleGuid = [newsItem guid];
					
					// This routine attempts to synthesize a GUID from an incomplete item that lacks an
					// ID field. Generally we'll have three things to work from: a link, a title and a
					// description. The link alone is not sufficiently unique and I've seen feeds where
					// the description is also not unique. The title field generally does vary but we need
					// to be careful since separate articles with different descriptions may have the same
					// title. The solution is to use the link and title and build a GUID from those.
					// We add the folderId at the beginning to ensure that items in different feeds do not share a guid.
					if ([articleGuid isEqualToString:@""])
						articleGuid = [NSString stringWithFormat:@"%d-%@-%@", folderId, [newsItem link], [newsItem title]];
					
					Article * article = [[Article alloc] initWithGuid:articleGuid];
					[article setFolderId:folderId];
					[article setAuthor:[newsItem author]];
					[article setBody:[newsItem description]];
					[article setSummary:[newsItem summary]];
					[article setTitle:[newsItem title]];
					[article setLink:[newsItem link]];
					[article setDate:articleDate];
					[article setEnclosure:[newsItem enclosure]];
					if ([[article enclosure] isEqualToString:@""] == NO)
					{
						[article setHasEnclosure:YES];
					}
					[articleArray addObject:article];
					[article release];
				}
			}

			// Here's where we add the articles to the database
			if ([articleArray count] > 0u)
			{
				[folder clearCache];
				
				NSEnumerator * articleEnumerator = [articleArray objectEnumerator];
				Article * article;
				
				[db beginTransaction]; // Should we wrap the entire loop or just individual article updates?
				while ((article = [articleEnumerator nextObject]) != nil)
				{
					if ([db createArticle:folderId article:article] && ([article status] == MA_MsgStatus_New))
						++newArticlesFromFeed;
				}
				[db commitTransaction];
			}
			
			[db beginTransaction];

			// A notify is only needed if we added any new articles.
			if ([[folder name] hasPrefix:[Database untitledFeedFolderName]] && ![feedTitle isBlank])
			{
				// If there's an existing feed with this title, make ours unique
				// BUGBUG: This duplicates logic in database.m so consider moving it there.
				NSString * oldFeedTitle = feedTitle;
				unsigned int index = 1;

				while (([db folderFromName:feedTitle]) != nil)
					feedTitle = [NSString stringWithFormat:@"%@ (%i)", oldFeedTitle, index++];

				[[connector aItem] setName:feedTitle];
				[db setFolderName:folderId newName:feedTitle];
			}
			if (feedDescription != nil)
				[db setFolderDescription:folderId newDescription:feedDescription];

			if (feedLink!= nil)
				[db setFolderHomePage:folderId newHomePage:feedLink];
			
			[db commitTransaction];
			
			// Let interested callers know that the folder has changed.
			[[NSNotificationCenter defaultCenter] postNotificationName: MA_Notify_FoldersUpdated object:[NSNumber numberWithInt:folderId]];
		}

		// Mark the feed as succeeded
		[self setFolderErrorFlag:folder flag:NO];
		
		// Set the last update date for this folder.
		[db setFolderLastUpdate:folderId lastUpdate:[NSDate date]];
		
		// Send status to the activity log
		if (newArticlesFromFeed == 0)
			[[connector aItem] setStatus:NSLocalizedString(@"No new articles available", nil)];
		else
		{
			NSString * logText = [NSString stringWithFormat:NSLocalizedString(@"%d new articles retrieved", nil), newArticlesFromFeed];
			[[connector aItem] setStatus:logText];
		}
		
		// Done with this connection
		[newFeed release];

		// If this folder also requires an image refresh, add that
		if ([folder flags] & MA_FFlag_CheckForImage)
			[self refreshFavIcon:folder];

		// Add to count of new articles so far
		countOfNewArticles += newArticlesFromFeed;
	}
	[self removeConnection:connector];
	[self postRefreshingProgress];
}

/* getRedirectURL
 * Scans the XML data and checks whether it is actually an HTML redirect. If so, returns the
 * redirection URL. (Yes, I'm aware that some of this could be better implemented with calls to
 * strnstr and its ilk but I have a deep rooted distrust of the standard C runtime stemming from
 * a childhood trauma with buffer overflows so bear with me.)
 */
-(NSString *)getRedirectURL:(NSData *)data
{
	const char * scanPtr = [data bytes];
	const char * scanPtrEnd = scanPtr + [data length];
	
	// Make sure this is HTML otherwise this is likely just valid
	// XML and we can ignore everything else.
	const char * htmlTagPtr = "<html>";
	while (scanPtr < scanPtrEnd && *htmlTagPtr != '\0')
	{
		if (*scanPtr != ' ')
		{
			if (tolower(*scanPtr) != *htmlTagPtr)
				return nil;
			++htmlTagPtr;
		}
		++scanPtr;
	}
	
	// Look for the meta attribute
	const char * metaTag = "<meta ";
	const char * headEndTag = "</head>";
	const char * metaTagPtr = metaTag;
	const char * headEndTagPtr = headEndTag;
	while (scanPtr < scanPtrEnd)
	{
		if (tolower(*scanPtr) == *metaTagPtr)
			++metaTagPtr;
		else
		{
			metaTagPtr = metaTag;
			if (tolower(*scanPtr) == *headEndTagPtr)
				++headEndTagPtr;
			else
				headEndTagPtr = headEndTag;
		}
		if (*headEndTagPtr == '\0')
			return nil;
		if (*metaTagPtr == '\0')
		{
			// Now see if this meta tag has http-equiv attribute
			const char * httpEquivAttr = "http-equiv=\"refresh\"";
			const char * httpEquivAttrPtr = httpEquivAttr;
			while (scanPtr < scanPtrEnd && *scanPtr != '>')
			{
				if (tolower(*scanPtr) == *httpEquivAttrPtr)
					++httpEquivAttrPtr;
				else if (*scanPtr != ' ')
					httpEquivAttrPtr = httpEquivAttr;
				if (*httpEquivAttrPtr == '\0')
				{
					// OK. This is our meta tag. Now look for the URL field
					while (scanPtr < scanPtrEnd-3 && *scanPtr != '>')
					{
						if (tolower(*scanPtr) == 'u' && tolower(*(scanPtr+1)) == 'r' && tolower(*(scanPtr+2)) == 'l' && *(scanPtr+3) == '=')
						{
							const char * urlStart = scanPtr + 4;
							const char * urlEnd = urlStart;
							
							// Finally, gather the URL for the redirect and return it as an
							// auto-released string.
							while (urlEnd < scanPtrEnd && *urlEnd != '"' && *urlEnd != ' ' && *urlEnd != '>')
								++urlEnd;
							if (urlEnd == scanPtrEnd)
								return nil;
							return [NSString stringWithCString:urlStart length:(urlEnd - urlStart)];
						}
						++scanPtr;
					}
				}
				++scanPtr;
			}
			
			// Not our meta tag so look for another
			metaTagPtr = metaTag;
		}
		++scanPtr;
	}
	return nil;
}

/* folderIconRefreshCompleted
 * Called when a folder icon refresh completed.
 */
-(void)folderIconRefreshCompleted:(AsyncConnection *)connector
{
	Folder * folder = [connector contextData];
	[self setFolderUpdatingFlag:folder flag:NO];
	if ([connector status] == MA_Connect_Succeeded)
	{
		NSImage * iconImage = [[NSImage alloc] initWithData:[connector receivedData]];
		if (iconImage != nil && [iconImage isValid])
		{
			[iconImage setScalesWhenResized:YES];
			[iconImage setSize:NSMakeSize(16, 16)];
			[folder setImage:iconImage];

			// Broadcast a notification since the folder image has now changed
			[[NSNotificationCenter defaultCenter] postNotificationName: MA_Notify_FoldersUpdated object:[NSNumber numberWithInt:[folder itemId]]];

			// Log additional details about this.
			ActivityItem * aItem = [[ActivityLog defaultLog] itemByName:[folder name]];
			NSString * favIconPath = [NSString stringWithFormat:@"http://%@/favicon.ico", [[folder homePage] baseURL]];
			NSString * logText = [NSString stringWithFormat:NSLocalizedString(@"Folder image retrieved from %@", nil), favIconPath];
			[aItem appendDetail:logText];
		}
		[iconImage release];
	}
	[self removeConnection:connector];
	[self postRefreshingProgress];
}

/* addConnection
 * Add the specified connection to the array of connections
 * that we manage.
 */
-(void)addConnection:(AsyncConnection *)conn
{
	if (![connectionsArray containsObject:conn])
	{
		[connectionsArray addObject:conn];
		if (!hasStarted)
		{
			countOfNewArticles = 0;
			[[NSNotificationCenter defaultCenter] postNotificationName: MA_Notify_RefreshStatus object:nil];
			hasStarted = YES;
		}
	}

}

/* removeConnection
 * Removes the specified connection from the array of connections
 * that we manage.
 */
-(void)removeConnection:(AsyncConnection *)conn
{
	NSAssert([connectionsArray count] > 0, @"Calling removeConnection with zero active connection count");
	if ([connectionsArray containsObject:conn])
	{
		// Close the connection before we release as otherwise it leaks
		[conn close];
		[connectionsArray removeObject:conn];
	}
}

/* postRefreshingProgress
 * post progress of any refreshing in percentage.
 * It may be bigger than return value from 
 * refreshFolderIconCacheForSubscriptions: or
 * refreshSubscriptions:ignoringSubscriptionStatus: because a refresh
 * may generate more refreshes.
 * Note: it counts how many refreshes are left, not how many are done.
 * Return -1 if it is not refreshing.
 */
- (void) postRefreshingProgress
{
	int progress = -1;
	if (hasStarted)
	{
		progress = [connectionsArray count] + [refreshArray count];
	}
    [[NSNotificationCenter defaultCenter] postNotificationName: MA_Notify_Refreshing_Progress object:[NSNumber numberWithInt: progress]];
}

/* dealloc
 * Clean up after ourselves.
 */
-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[pumpTimer release];
	[authQueue release];
	[connectionsArray release];
	[refreshArray release];
	[super dealloc];
}
@end

