/* 
   ViewerController.h

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

@class NSURL;
@class NSWindow;
@class NSMutableArray;
@class WkContextWindowController;

@interface WorkspaceController : NSObject
{
    NSMutableArray *openViewers;
}


// Action methods
- (IBAction) moveToURL: (id)sender;

// Main methods
- (void) viewContextContentForURL: (NSURL *)url;
- (WkContextWindowController *) viewerForURL: (NSURL *)url;

@end
