/* -*-objc-*-
   
   Project: RSSReader

   Copyright (C) 2006 Yen-Ju Chen
   Copyright (C) 2005 Guenther Noack

   Author: Yen-Ju Chen
   Author: Guenther Noack,,,

   Created: 2005-03-25 19:42:31 +0100 by guenther
   
   Application Controller

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
 
#import <AppKit/AppKit.h>
#import <BookmarkKit/BookmarkKit.h>
#import <CollectionKit/CollectionKit.h>

@class MainWindow;
@class FeedList;
@class ContentTextView;

@interface Controller : NSObject
{
  MainWindow* mainWindow;
  BKBookmarkView* feedBookmarkView;
  CKCollectionView *articleCollectionView;
  ContentTextView *contentTextView;
  NSSearchField *searchField;
#if 0
  NSPanel* logPanel;
#endif

  FeedList *feedList;
}

+ (Controller *) mainController;

- (void) showPreferencePanel: (id) sender;

- (void) subscribe: (id) sender;
- (void) addGroup: (id) sender;
- (void) reload: (id) sender;
- (void) reloadAll: (id) sender;
- (void) delete: (id) sender;

- (void) markAllRead: (id) sender;
- (void) markAllUnread: (id) sender;
- (void) markRead: (id) sender;
- (void) markUnread: (id) sender;

- (void) search: (id) sender;

@end

