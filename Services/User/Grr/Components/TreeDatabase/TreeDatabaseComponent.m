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

#import <Foundation/Foundation.h>
#import <RSSKit/RSSKit.h>

#import "TreeDatabaseComponent.h"
#import "Article.h"
#import "Feed.h"


@interface TreeDatabaseComponent (Private)
-(NSDictionary*)plistDictionary;
-(void)focusElement: (id<DatabaseElement>)elem;
@end

@implementation TreeDatabaseComponent (Private)
-(NSDictionary*)plistDictionary
{
    NSAssert(
        topLevelElements != nil,
        @"Database was not initialized before archiving!"
    );
    
    NSMutableDictionary* dict = [NSMutableDictionary new];
    
    [dict setObject: @"Grr TreeDatabaseComponent" forKey: @"generator"];
    [dict setObject: [NSDate new] forKey: @"modified"];
    
    NSMutableArray* mutArr = [NSMutableArray new];
    
    int i;
    for (i=0; i<[topLevelElements count]; i++) {
        id<DatabaseElement> elem = [topLevelElements objectAtIndex: i];
        
        NSAssert1(
            [elem conformsToProtocol: @protocol(DatabaseElement)],
            @"The tree database top level element %@ doesn't "
            @"conform to the DatabaseElement protocol",
            elem
        );
        
        [mutArr addObject: [elem plistDictionary]];
    }
    
    [dict setObject: mutArr forKey: @"topLevelElements"];
    
    return dict;
}

-(void)focusElement: (id<DatabaseElement>)elem
{
    [[NSNotificationCenter defaultCenter]
        postNotificationName: DatabaseElementFocusRequestNotification
                      object: elem];
}
@end

@implementation TreeDatabaseComponent

-(id)init
{
    NSLog(@"Tree Database Component starting up...");
    if ((self = [super init]) != nil) {
        [self unarchive];
        ASSIGN(dirtyArticles, [NSMutableSet new]);
        
        // Register for article change events
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(articleChanged:)
                                                     name: RSSArticleChangedNotification
                                                   object: nil];
        
        [self sendChangeNotification]; // not clean, but nobody's inheriting from this class
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
    // Looks strange, it's done this way to keep the order
    // (dirty articles first, database itself afterwards)
    BOOL success = [self saveDirtyArticles];
    success = success && [[self plistDictionary] writeToFile: [self databaseStoragePath] atomically: YES];
    
    return success;
}

-(BOOL)unarchive
{
    NSDictionary* dict =
        [NSDictionary dictionaryWithContentsOfFile: [self databaseStoragePath]];
    
    // Create new empty database
    ASSIGN(topLevelElements, [NSMutableArray new]);
    ASSIGN(allArticles, [NSMutableSet new]);
    
    int i; // for iterations
    
#ifdef BACKWARDS_COMPATIBILITY
    // Backwards compatibility with Article Database Component
    NSArray* feeds = [dict objectForKey: @"feeds"];
    for (i=0; i<[feeds count]; i++) {
        id<Feed> feed = [Feed feedFromPlistDictionary: [feeds objectAtIndex: i]];
        
        NSLog(@"Unarchived feed %@", [feed feedName]);
        [topLevelElements addObject: feed];
        
        NSEnumerator* enumerator = [feed articleEnumerator];
        id<RSSArticle> article;
        while ((article = [enumerator nextObject]) != nil) {
            //NSLog(@"  - article %@ (feed=%@)", [article headline], [[article feed] feedName]);
            [allArticles addObject: article];
        }
    }
#endif
    
    NSArray* elems = [dict objectForKey: @"topLevelElements"];
    for (i=0; i<[elems count]; i++) {
        NSDictionary* elemDict = [elems objectAtIndex: i];
        id<DatabaseElement> elem = DatabaseElementFromPlistDictionary(elemDict);
        
        // FIXME: Add all articles to the database's article set!
        [topLevelElements addObject: elem];
        // super element is nil, thus doesn't need to be set separately.
    }
    
    return YES; // worked.
}

