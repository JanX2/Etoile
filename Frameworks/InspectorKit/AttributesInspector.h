/*
   AttributesInspector.h
   The attributes inspector.

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

#import "InspectorModule.h"

@interface AttributesInspector : NSObject <InspectorModule>
{
  id computeSizeBtn;
  id date;
  id fileGroup;
  id fileOwner;
  id fileSize;
  id linkTo;
  id bogusWindow;
  id perms;
  id box;
  id okButton;
  id revertButton;

  NSString * path;

  NSDictionary * users;
  NSDictionary * groups,
               * myGroups;

  NSString * user;
  NSString * group;
  BOOL modeChanged;
  unsigned oldMode;
  unsigned mode;
}

- (void) changeOwner: sender;
- (void) changeGroup: (id)sender;
- (void) computeSize: (id)sender;

- (void) ok: sender;
- (void) revert: sender;

- (void) changePerms: sender;

@end
