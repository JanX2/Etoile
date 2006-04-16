// Modified by Yen-Ju Chen
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   startupnotify.h for the Openbox window manager
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
#import "AZMainLoop.h"

#ifdef USE_LIBSN
#define SN_API_NOT_YET_FROZEN
#include <libsn/sn.h>
#endif

@interface AZStartupHandler: NSObject <AZXHandler, NSCopying>
{
#ifdef USE_LIBSN
  SnDisplay *sn_display;
  SnMonitorContext *sn_context;
  NSMutableArray *sn_waits; /* list of ObWaitDatas */
#endif
}

+ (AZStartupHandler *) defaultHandler;

- (void) startup: (BOOL) reconfig;
- (void) shutdown: (BOOL) reconfig;

- (BOOL) applicationStarting;

/*! Notify that an app has started */
- (void) applicationStarted: (char *) wmclass;

/*! Get the desktop requested via the startup-notiication protocol if one
  was requested */
- (BOOL) getDesktop: (unsigned int *) desktop forIdentifier: (char *) iden;

@end
              
