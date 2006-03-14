/* -*-objc-*-
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

#ifndef _RSSREADERARTICLE_H_
#define _RSSREADERARTICLE_H_

#include <RSSKit/RSSKit.h>
#include <Foundation/Foundation.h>

@interface RSSReaderArticle : RSSArticle
{
  // is this article already read?
  BOOL isRead;
}


-(id)initWithCoder: (NSCoder*)coder;
-(void)encodeWithCoder: (NSCoder*)coder;

- (BOOL) isRead;
- setRead: (BOOL) value;


@end

@interface RSSArticle (Subclassing)
-(BOOL) isSubclassedArticle;
@end

@interface RSSReaderArticle (Subclassing)
-(BOOL) isSubclassedArticle;
@end

#endif // _RSSREADERARTICLE_H_

