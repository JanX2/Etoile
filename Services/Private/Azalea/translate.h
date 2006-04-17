/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   translate.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   translate.h for the Openbox window manager
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

#import <Foundation/Foundation.h>

BOOL translate_button(NSString *str, unsigned int *state, unsigned int *keycode);
BOOL translate_key(NSString *str, unsigned int *state, unsigned int *keycode);

