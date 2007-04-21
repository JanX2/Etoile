/*
   ToolsInspector.h
   The tools inspector.

   Copyright (C) 2005 Saso Kiselkov

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

#include <AppKit/AppKit.h>

#import "InspectorModule.h"

@interface ToolsInspector : NSObject <InspectorModule>
{
        id appList;
        id appPath;
        id bogusWindow;
        id defaultApp;
        id textSv;
        id text;
        id view;
        id setDefaultButton;
        id revertButton;

        NSString * path;
}

- (void) appSelected: sender;
- (void) openWithApp: sender;
- (void) setDefault: sender;
- (void) revert: sender;

@end
