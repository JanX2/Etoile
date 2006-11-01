/* -*-objc-*-
   Project: RSSReader

   Copyright (C) 2005 Guenther Noack 

   Author: Guenther Noack,,,

   Created: 2005-05-31 21:21:50 +0000 by guenther

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

#ifndef _RSSREADERSERVICE_H_
#define _RSSREADERSERVICE_H_

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

@interface RSSReaderService : NSObject
{
}

-(void) addFeedWithURL: (NSPasteboard*) pboard
	      userData: (NSString*) userData
		 error: (NSString**) error;

@end

#endif // _RSSREADERSERVICE_H_

