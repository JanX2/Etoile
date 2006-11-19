/* 
   WkContextWindowContrller.h

   Workspace windows controller
   
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

@class NSURL;
@class EXContext;
@class WkContextViewController;

typedef enum _WorkspaceViewMode
{
    WorkspaceViewModeIcon,
    WorkspaceViewModeList
} WorkspaceViewMode;

@interface WkContextWindowController : NSObject
{
    id workspaceWindow;
    id contextView;
    EXContext *context;
    WkContextViewController *contextViewController;
}

- (id) initWithViewMode: (WorkspaceViewMode)viewMode;

- (void) reload;

/*
 * Accessors
 */
 
- (EXContext *) context;
- (NSView *) contextView;
- (NSURL *) URL;
- (NSWindow *) window;
- (void) setContext: (EXContext *)aContext;
- (void) setContextView: (NSView *)aContextView;
- (void) setURL: (NSURL *)url;

@end
