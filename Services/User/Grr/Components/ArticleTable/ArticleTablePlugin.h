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

#ifndef _ARTICLETABLEPLUGIN_H_
#define _ARTICLETABLEPLUGIN_H_

#import <Foundation/NSObject.h>

#import <RSSKit/RSSKit.h>
#import "Components.h"



@interface ArticleTablePlugin : ViewProvidingComponent <FilterComponent>
{
  // Instance variables
  NSArray* articles;
  NSMutableSet* articleSelection;
  
  IBOutlet NSTableView* table;
  
  NSTableColumn* headlineCol;
  NSTableColumn* dateCol;
  NSTableColumn* ratingCol;
}

// Class methods



// Instance methods

-(void)awakeFromNib;

-(void) setNewArrayWithoutNotification: (NSArray*) newArray;

// --------------- MVC Model Change Listening -------------------
-(void) articleChanged: (NSNotification*) aNotification;

// ---------------- NSTableView data source ----------------------

- (int) numberOfRowsInTableView: (NSTableView *)aTableView;


- (id)           tableView: (NSTableView *)aTableView
 objectValueForTableColumn: (NSTableColumn *)aTableColumn
                       row: (int)rowIndex;

// ------------------- NSTableView delegate ------------------------

- (void) tableViewSelectionDidChange: (NSNotification*) notif;

@end

#endif // _ARTICLETABLEPLUGIN_H_
