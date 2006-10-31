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

#import "RSSLinks.h"
#import "RSSArticle.h"
#import "GNUstep.h"




@implementation RSSArticle


// methods to come... FIXME
- (id) init
{
  return [self initWithHeadline: @"no headline"
	       url: @"no URL"
	       description: @"no description"
	       time: 0 ];
}


- (id) initWithHeadline: (NSString*) myHeadline
	      url: (NSString*) myUrl
      description: (NSString*) myDescription
	     date: (NSDate*)   myDate
{
  [super init];
  
  ASSIGN(headline, myHeadline);
  ASSIGN(url, myUrl);
  ASSIGN(description, myDescription);
  ASSIGN(date, myDate);
  ASSIGN(links, AUTORELEASE([[NSMutableArray alloc] init]));
  
  return self;
}


- (id) initWithHeadline: (NSString*) myHeadline
	      url: (NSString*) myUrl
      description: (NSString*) myDescription
	     time: (unsigned int) myTime
{
  return
    [self initWithHeadline: myHeadline
	  url: myUrl
	  description: myDescription
	  date: [NSDate dateWithTimeIntervalSince1970: ((double)myTime)]
     ];
}


- (void) dealloc
{
  RELEASE(headline);
  RELEASE(url);
  RELEASE(description);
  RELEASE(date);
  RELEASE(links);
  
  [super dealloc];
}


#define ENCODING_VERSION 1

- (id) initWithCoder: (NSCoder*)coder
{
  if ((self = [super init]))
  {
    unsigned int version = 0;
    
    [coder decodeValueOfObjCType: @encode(unsigned int) at: &version];
    
    switch (version)
      {
      case 0:
	ASSIGN(date, [coder decodeObject]);
	ASSIGN(headline, [coder decodeObject]);
	ASSIGN(url, [coder decodeObject]);
	ASSIGN(description, [coder decodeObject]);
	break;
	
      case 1:
	ASSIGN(date, [coder decodeObject]);
	ASSIGN(headline, [coder decodeObject]);
	ASSIGN(url, [coder decodeObject]);
	ASSIGN(description, [coder decodeObject]);
	[self setLinks: [coder decodeObject]];
	break;
	
      default:
	NSLog(@"FATAL: Unknown RSSArticle version %d, please upgrade!",
	      version);
	break;
      }
  }
  
  return self;
}


- (void) encodeWithCoder: (NSCoder*)coder
{
  unsigned int version = ENCODING_VERSION;
  
  [coder encodeValueOfObjCType: @encode(unsigned int) at: &version];
  [coder encodeObject: date];
  [coder encodeObject: headline];
  [coder encodeObject: url];
  [coder encodeObject: description];
  [coder encodeObject: links];
}



- (NSString *) headline
{
  return headline;
}

- (NSString *) url
{
  return url;
}

- (NSString *) description
{
  return description;
}

- (NSString*) content
{
  return AUTORELEASE(RETAIN(description));
}

- (NSDate*) date
{
  return date;
}

- (void) setFeed:(RSSFeed*)aFeed
{
  // Feed is NON-RETAINED!
  feed = aFeed;
}

- (RSSFeed *) feed
{
  // Feed is NON-RETAINED!
  return feed;
}


- (NSURL*) enclosure
{
    return [[enclosure retain] autorelease];
}

/*
 * This method checks if the specified link is a enclosure. If it is, it is
 * stored in the article's enclosure field so that it can be easily returned
 * using the -enclosure method.
 */
-(void)_checkLinkForEnclosure: (NSURL*)link
{
    if ([link isKindOfClass: [RSSEnclosureLink class]]) {
        ASSIGN(enclosure, link);
    }
}

- (void) setLinks: (NSArray *) someLinks
{
  DESTROY(enclosure);
  
  [links setArray: someLinks];
  
  int i;
  for (i=0; i<[links count]; i++) {
      [self _checkLinkForEnclosure: [links objectAtIndex: i]];
  }
}

- (void) addLink: (NSURL *) anURL
{
  if (anURL == nil)
    return;
  
  [links addObject: anURL];
  
  [self _checkLinkForEnclosure: anURL];
}

- (NSArray *) links
{
  return links;
}

// Equality and hash codes
- (unsigned) hash
{
  return [headline hash] ^ [url hash];
}

/**
 * RSS Articles are equal if both the article headlines
 * and the article URLs are equal. If they are equal is
 * tested by calling the isEqual: method on those.
 */
- (BOOL) isEqual: (id)anObject
{
  if ( ( [headline isEqualToString: [anObject headline]] == YES ) &&
       ( [url      isEqualToString: [anObject url]]      == YES ) )
    {
      return YES;
    }
  else
    {
      return NO;
    }
}


@end

