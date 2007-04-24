/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZDebug.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   debug.c for the Openbox window manager
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

#import "AZDebug.h"
#import "openbox.h"
#if 0
#include <stdlib.h>
#include <stdarg.h>
#include <stdio.h>
#endif

static BOOL show;

void AZDebugShowOutput(BOOL enable)
{
    show = enable;
}

void AZDebug(const char *a, ...)
{
    va_list vl;

    if (show) {
        va_start(vl, a);
        vfprintf(stderr, a, vl);
        va_end(vl);
    }
}

static BOOL xerror_ignore = NO;
BOOL xerror_occured = NO;

int AZXErrorHandler(Display *d, XErrorEvent *e)
{
    xerror_occured = YES;
#ifdef DEBUG_AZALEA
    if (!xerror_ignore) {
        char errtxt[128];
        XGetErrorText(d, e->error_code, errtxt, 127);
        if (e->error_code == BadWindow)
            /*g_warning("X Error: %s", errtxt)*/;
        else
            g_error("X Error: %s", errtxt);
    }
#else
    (void)d; (void)e;
#endif
    return 0;
}

void AZXErrorSetIgnore(BOOL ignore)
{
    XSync(ob_display, NO);
    xerror_ignore = ignore;
}

