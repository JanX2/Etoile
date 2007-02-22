/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>
   
   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License version 2 as published by the Free Software Foundation.
   
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>
#import <AppKit/AppKit.h>

#import "Components.h"
#import "ToolbarDelegate.h"
#import "DatabaseElement.h"

#import "SubscriptionPanelProtocol.h"


@interface DatabaseOperationsComponent : NSObject <ToolbarDelegate, InputAcceptingComponent>
{
    NSSet* selectedFeeds;
    NSSet* selectedElements;
    id<DatabaseElement> subscriptionReferenceElement;
    id<SubscriptionPanel> subscriptionPanel;
    
    NSArray* allowedIdentifiers;
    NSArray* defaultIdentifiers;
    
    NSToolbarItem* fetchAllItem;
    NSToolbarItem* fetchItem;
    NSToolbarItem* subscribeItem;
    NSToolbarItem* addCategoryItem;
    NSToolbarItem* deleteItem;
    
    NSMenuItem* fetchAllMenuItem;
    NSMenuItem* fetchMenuItem;
    NSMenuItem* subscribeMenuItem;
    NSMenuItem* deleteMenuItem;
}

- (void) deleteSelectedElements;
- (void) fetchSelectedFeeds;
- (void) fetchAllFeeds;
- (void) subscribeFeed;
- (void) addCategory;

@end
