/* 
   WkContextTableViewController.m

   Context component table view controller
   
   Copyright (C) 2004 Quentin Mathe

   Author: Quentin Mathe <qmathe@club-internet.fr>
   Date: November 2004
   
   This file is part of the Etoile desktop environment.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#import <AppKit/AppKit.h>
#import <ExtendedWorkspaceKit/ExtendedWorkspaceKit.h>
#import "WkContextViewController.h"
#import "WkContextTableViewController.h"

@implementation WkContextTableViewController

- (id) initWithView: (NSView *)view
{
    if ([super initWithView: view] != nil)
    {
        ASSIGN(tableView, view);
		[tableView setDataSource: self];
        return self;
    }
    
    return nil;
}

/*
 * Table view data source methods
 */
 
- (int) numberOfRowsInTableView: (NSTableView *)tv
{
    return [subcontextsToView count]; 
}

- (id) tableView: (NSTableView *)tv objectValueForTableColumn: (NSTableColumn *)column row: (int)row
{
    if ([[column identifier] isEqualToString: @"Name"])
    {
        return [(EXContext *)[subcontextsToView objectAtIndex: row] name];
    }
    else if ([[column identifier] isEqualToString: @"ModificationDate"])
    {
        return [(EXContext *)[subcontextsToView objectAtIndex: row] modificationDate];
    }
    else if ([[column identifier] isEqualToString: @"CreationDate"])
    {
        return [(EXContext *)[subcontextsToView objectAtIndex: row] creationDate];
    }
    else if ([[column identifier] isEqualToString: @"Size"])
    {
        return [NSNumber numberWithInt:
		[(EXContext *)[subcontextsToView objectAtIndex: row] size]];
    }
    
    return nil;
}

- (void) reload
{
    [tableView reloadData];
}

@end
