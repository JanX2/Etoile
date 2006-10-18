/*
	BKBookmark.h
	BKBookmark is the BookmarkKit class which is used to represent a bookmark
	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>
	Copyright (C) 2006 Yen-Ju Chen <yjchen @ gmail>>	                   
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2004
	Author:  Yen-Ju Chen <yjchen @ gmail>
	Date:  October 2006

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

#import <CollectionKit/CollectionKit.h>
#import <AppKit/AppKit.h>
#import <BookmarkKit/BKGlobals.h>

// FIXME: Rewrite bookmark protocols model with roles idea
typedef enum _BKBookmarkProtocol
{
  BKBookmarkNoProtocol,
  BKBookmarkFTPProtocol,
  BKBookmarkHTTPProtocol,
  BKBookmarkLocalProtocol
} BKBookmarkProtocol;

@interface BKBookmark : CKItem <BKTopLevel> 
{
  BKTopLevelType topLevel;
}

+ (BKBookmark *) bookmarkWithURL: (NSURL *)url;
+ (BKBookmark *) bookmarkWithXBEL: (NSString *)xbel;

- (id) initWithURL: (NSURL *)url;
- (id) initWithXBEL: (NSString *)xbel;

- (NSURL *) URL;
- (void) setURL: (NSURL *)url;
- (NSString *) title;
- (void) setTitle: (NSString *) title;
- (NSDate *) creationDate;
- (void) setCreationDate: (NSDate *)date;
- (NSDate *) lastVisitedDate;
- (void) setLastVisitedDate: (NSDate *)date;
- (NSImage *) favIcon;
- (void) setFavIcon: (NSImage *)icon;

- (id) propertyForKey: (NSString *)key;
- (void) setTextProperty: (NSString *)text forKey: (NSString *)key;
- (void) setImageProperty: (NSImage *)image forKey: (NSString *)key;

@end
