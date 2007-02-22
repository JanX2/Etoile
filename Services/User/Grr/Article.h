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

#import <RSSKit/RSSArticle.h>
#import <RSSKit/RSSArticle+Storage.h>


/**
 * This notification is sent when the read flag for an article changes.
 */
extern NSString* const ArticleReadFlagChangedNotification;


@protocol Article <RSSMutableArticle>
// Getter and setter for read variable
-(void)setRead: (BOOL)isRead;
-(BOOL)isRead;

// Getter and setter for rating variable
-(void)setRating: (int)aRating;
-(int)rating;
@end

@interface Article : RSSArticle <Article>
{
    BOOL _read;
    int _rating;
}

/**
 * Initializes the object from a Plist dictionary.
 */
-(id)initWithDictionary: (NSDictionary*) aDictionary;

/**
 * Designated initializer
 */
-(id)initWithHeadline: (NSString*) headline
                  url: (NSString*) url
          description: (NSString*) description
                 date: (NSDate*) date;

// Getter and setter for read variable
-(void)setRead: (BOOL)isRead;
-(BOOL)isRead;

// Getter and setter for rating variable
-(void)setRating: (int)aRating;
-(int)rating;

/**
 * This method is intended to make sure that the replacing article keeps
 * some fields from the old (this) article. Subclasses will probably want
 * to override this, but shouldn't forget calling the super implementation,
 * first.
 */
-(void)willBeReplacedByArticle: (id<RSSMutableArticle>) newArticle;

@end

