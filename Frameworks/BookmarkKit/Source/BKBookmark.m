/*
	BKBookmark.m

	BKBookmark is the BookmarkKit class which is used to represent a bookmark

	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>	                   

	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2004

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 2.1 of the License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "BKBookmark.h"

@implementation BKBookmark

+ bookmarkWithURL: (NSURL *)url
{
    return nil;
}

+ bookmarkWithXBEL: (NSString *)xbel
{
    return nil;
}

- (id) initWithURL: (NSURL *)url
{
    return nil;
}

- (id) initWithXBEL: (NSString *)xbel
{
    return nil;
}

- (NSURL *) URL
{
    return nil;
}

- (NSDate *) creationDate
{
    return nil;
}

- (void) setCreationDate: (NSDate *)date
{

}

- (NSDate *) lastVisitDate
{
    return nil;
}

- (void) setLastVisitDate: (NSDate *)date
{

}

- (NSImage *) favIcon
{
    return nil;
}

- (void) setFavIcon: (NSImage *)icon
{

}

- (id) propertyForKey: (NSString *)key
{
    return nil;
}

- (void) setTextProperty: (NSString *)text forKey: (NSString *)key
{

}

- (void) setImageProperty: (NSImage *)image forKey: (NSString *)key
{

}

@end
