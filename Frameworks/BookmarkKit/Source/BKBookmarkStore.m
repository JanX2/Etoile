/*
	BKBookmarkStore.m

	BKBookmarkStore is the core BookmarkKit class to interact with the bookmarks

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
#import "BKBookmarkQuery.h"
#import "BKBookmarkSearchResult.h"
#import "BKBookmarkStore.h"

@implementation BKBookmarkStore

+ (BKBookmarkStore *) sharedInstanceForDefaultPath
{
	return nil;
}

+ (BKBookmarkStore *) sharedInstanceForPath: (NSString *)path 
// support native format or XBEL format
{
    return nil;
}

+ (BKBookmarkStore *) sharedInstanceForURL: (NSURL *)url
// support native format or XBEL format
{
    return nil;
}

- (NSString *) path
{
    return nil;
}

// FIXME: roles idea must be used here to have a better method interface and
// implementation. "relatedToProtocols" is here to support protocol variants
// like "protocols combo" to be short, I mean http/web, http/webdav, ssh/svn 
// etc.
- (void) addProtocol: (BKBookmarkProtocol)bookmarkProtocol 
  relativeToResourceSpecifier: (NSString *)resourceSpecifier 
  relatedToProcotols: (NSArray *)bookmarkProtocols;
{

}

- (void) removeProtocol: (BKBookmarkProtocol)bookmarkProtocol
{

}

- (void) addBookmark: (BKBookmark *)bookmark
{

}

- (void) removeBookmark: (BKBookmark *)bookmark
{

}

- (BKBookmarkSearchResult *) searchWithQuery: (BKBookmarkQuery *)query
{
    return nil;
}

- (void) save
{

}

- (void) hasUnsavedChanges
{

}

- (NSString *) transformToXBEL // aspect
{
    return nil;
}

- (NSString *) transformToXMLNativeFormat // aspect
{
    return nil;
}

@end
