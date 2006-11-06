/*  -*-objc-*-
 *
 *  GNUstep RSS Kit
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation, in version 2.1
 *  of the License
 * 
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "RSSFactory.h"
#import "RSSArticle+Storage.h"
#import "GNUstep.h"

static id<RSSFactory> sharedFactory = nil;
static NSString* RSSArticleStorageDirectory = nil;



/**
 * Converts a string to a string that's usable as a file system name. This is done
 * by removing several forbidden characters, only leaving the allowed ones. (A helper method)
 */
NSString* stringToFSString( NSString* aString )
{
    NSScanner* scanner = [NSScanner scannerWithString: aString];
    NSMutableString* string = [NSMutableString new];
    NSCharacterSet* allowedSet = [NSCharacterSet alphanumericCharacterSet];
    
    do {
        // discard any unknown characters
        if ([scanner scanUpToCharactersFromSet: allowedSet intoString: NULL] == YES) {
            [string appendString: @"_"];
        }
        
        // scan known characters...
        NSString* nextPart;
        BOOL success = [scanner scanCharactersFromSet: allowedSet intoString: &nextPart];
        
        // ...and add them to the string
        if (success == YES) {
            [string appendString: nextPart];
        }
    } while ([scanner isAtEnd] == NO);
    
    return [NSString stringWithString: string];
}


@implementation RSSFactory

/**
 * Returns the shared factory instance.
 */
+ (id<RSSFactory>) sharedFactory
{
    if (sharedFactory == nil) {
        ASSIGN(sharedFactory, [[RSSFactory alloc] init]);
    }
    
    return sharedFactory;
}

/**
 * Sets another shared factory instance than the currently selected one.
 */
+ (void) setFactory: (id<RSSFactory>) aFactory
{
    ASSIGN(sharedFactory, aFactory);
}


/**
 * The default implementation of this method returns a new article
 * of the RSSArticle class.
 */
- (id<RSSArticle>) articleWithHeadline: (NSString*) aHeadline
                                   URL: (NSString*) aURL
                               content: (NSString*) aContent
                                  date: (NSDate*) aDate
{
    id <RSSArticle> article = [[RSSArticle alloc] initWithHeadline: aHeadline
                                                               url: aURL
                                                       description: aContent
                                                              date: aDate];
    return [article autorelease];
}

/**
 * The default implementation of this method returns a new article
 * of the RSSArticle class.
 */
- (id<RSSArticle>) articleFromStorageWithURL: (NSString*) aURL
{
    return [self articleFromDictionary:
            [NSDictionary dictionaryWithContentsOfFile:
                [self storagePathForURL: aURL]]];
}



/**
 * The default implementation of this method returns a article
 * of the RSSArticle class.
 */
- (id<RSSArticle>) articleFromDictionary: (NSDictionary*) aDictionary
{
    return [[[RSSArticle alloc] initWithDictionary: aDictionary] autorelease];
}

/**
 * Returns the file path where an article with the anURL URL would be stored to.
 */
-(NSString*) storagePathForURL: (NSString*) anURL
{
    if (RSSArticleStorageDirectory == nil) {
        ASSIGN(RSSArticleStorageDirectory, [@"~/GNUstep/Library/RSSArticles" stringByExpandingTildeInPath]);
        
        NSFileManager* manager = [NSFileManager defaultManager];
        
        BOOL isDir, exists;
        exists = [manager fileExistsAtPath: RSSArticleStorageDirectory isDirectory: &isDir];
        
        if (exists) {
            if (isDir == NO) {
                [[NSException exceptionWithName: @"RSSArticleStorageDirectoryIsNotADirectory"
                                         reason: @"The storage directory for RSS articles is not a directory."
                                       userInfo: nil] raise];
            }
        } else {
            if ([manager createDirectoryAtPath: RSSArticleStorageDirectory
                                    attributes: nil] == NO) {
                [[NSException exceptionWithName: @"RSSArticleStorageDirectoryCreationFailed"
                                         reason: @"Creation of the storage directory for RSS Articles failed."
                                       userInfo: nil] raise];
            }
        }
    }
    
    return [NSString stringWithFormat: @"%@/%@.rssarticle", RSSArticleStorageDirectory, stringToFSString(anURL)];
}

@end


