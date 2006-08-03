/*  -*-objc-*-
 *
 *  GNUstep RSS Kit
 *  Copyright (C) 2006 Guenther Noack
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#import "NewRSSArticleListener.h"
#import "RSSArticleCreationListener.h"

#define REL_KEY @"rel"
#define TYPE_KEY @"type"


@implementation RSSArticleComposer

-(id) init
{
  return [super init];
}

-(void) dealloc
{
  DESTROY(headline);
  DESTROY(url);
  DESTROY(summary);
  DESTROY(content);
  DESTROY(date);
  
  DESTROY(links);
  
  [super dealloc];
}


//delegate accessor methods

-(void) setDelegate: (id)aDelegate
{
  ASSIGN(delegate, aDelegate);
}

-(id) delegate
{
  return AUTORELEASE(RETAIN(delegate));
}



/**
 * Adds the article to the feed
 */
-(void) commitArticle
{
  RSSArticle* article;
  NSDate* articleDate;
  NSString* desc;
  
  // date
  if( date == nil )
    {
      articleDate = [[NSDate alloc] init];
    }
  else
    {
      articleDate = RETAIN(date);
    }
  
  // description
  if (content != nil)
    {
      desc = content;
    }
  else if (summary != nil)
    {
      desc = summary;
    }
  else
    {
      desc = @"No content.";
    }
  
  // create
  article = [[[delegate articleClass] alloc]
	      initWithHeadline: headline
	      url: url
	      description: desc
	      date: articleDate];
  
  // add links
  if ([links count] > 0)
    {
      [article setLinks: links];
    }
  
  // submit article
  #ifdef DEBUG
  NSLog(@"Commit, links is %@", links);
  #endif
  
  if (delegate != nil)
    [delegate newArticleFound: article];
  
  RELEASE(date);
  
  // desc needs NOT to be released or retained (only tmp ptr!)
}


/**
 * Gets called whenever a feed has been parsed completely.
 */
-(void) finished
{
  #ifdef DEBUG
  NSLog(@"%@ finished, rc=%d", self, [self retainCount]);
  #endif
  
  // empty at the moment, may be useful for things like thread locking
  // in the future.
}


/**
 * Starts a new article
 */
-(void) startArticle
{
  #ifdef DEBUG
  NSLog(@"start article");
  
  NSLog(@"retain counts in start article: %d %d %d",
	[headline retainCount],
	[links retainCount],
	[date retainCount]);
  #endif
  
  // Free all old stuff
  RELEASE(headline);
  RELEASE(url);
  RELEASE(summary);
  RELEASE(content);
  RELEASE(date);
  
  RELEASE(links);
  
  // Set default values
  headline = @"No headline";
  url = nil;
  summary = nil;
  content = nil;
  date = nil;
  
  links = [[NSMutableArray alloc] initWithCapacity: 1];
}

// don't use this, use commitArticle
// and startArticle directly instead!
-(void) nextArticle
{
  #ifdef DEBUG
  NSLog(@"Warning: nextArticle should not be called.");
  #endif
  
  [self commitArticle];
  [self startArticle];
}


-(void)setHeadline: (NSString*) aHeadline
{
  RELEASE(headline);
  headline = RETAIN(aHeadline);
}

-(void) addLinkWithURL: (NSString*) anURL
{
  // default is 'alternate', see ATOM specification!
  [self addLinkWithURL: anURL
	andRel: @"alternate"];
}

-(void) addLinkWithURL: (NSString*) anURL
		andRel: (NSString*) aRelation
{
  [self addLinkWithURL: anURL
	andRel: aRelation
	andType: nil];
}

/**
 * Adds a link with a specified URL, relation type and file type.
 * 
 * Relation type is one of:
 * <ul>
 *  <li>"alternate": This link leads to an alternative location where
 *                   this article's contents can be found.</li>
 *  <li>"enclosure": A related resource which is probably large in size.
 *                   This may link to a movie, a mp3 file, etc.</li>
 *  <li>"related":   A related document</li>
 *  <li>"self":      The feed itself</li>
 *  <li>"via":       The source of the information provided in the entry.</li>
 * </ul>
 *
 * These relation types are compatible with the ones of the ATOM
 * specification. For details, see
 * <a href="http://www.atomenabled.org/developers/syndication/#link">
 * the ATOM specification.</a>
 */
-(void) addLinkWithURL: (NSString*) anURL
		andRel: (NSString*) aRelation
	       andType: (NSString*) aType
{
  NSURL* actualURL;
  
  #ifdef DEBUG
  NSLog(@"addLinkWithURL: %@ andRel: %@ andType: %@",
	anURL, aRelation, aType);
  #endif
  
  actualURL = [[NSURL alloc] initWithString: anURL];
  
  if (aType != nil)
    {
      [actualURL setProperty: aType
		 forKey: TYPE_KEY];
    }
  
  if (aRelation != nil)
    {
      [actualURL setProperty: aRelation
		 forKey: REL_KEY];
      
      if ([aRelation isEqualToString: @"alternate"])
	{
	  RELEASE(url);
	  url = RETAIN(anURL); // anURL, the String version!
	}
    }
  
  [links addObject: actualURL];
  RELEASE(actualURL);
  
  #ifdef DEBUG
  NSLog(@"links is now %@", links);
  #endif
}

-(void) setContent: (NSString*) aContent
{
  RELEASE(content);
  content = RETAIN(aContent);
}

-(void) setSummary: (NSString*) aSummary
{
  RELEASE(summary);
  summary = RETAIN(aSummary);
}

-(void) setDate: (NSDate*) aDate
{
  RELEASE(date);
  date = RETAIN(aDate);
}

@end
