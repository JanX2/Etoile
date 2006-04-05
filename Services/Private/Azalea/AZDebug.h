// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   debug.h for the Openbox window manager
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
#import <X11/Xlib.h>

/* Debug */
void AZDebugShowOutput(BOOL enable);
void AZDebug(char *a, ...);


/* XError */

/* can be used to track errors */
extern BOOL xerror_occured;

int AZXErrorHandler(Display *, XErrorEvent *);
void AZXErrorSetIgnore(BOOL ignore);

