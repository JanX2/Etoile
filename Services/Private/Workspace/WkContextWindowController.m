/* 
   WkContextWindowController.m

   Workspace windows controller
   
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

#import <AppKit/AppKit.h>
#import <ExtendedWorkspaceKit/ExtendedWorkspaceKit.h>
#import <EtoileExtensions/UKDistributedView.m>
#import "WkContextViewController.h"
#import "WkContextWindowController.h"

static EXWorkspace *workspace = nil;
static EXVFS *vfs = nil;

@implementation WkContextWindowController

+ (void) initialize
{
    if (self == [WkContextWindowController class])
    {
        workspace = [EXWorkspace sharedInstance];
        vfs = [EXVFS sharedInstance];
    }
}

- (id) initWithViewMode: (WorkspaceViewMode)viewMode
{
    if ((self = [super init]) != nil)
    {
        NSView *view;
		
		if (viewMode == WorkspaceViewModeList)
        {
            view = [[NSTableView alloc] initWithFrame: [contextView frame]];
        }
		else if (viewMode == WorkspaceViewModeIcon)
		{
			view = [[UKDistributedView alloc] initWithFrame: [contextView frame]];
		}
		[self setContextView: view];
		contextViewController = [[WkContextViewController alloc] initWithView: view];		
		
		return self;
    }
    
    return nil;
}

- (void) reload
{
    [contextViewController reload];
}

/*
 * Accessors
 */
 
- (EXContext *) context
{
    return context;
}

- (NSView *) contextView
{
    return contextView;
}
 
- (NSURL *) URL
{
    return [context URL];
}
 
- (NSWindow *) window
{
    return workspaceWindow;
}
 
- (void) setContext: (EXContext *)aContext
{
    ASSIGN(context, aContext);
    [contextViewController setContext: context];
}

- (void) setContextView: (NSView *)aContextView
{
    ASSIGN(contextView, aContextView);
}

- (void) setURL: (NSURL *)url
{
    [self setContext: [workspace contextForURL: url]];
}

@end
