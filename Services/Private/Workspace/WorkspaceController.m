/* 
   WorkspaceController.m

   Workspace main controller
   
   Copyright (C) 2004 Quentin Mathe

   Author: Quentin Mathe <qmathe@club-internet.fr>
   Date: July 2004
   
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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <ExtendedWorkspaceKit/ExtendedWorkspaceKit.h>
#import "WkContextWindowController.h"
#import "WorkspaceController.h"

static NSNotificationCenter *nc = nil;

@interface NSArray (Whatever)

- (NSArray *) objectsWithValue: (id)value forKey: (NSString *)key;

@end

@implementation WorkspaceController

- (void) awakeFromNib
{
    openViewers = [[NSMutableArray alloc] init];
    nc = [NSNotificationCenter defaultCenter];
}

- (void) dealloc
{
    RELEASE(openViewers);
  
    [super dealloc];
}

- (IBAction) moveToURL: (id)sender
{
    NSURL *url = nil;
  
    //if ([sender tag] == 40)
    //{
        url = [NSURL fileURLWithPath: @"/"];
		NSLog(@"URL 1 %@", url);
    //}
    
    [self viewContextContentForURL: url];
}

- (void) viewContextContentForURL: (NSURL *)url
{
    WkContextWindowController *viewerController = [self viewerForURL: url];
  
    [openViewers addObject: viewerController];
  
    [[viewerController window] makeKeyAndOrderFront: self];
}

- (WkContextWindowController *) viewerForURL: (NSURL *)url
{
    WkContextWindowController *viewerController = nil;
    NSArray *objs = [openViewers objectsWithValue: url forKey: @"URL"];
    
    if (objs != nil)
    	viewerController = [objs objectAtIndex: 0];
  
    if (viewerController == nil)
    {
        viewerController = [[WkContextWindowController alloc] init];
        [NSBundle loadNibNamed: @"workspacewindow" owner: viewerController];
      
        [viewerController setURL: url];
        [viewerController reload];
      
        [nc addObserver: self selector: @selector(windowWillCloseNotification:)
        name : NSWindowWillCloseNotification object: [viewerController window]];
        
        AUTORELEASE(viewerController);
    }
    	
    return viewerController;
}

- (void) windowWillCloseNotification: (NSNotification *)notification
{
    WkContextWindowController *viewerController = [notification object];
    NSArray *objs = [openViewers objectsWithValue: [viewerController window] forKey: @"window"];
  
    if (objs != nil)
        [openViewers removeObject: [objs objectAtIndex: 0]];
}

@end