-(NSString*)databaseStoragePath
{
    static NSString* dbPath = nil;
    
    if (dbPath == nil) {
        NSString* path = [@"~/GNUstep/Library/Grr" stringByExpandingTildeInPath];
        
        NSFileManager* manager = [NSFileManager defaultManager];
        
        BOOL isDir, exists;
        exists = [manager fileExistsAtPath: path isDirectory: &isDir];
        
        if (exists) {
            NSAssert1(isDir, @"%@ is supposed to be a directory, but it isn't.", path);
            
        } else {
            if ([manager createDirectoryAtPath: path attributes: nil] == NO) {
                [NSException raise: @"GrrDBStorageCreationFailed"
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
        aPipeType == [PipeType articleType],
        @"%@ component does not support %@ output",
        self, aPipeType
    );
    
    return [self articles];
}


-(NSArray*)topLevelElements
{
    return topLevelElements;
}

-(NSSet*)articles
{
    return [NSSet setWithSet: allArticles];
}


-(BOOL)removeArticle: (id<Article>)article
{
    // XXX: Apart from the hard implementation, does it make sense to delete articles?
    NSLog(@"Shall remove article %@", [article headline]);
    // don't forget to notify change!
    
    return NO;
}

// recursive
-(BOOL)removeElement: (id<DatabaseElement>)anElement
{
    if ([self _removeElement: anElement fromMutableArray: topLevelElements]) {
        [self sendChangeNotification];
        return YES;
    } else {
        return NO;
    }
}

-(BOOL)_removeElement: (id<DatabaseElement>)anElement
     fromMutableArray: (NSMutableArray*)array
{
    BOOL success = NO;
    if ([array containsObject: anElement]) {
        [array removeObject: anElement];
        success = YES;
    }
    
    int i;
    for (i=0; i<[array count]; i++) {
        id<DatabaseElement> elem = [array objectAtIndex: i];
        
        if ([elem conformsToProtocol: @protocol(Category)]) {
            success = success || [(id<Category>)elem recursivelyRemoveElement: anElement];
        }
    }
    
    return success;
}

-(void)fetchAllFeeds
{
    [self _fetchAllFeedsInDBElementArray: topLevelElements];
    [self sendChangeNotification];
}

-(void)_fetchAllFeedsInDBElementArray: (NSArray*)array
{
    int i;
    for (i=0; i<[array count]; i++) {
        id<DatabaseElement> elem = [array objectAtIndex: i];
        
        if ([elem conformsToProtocol: @protocol(Feed)]) {
            [(id<Feed>)elem fetchInBackground];
        } else if ([elem conformsToProtocol: @protocol(Category)]) {
            [self _fetchAllFeedsInDBElementArray: [(id<Category>)elem elements]];
        }
    }
}


// --------------------------------------------------------------------
//    Subscription methods
// --------------------------------------------------------------------

-(BOOL)subscribeToURL: (NSURL*)aURL
           inCategory: (id<Category>)aCategory
             position: (int)index
{
    if (aURL == nil) {
        return NO;
    }
    
    // Check if URL is already subscribed in this database
    if ([self feedForURL: aURL inArray: topLevelElements]) {
        // Don't allow to subscribe to the same feed twice.
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
#endif // VERSION
#endif // GNUSTEP
    
    id<Feed> feed = [[RSSFactory sharedFactory] feedWithURL: aURL];
    
    if (feed == nil) {
        return NO;
    }
    
    if (aCategory == nil) {
        [topLevelElements insertObject: feed atIndex: index];
        [feed setSuperElement: nil];
    } else {
        [aCategory insertElement: feed atPosition: index];
    }
    
    [feed fetchInBackground]; // directly fetch!
    [self focusElement: feed];
    [self sendChangeNotification];
    
    return YES;
}

-(BOOL)subscribeToURL: (NSURL*)aURL
           inCategory: (id<Category>)aCategory
{
    return [self subscribeToURL: aURL inCategory: aCategory position: 0];
}

-(BOOL)subscribeToURL: (NSURL*)aURL
{
    return [self subscribeToURL: aURL inCategory: nil];
}

/*
 * Searches the given array for a feed which subscribes to the given URL.
 * The array must consist of objects conforming to the DatabaseElement protocol.
 * Categories are searches recursively.
 */
-(id<Feed>)feedForURL: (NSURL*)aURL
              inArray: (NSArray*)anArray
{
    int i;
    for (i=0; i<[anArray count]; i++) {
        id<DatabaseElement> elem = [anArray objectAtIndex: i];
        
        if ([elem conformsToProtocol: @protocol(Feed)]) {
            if ([[(id<Feed>)elem feedURL] isEqual: aURL]) {
                return (id<Feed>)elem;
            }
        } else if ([elem conformsToProtocol: @protocol(Category)]) {
            id<Feed> result = [self feedForURL: aURL inArray: [(id<Category>)elem elements]];
            
            if (result != nil) {
                return result;
            }
        }
    }
    
    // nothing found
    return nil;
}

// ---------------------------------------------------------------------------
//    category adding methods
// ---------------------------------------------------------------------------

/**
 * Creates a new category with the given name in the specified
 * category at the given position.
 *
 * @return YES on success
 */
-(BOOL) addCategoryNamed: (NSString*)name
              inCategory: (id<Category>)aCategory
                position: (int)index
{
    BOOL result;
    id<Category> cat = AUTORELEASE([[GrrCategory alloc] initWithName: name]);
    
    if (cat == nil) {
        return NO;
    }
    
    if (aCategory == nil) {
        [topLevelElements insertObject: cat atIndex: index];
        [cat setSuperElement: nil];
        result = YES;
    } else {
        result = [aCategory insertElement: cat atPosition: index];
    }
    
    if (result) {
        [self focusElement: cat];
        [self sendChangeNotification];
    }
    
    return result;
}

/**
 * Creates a new category with the given name in the specified
 * category.
 *
 * @return YES on success
 */
-(BOOL) addCategoryNamed: (NSString*)name
              inCategory: (id<Category>)aCategory
{
    return [self addCategoryNamed: name
                       inCategory: aCategory
                         position: 0];
}

// ---------------------------------------------------------------------------
//    Moving methods
// ---------------------------------------------------------------------------

/*
 * This method moves an element by removing it from one category and adding it
 * to another. It sounds easy, but it's actually a bit more tricky than expected.
 * When moving an element inside the same category (changing the index), the
 * category has one element less than before and thus the target index will have
 * to be adjusted before inserting the object.
 */
-(BOOL)moveElement: (id<DatabaseElement>)anElement
      intoCategory: (id<Category>)aCategory
          position: (int)targetIndex
{
    // First check if we're just trying to move a category into a subcategory
    // of itself. The method directly fails in this case.
    id<Category> tmpCategory = aCategory;
    while (tmpCategory != nil) {
        if (tmpCategory == anElement) {
            return NO;
        }
        tmpCategory = [tmpCategory superElement];
    }
    
    id<Category> origSuperCategory = [anElement superElement];
    BOOL result = YES;
    
    // Delete
    if (origSuperCategory == nil) {
        if (aCategory == nil) { // src and target category are the same
            if ([topLevelElements indexOfObject: anElement] < targetIndex) {
                targetIndex--;
            }
        }
        [topLevelElements removeObject: anElement];
    } else {
        if (aCategory == origSuperCategory) {
            if ([[origSuperCategory elements] indexOfObject: anElement] < targetIndex) {
                targetIndex--;
            }
        }
        result = [origSuperCategory removeElement: anElement];
    }
    
    if (result == NO) {
        // Problems, better stopping the attempt right now.
        return NO;
    }
    
    // And insert again
    if (aCategory == nil) {
        [topLevelElements insertObject: anElement atIndex: targetIndex];
        [anElement setSuperElement: nil];
    } else {
        result = [aCategory insertElement: anElement atPosition: targetIndex];
        
        // FIXME: If this proves to be a problem, we can try to insert
        //        things back to where they came again here.
        NSAssert(result, @"Database corrupted.");
    }
    
    [self focusElement: anElement];
    [self sendChangeNotification];
    
    return result;
}

-(BOOL)moveElement: (id<DatabaseElement>)anElement
      intoCategory: (id<Category>)aCategory
{
    return [self moveElement: anElement
                intoCategory: aCategory
                    position: 0];
}

// ---------------------------------------------------
//    receiving notifications
// ---------------------------------------------------

// gets called whenever an article changes.
-(void)articleChanged: (NSNotification*)aNotification
{
    // add this article to the 'dirty' list
    [dirtyArticles addObject: [aNotification object]];
}

// ---------------------------------------------------
//    sending notifications
// ---------------------------------------------------

-(void) sendChangeNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName: DatabaseChangeNotification
                                                        object: self];
}

@end


