/*
	BKBookmarkStore.m

	BKBookmarkStore is the core BookmarkKit class to interact with the bookmarks

	Copyright (C) 2004 Quentin Mathe <qmathe@club-internet.fr>
	Copyright (C) 2006 Yen-Ju Chen <yjchenx @ gmail >

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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <BookmarkKit/BKBookmark.h>
#import <BookmarkKit/BKGroup.h>
#import <BookmarkKit/BKBookmarkQuery.h>
#import <BookmarkKit/BKBookmarkSearchResult.h>
#import <BookmarkKit/BKBookmarkStore.h>
#import "GNUstep.h"

NSString *const BKDefaultBookmarkStore = @"BKDefaultBookmarkStore";
NSString *const BKRecentFilesBookmarkStore = @"BKRecentFilesBookmarkStore";
NSString *const BKRecentApplicationsBookmarkStore = @"BKRecentApplicationsBookmarkStore";
NSString *const BKWebBrowserBookmarkStore = @"BKWebBrowserBookmarkStore";
NSString *const BKRSSBookmarkStore = @"BKRSSBookmarkStore";

NSString *const BKBookmarkDirectory = @"Bookmark";
NSString *const BKBookmarkExtension = @"bookmark";

NSString *const kBKTopLevelOrderProperty = @"kBKTopLevelOrderProperty";

@implementation BKBookmarkStore

+ (BKBookmarkStore *) sharedBookmarkStore
{
  return [BKBookmarkStore sharedBookmarkWithDomain: BKDefaultBookmarkStore]; 
}

+ (BKBookmarkStore *) sharedBookmarkWithDomain: (NSString *) domain
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,  NSUserDomainMask, YES);
  if ([paths count] == 0)
    return nil;

  NSString *path = [paths objectAtIndex: 0];
  path = [path stringByAppendingPathComponent: BKBookmarkDirectory];
  path = [path stringByAppendingPathComponent: domain];
  path = [path stringByAppendingPathExtension: BKBookmarkExtension];
  
  return [BKBookmarkStore sharedBookmarkAtPath: path];
}

// support native format or XBEL format
+ (BKBookmarkStore *) sharedBookmarkAtPath: (NSString *)path 
{
  return AUTORELEASE([[BKBookmarkStore alloc] initWithLocation: path]);
}

+ (BKBookmarkStore *) sharedBookmarkAtURL: (NSURL *)url
// support native format or XBEL format
{
    return nil;
}

- (NSString *) path
{
  return [self location];
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
  [self addRecord: bookmark];
}

- (void) removeBookmark: (BKBookmark *)bookmark
{
  [self removeRecord: bookmark];
}

- (BKBookmarkSearchResult *) searchWithQuery: (BKBookmarkQuery *)query
{
  return nil;
}

- (void) save
{
  /* Go through all top level records and put an order number of it */
  NSEnumerator *e = [_topLevelRecords objectEnumerator];
  CKRecord *r;
  int i = 0;
  while ((r = [e nextObject])) {
    [r setValue: [NSString stringWithFormat: @"%d", i++] 
       forProperty: kBKTopLevelOrderProperty];
  }
  [super save];
}

- (BOOL) hasUnsavedChanges
{
  return [super hasUnsavedChanges];
}

- (NSMutableArray *) topLevelRecords
{
  return _topLevelRecords;
}

- (NSString *) transformToXBEL // aspect
{
  return nil;
}

- (NSString *) transformToXMLNativeFormat // aspect
{
  return nil;
}

/** override super class */
- (BOOL) addRecord: (CKRecord *) record
{
  if ([super addRecord: record]) {
    [_topLevelRecords addObject: record];
    return YES;
  }
  return NO;
}

- (BOOL) removeRecord: (CKRecord *) record
{
  if ([super removeRecord: record]) {
    [_topLevelRecords removeObject: record];
    return YES;
  }
  return NO;
}

- (BOOL) addItem: (CKItem *) it forGroup: (CKGroup*) group
{
  BKBookmark *item = (BKBookmark *) it;
  if ([item isTopLevel] == BKNotTopLevel) {
    /* Has parent already. */
    return NO;
  }

  if ([super addItem: item forGroup: group] == YES) {
    [item setTopLevel: BKNotTopLevel];
    [_topLevelRecords removeObject: item];
    return YES;
  } else {
    [item setTopLevel: BKUndecidedTopLevel];
    return NO;
  }
}

- (BOOL) removeItem: (CKItem *) it forGroup: (CKGroup*) group
{
  BKBookmark *item = (BKBookmark *) it;
  if ([super removeItem: item forGroup: group] == YES) {
    /* In BookmarkKit, an item can have only one parent.
     * If it is remove from a group, it should be at top level. */
    [item setTopLevel: BKTopLevel];
    [_topLevelRecords addObject: item];
    return YES;
  } else {
    [item setTopLevel: BKUndecidedTopLevel];
    return NO;
  }
}

- (BOOL) addSubgroup: (CKGroup*) g forGroup: (CKGroup*) g2
{
  BKGroup *g1 = (BKGroup *) g;
  if ([g1 isTopLevel] == BKNotTopLevel) {
    /* Has parent already. */
    return NO;
  }

  if ([super addSubgroup: g1 forGroup: g2] == YES) {
    [g1 setTopLevel: BKNotTopLevel];
    [_topLevelRecords removeObject: g1];
    return YES;
  } else {
    [g1 setTopLevel: BKUndecidedTopLevel];
    return NO;
  }
}

- (BOOL) removeSubgroup: (CKGroup*) g forGroup: (CKGroup*) g2
{
  BKGroup *g1 = (BKGroup *) g;
  if ([super removeSubgroup: g1 forGroup: g2] == YES) {
    /* In BookmarkKit, an item can have only one parent.
     * If it is remove from a group, it should be at top level. */
    [g1 setTopLevel: BKTopLevel];
    [_topLevelRecords addObject: g1];
    return YES;
  } else {
    [g1 setTopLevel: BKUndecidedTopLevel];
    return NO;
  }
}

- (id) initWithLocation: (NSString *) location
{
  self = [self initWithLocation: location itemClass: [BKBookmark class] groupClass: [BKGroup class]];

  /* Found all top level records */
  _topLevelRecords = [[NSMutableArray alloc] init];

  NSEnumerator *e = [[self items] objectEnumerator];
  CKRecord *r;
  NSNumber *n;
  while ((r = [e nextObject])) {
    n = [r valueForProperty: kBKTopLevelOrderProperty];
    if (n) {
      [_topLevelRecords addObject: r];
    }
  }
  e = [[self groups] objectEnumerator];
  while ((r = [e nextObject])) {
    n = [r valueForProperty: kBKTopLevelOrderProperty];
    if (n) {
      [_topLevelRecords addObject: r];
    }
  }
  [_topLevelRecords sortUsingSelector: @selector(compareTopLevelOrder:)];
  e = [_topLevelRecords objectEnumerator];
  while ((r = [e nextObject])) {
    [r removeValueForProperty: kBKTopLevelOrderProperty];
  }
  
  return self;
}

- (void) dealloc
{
  DESTROY(_topLevelRecords);
  [super dealloc];
}

@end
