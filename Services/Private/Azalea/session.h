/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   session.h for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   session.h for the Openbox window manager
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

#ifndef __ob__session_h
#define __ob__session_h

#import <Foundation/Foundation.h>

@class AZClient;

@interface AZSessionState: NSObject
{
    NSString *iden, *name, *class, *role;
    unsigned int stacking;
    unsigned int desktop;
    int x, y, w, h;
    BOOL shaded, iconic, skip_pager, skip_taskbar, fullscreen;
    BOOL above, below, max_horz, max_vert;

    BOOL matched;
}
- (NSString *) identifier;
- (NSString *) name;
- (NSString *) class;
- (NSString *) role;
- (unsigned int) stacking;
- (unsigned int) desktop;
- (int) x;
- (int) y;
- (int) w;
- (int )h;
- (BOOL) shaded;
- (BOOL) iconic;
- (BOOL) skip_pager;
- (BOOL) skip_taskbar;
- (BOOL) fullscreen;
- (BOOL) above;
- (BOOL) below;
- (BOOL) max_horz;
- (BOOL) max_vert;
- (BOOL) matched;
- (void) set_identifier: (NSString *) iden;
- (void) set_name: (NSString *) name;
- (void) set_class: (NSString *) class;
- (void) set_role: (NSString *) role;
- (void) set_stacking: (unsigned int) stacking;
- (void) set_desktop: (unsigned int) desktop;
- (void) set_x: (int) x;
- (void) set_y: (int) y;
- (void) set_w: (int) w;
- (void) set_h: (int )h;
- (void) set_shaded: (BOOL) shaded;
- (void) set_iconic: (BOOL) iconic;
- (void) set_skip_pager: (BOOL) skip_pager;
- (void) set_skip_taskbar: (BOOL) skip_taskbar;
- (void) set_fullscreen: (BOOL) fullscreen;
- (void) set_above: (BOOL) above;
- (void) set_below: (BOOL) below;
- (void) set_max_horz: (BOOL) max_horz;
- (void) set_max_vert: (BOOL) max_vert;
- (void) set_matched: (BOOL) matched;
@end

extern NSMutableArray *session_saved_state;

void session_startup(int *argc, char ***argv);
void session_shutdown();

AZSessionState* session_state_find(AZClient *c);
BOOL session_state_cmp(AZSessionState *s, AZClient *c);

#endif
