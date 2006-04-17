/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZClient+Resist.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   resist.h for the Openbox window manager
   Copyright (c) 2003        Ben Jansens

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   See the COPYING file for a copy of the GNU General Public License.
*/

#import "AZClient.h"

@interface AZClient (AZResist)

/* FIXME: the names does not make much sence */
- (void) resistMoveWindowsAtX: (int *) x y: (int *) y;
- (void) resistMoveMonitorsAtX: (int *) x y: (int *) y;
- (void) resistSizeWindowsWithWidth: (int *) w height: (int *) h corner: (ObCorner) corn;
- (void) resistSizeMonitorsWithWidth: (int *) w height: (int *) h corner: (ObCorner) corn;

@end

