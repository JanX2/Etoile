/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>
   
   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License version 2 as published by the Free Software Foundation.
   
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import <RSSKit/RSSKit.h>

#import "ArticleDatabaseComponent.h"
#import "Article.h"
#import "Feed.h"

@interface ArticleDatabaseComponent (Private)
-(NSDictionary*)plistDictionary;
@end

@implementation ArticleDatabaseComponent (Private)
-(NSDictionary*)plistDictionary
{
    NSAssert(
        allArticles != nil && allFeeds != nil,
        @"Database was not initialized before archiving!"
    );
    
    NSMutableDictionary* dict = [NSMutableDictionary new];
    
    [dict setObject: @"Grrr ArticleDatabaseComponent" forKey: @"generator"];
    
    NSMutableArray* mutArr = [NSMutableArray new];
    
    NSEnumerator* enumerator = [allFeeds objectEnumerator];
    id <Feed> feed;
    while((feed = [enumerator nextObject]) != nil) {
        [mutArr addObject: [feed plistDictionary]];
    }
    [dict setObject: mutArr forKey: @"feeds"];
    
    return dict;
}
@end

@implementation ArticleDatabaseComponent

-(id)init
{
    NSLog(@"Article Database Component starting up...");
    if ((self = [super init]) != nil) {
        [self unarchive];
        ASSIGN(dirtyArticles, [NSMutableSet new]);
        
        // Register for article change events
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(articleChanged:)
                                                     name: RSSArticleChangedNotification
                                                   object: nil];
    }
    
    return self;
}

// -----------------------------

-(BOOL) saveDirtyArticles
{
    BOOL success = YES;
    NSMutableSet* newDirtyArticleSet = [NSMutableSet new];
    
    NSEnumerator* enumerator = [dirtyArticles objectEnumerator];
    id<Article> article;
    
    while ((article = [enumerator nextObject]) != nil) {
        if ([article store] == NO) {
            // if storing the article didn't work, keep it in the list
            success = NO;
            [newDirtyArticleSet addObject: article];
        }
    }
    
    ASSIGN(dirtyArticles, newDirtyArticleSet);
    
    return success;
}

-(BOOL)archive
{
    [self saveDirtyArticles];
    return [[self plistDictionary] writeToFile: [self databaseStoragePath] atomically: YES];
}

-(BOOL)unarchive
{
    NSDictionary* dict =
        [NSDictionary dictionaryWithContentsOfFile: [self databaseStoragePath]];
    
    // Create new empty database
    ASSIGN(allArticles, [NSMutableSet new]);
    ASSIGN(allFeeds, [NSMutableSet new]);
    
    NSArray* feeds = [dict objectForKey: @"feeds"];
    int i;
    for (i=0; i<[feeds count]; i++) {
        id<Feed> feed = [Feed feedFromPlistDictionary: [feeds objectAtIndex: i]];
        
        NSLog(@"Unarchiving feed %@", [feed feedName]);
        [allFeeds addObject: feed];
        
        NSEnumerator* enumerator = [feed articleEnumerator];
        id<RSSArticle> article;
        while ((article = [enumerator nextObject]) != nil) {
            //NSLog(@"  - article %@ (feed=%@)", [article headline], [[article feed] feedName]);
            [allArticles addObject: article];
        }
    }
    
    return YES; // worked.
}

-(NSString*)databaseStoragePath
{
    static NSString* dbPath = nil;
    
    if (dbPath == nil) {
        NSString* path = [@"~/GNUstep/Library/Grrr" stringByExpandingTildeInPath];
        
        NSFileManager* manager = [NSFileManager defaultManager];
        
        BOOL isDir, exists;
        exists = [manager fileExistsAtPath: path isDirectory: &isDir];
        
        if (exists) {
            NSAssert1(isDir, @"%@ is supposed to be a directory, but it isn't.", path);
            
        } else {
            if ([manager createDirectoryAtPath: path attributes: nil] == NO) {
                [NSException raise: @"GrrrDBStorageCreationFailed"
                            format: @"Creation of the DB storage directory %@ failed.", path];
            }
        }
        
        ASSIGN(dbPath, [path stringByAppendingString: @"/database.plist"]);
    }
    
    return dbPath;
}


// Output providing plugin impl
-(NSSet*) objectsForPipeType: (id<PipeType>)aPipeType
{
    NSAssert2(
        aPipeType == [PipeType articleType] || aPipeType == [PipeType feedType],
        @"%@ component does not support %@ output",
        self, aPipeType
    );
    
    if (aPipeType == [PipeType articleType]) {
        return [self articles];
    } else if (aPipeType == [PipeType feedType]) {
        return [self feeds];
    }
    
    return [NSSet new]; // should never happen
}


-(NSSet*)articles
{
    return [NSSet setWithSet: allArticles];
}

-(NSSet*)feeds
{
    return [NSSet setWithSet: allFeeds];
}


-(BOOL)removeArticle: (id<Article>)article
{
    // XXX: Apart from the hard implementation, does it make sense to delete articles?
    NSLog(@"Shall remove article %@", [article headline]);
    // don't forget to notify change!
    
    return NO;
}

-(BOOL)removeFeed: (id<Feed>)feed
{
    NSEnumerator* enumerator = [feed articleEnumerator];
    id<Article> article;
    
    while ((article = [enumerator nextObject]) != nil) {
        [allArticles removeObject: article];
    }
    
    [allFeeds removeObject: feed];
    
    [[NSNotificationCenter defaultCenter] postNotificationName: ComponentDidUpdateNotification
                                                        object: self];
    
    return YES;
}

-(void)fetchAllFeeds
{
    NSEnumerator* enumerator = [allFeeds objectEnumerator];
    id<Feed> feed;
    
    while ((feed = [enumerator nextObject]) != nil) {
        [feed fetchInBackground];
    }
}

-(BOOL)subscribeToURL: (NSURL*)aURL
{
    if (aURL == nil) {
        return NO;
    }
    
#ifdef GNUSTEP
    // If GNUstep base is below or equal 1.13.0, give a warning before loading a remote feed
#if (GNUSTEP_BASE_MAJOR_VERSION < 1 || \
       (GNUSTEP_BASE_MAJOR_VERSION == 1 && GNUSTEP_BASE_MINOR_VERSION <= 13) || \
       ( GNUSTEP_BASE_MAJOR_VERSION == 1 && \
         GNUSTEP_BASE_MINOR_VERSION == 13 && \
         GNUSTEP_BASE_SUBMINOR_VERSION == 0 ))
    int result = NSRunAlertPanel(
        @"Security problem",
        [NSString stringWithFormat:
            @"Your GNUstep FoundationKit version (below or equal 1.13.0) is vulnerable to a\n"
            @"security problem which can be exploited through RSS and Atom feeds.\n\n"
            @"Do you trust the source of this feed ?\n\n%@", aURL],
        @"No, I don't trust this feed.", @"Yes, I trust this feed.", nil
    );
    
    if (result == 1) {
        // User didn't trust the source.
        return NO;
    }
#endif
#endif
    
    id<Feed> feed = [[RSSFactory sharedFactory] feedWithURL: aURL];
    
    if (feed == nil) {
        return NO;
    }
    
    [allFeeds addObject: feed];
    [feed fetchInBackground]; // directly fetch!
    [[NSNotificationCenter defaultCenter] postNotificationName: ComponentDidUpdateNotification
                                                        object: self];
    return YES;
}

// gets called whenever an article changes.
-(void)articleChanged: (NSNotification*)aNotification
{
    // add this article to the 'dirty' list
    [dirtyArticles addObject: [aNotification object]];
}

@end


