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

#import "Article.h"

/**
 * This notification is sent when the read flag for an article changes.
 */
NSString* const ArticleReadFlagChangedNotification = @"ArticleReadFlagChangedNotification";


@implementation Article

/**
 * Initializes the object from a Plist dictionary.
 */
-(id)initWithDictionary: (NSDictionary*) aDictionary
{
    NSAssert(aDictionary != nil, @"Cannot initialise an article from the nil dictionary");
    
    if ((self = [super initWithDictionary: aDictionary]) != nil) {
        NSNumber* readFlagNumber = [aDictionary objectForKey: @"readFlag"];
        
        if (readFlagNumber) {
            _read = [readFlagNumber boolValue];
        } else {
            _read = YES;
        }
        
        NSNumber* ratingNumber = [aDictionary objectForKey: @"rating"];
        
        if (ratingNumber) {
            _rating = [ratingNumber intValue];
        } else {
            _rating = 0;
        }
    }
    
    return self;
}

/**
 * Designated initializer
 */
-(id)initWithHeadline: (NSString*) headline
                  url: (NSString*) url
          description: (NSString*) description
                 date: (NSDate*) date
{
    if((self = [super initWithHeadline: headline
                                   url: url
                           description: description
                                  date: date]) != nil) {
        _read = NO;
    }
    
    return self;
}

// Getter and setter for read variable
-(void)setRead: (BOOL)isRead
{
    if (_read != isRead) {
        _read = isRead;
        [self notifyChange];
        [[NSNotificationCenter defaultCenter] postNotificationName: ArticleReadFlagChangedNotification
                                                            object: self];
    }
}

-(BOOL)isRead
{
    return _read;
}

// Getter and setter for rating variable
-(void)setRating: (int)aRating
{
    if (_rating != aRating) {
        _rating = aRating;
        [self notifyChange];
    }
}

-(int)rating
{
    return _rating;
}

// Storage stuff
-(NSDictionary*)plistDictionary
{
    NSMutableDictionary* dict = [super plistDictionary];
    [dict setValue: [NSNumber numberWithBool: _read] forKey: @"readFlag"];
    [dict setValue: [NSNumber numberWithInt: _rating] forKey: @"rating"];
    return dict;
} 

-(void)willBeReplacedByArticle: (id<RSSMutableArticle>) newArticle
{
    NSParameterAssert([newArticle conformsToProtocol: @protocol(Article)]);
    
    id a = newArticle;
    [a setFeed: (id<RSSMutableFeed>)[self feed]];
    
    [super willBeReplacedByArticle: newArticle];
    
    [(id<Article>)newArticle setRating: _rating];
    [(id<Article>)newArticle setRead: _read];
}

@end
