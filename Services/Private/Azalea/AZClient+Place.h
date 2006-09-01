/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZClient+Place.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   place.h for the Openbox window manager
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

typedef enum
{
    OB_PLACE_POLICY_SMART,
    OB_PLACE_POLICY_MOUSE
} ObPlacePolicy;

@interface AZClient (AZPlace)
- (BOOL) placeAtX: (int *) x y: (int *) y;
@end

