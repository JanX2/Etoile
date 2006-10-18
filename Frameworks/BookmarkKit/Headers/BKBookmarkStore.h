/*
	BKBookmarkStore.h

	BKBookmarkStore is the core BookmarkKit class to interact with the bookmarks

	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>
	Copyright (C) 2006 Yen-Ju Chen <yjchenx @ gmail>>	                   
	Author:  Quentin Mathe <qmathe@club-internet.fr>
	Date:  April 2004
	Author:  Yen-Ju Chen <yjchenx @ gmail>
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
#import <BookmarkKit/BKBookmark.h>
#import <BookmarkKit/BKBookmarkSearchResult.h>
#import <BookmarkKit/BKBookmarkQuery.h>

/* Commonly used domains for bookmark store */
extern NSString *const BKDefaultBookmarkStore;
extern NSString *const BKRecentFilesBookmarkStore;
extern NSString *const BKRecentApplicationsBookmarkStore;
extern NSString *const BKWebBrowserBookmarkStore;
extern NSString *const BKRSSBookmarkStore;

@interface BKBookmarkStore: CKCollection 
{
  NSMutableArray *_bookmarksSoupStore;
  NSMutableArray *_topLevelRecords;
}

+ (BKBookmarkStore *) sharedBookmarkStore;
+ (BKBookmarkStore *) sharedBookmarkWithDomain: (NSString *) domain;
+ (BKBookmarkStore *) sharedBookmarkAtPath: (NSString *)path; 
// support native format or XBEL format
+ (BKBookmarkStore *) sharedBookmarkAtURL: (NSURL *)url; 
// support native format or XBEL format

- (NSString *) path;
- (void) addProtocol: (BKBookmarkProtocol)bookmarkProtocol
  relativeToResourceSpecifier: (NSString *)resourceSpecifier
  relatedToProcotols: (NSArray *)bookmarkProtocols;
  // FIXME: roles idea must be used here to have a better method interface and
  // implementation. "relatedToProtocols" is here to support protocol variants
  // like "protocols combo" to be short, I mean http/web, http/webdav, ssh/svn 
  // etc.
- (void) removeProtocol: (BKBookmarkProtocol)bookmarkProtocol;

- (void) addBookmark: (BKBookmark *)bookmark;
- (void) removeBookmark: (BKBookmark *)bookmark;

- (BKBookmarkSearchResult *) searchWithQuery: (BKBookmarkQuery *)query;

- (void) save;
- (BOOL) hasUnsavedChanges;

/* Internally, records are stored as dictionary.
 * Therefore, the order of records is not conserved.
 * When a record is added into a group, it is stored as array.
 * So the group keep track of the order of its subgroup or items.
 * But for records without parent group, it is not tracked.
 * This method provide all the records without parent in order.
 * It returns mutable array so that the order can be changed.
 */
- (NSMutableArray *) topLevelRecords;

- (NSString *) transformToXBEL; // aspect
- (NSString *) transformToXMLNativeFormat; // aspect

@end
