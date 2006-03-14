/*
   Project: RSSReader

   Copyright (C) 2005 Free Software Foundation

   Author: Guenther Noack,,,

   Created: 2005-05-29 15:50:00 +0000 by guenther

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "RSSReaderArticle.h"

@implementation RSSArticle (Subclassing)
-(BOOL) isSubclassedArticle
{
  return NO;
}
@end

@implementation RSSReaderArticle (Subclassing)
-(BOOL) isSubclassedArticle
{
  return YES;
}
@end

@implementation RSSReaderArticle


-initWithHeadline: (NSString*) myHeadline
              url: (NSString*) myUrl
      description: (NSString*) myDescription
             date: (NSDate*)   myDate
{
  self = [super initWithHeadline: myHeadline
		url: myUrl
		description: myDescription
		date: myDate];
  
  if ( self != nil )
    {
      isRead = NO;
    }
  
  return self;
}


-(id)initWithCoder: (NSCoder*)coder
{
  if ((self = [super initWithCoder: coder]))
  {
    int encodingVersion;
    [coder decodeValueOfObjCType: @encode(int) at: &encodingVersion];
    
    switch(encodingVersion)
      {
      case 1: // version 0.5pre (1)
	[coder decodeValueOfObjCType: @encode(BOOL) at: &isRead];
	break;
	
      default:
	NSLog(@"Fatal: no encoding verion for RSSReaderArticle!");
	break;
      }
  }
  
  return self;
}


-(void)encodeWithCoder: (NSCoder*)coder
{
  int encodingVersion = 1; // version 0.5pre (1)
  
  [super encodeWithCoder: coder];
  
  [coder encodeValueOfObjCType: @encode(int) at: &encodingVersion];
  [coder encodeValueOfObjCType: @encode(BOOL) at: &isRead];
}


- (BOOL) isRead
{
  return isRead;
}


- setRead: (BOOL) value
{
  isRead = value;
}

@end
