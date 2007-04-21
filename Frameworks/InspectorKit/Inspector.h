/*
   Inspector.h
   The workspace manager's inspector.

   This file is part of OpenSpace.

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

#import <AppKit/AppKit.h>

@protocol InspectorModule;

@interface Inspector : NSObject
{
  NSBox * box;
  id filename;
  id icon;
  id panel;
  id path;
  id popUpButton;
  id multipleSelectionView;
  id multipleSelectionViewBogusWindow;

  NSString * filePath;

   // built-in inspectors
  id attrs,
     tools,
     perms,
     noContents;

  NSMutableArray * contentsInspectors;
  
  id <InspectorModule> currentInspector;
}

+ shared;

- (void) displayPath: (NSString *) aPath;

 // order the inspector front
- (void) activate;

- (void) selectView: (id)sender;

- (void) showAttributesInspector: sender;
- (void) showContentsInspector: sender;
- (void) showToolsInspector: sender;
- (void) showPermissionsInspector: sender;

@end
