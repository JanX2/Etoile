/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   grab.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   grab.c for the Openbox window manager
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

#import "AZScreen.h"
#import "AZEventHandler.h"
#import "AZDebug.h"
#import "grab.h"
#import "openbox.h"
#import <X11/Xlib.h>

#define GRAB_PTR_MASK (ButtonPressMask | ButtonReleaseMask | PointerMotionMask)
#define GRAB_KEY_MASK (KeyPressMask | KeyReleaseMask)

#define MASK_LIST_SIZE 8

/*! A list of all possible combinations of keyboard lock masks */
static unsigned int mask_list[MASK_LIST_SIZE];
static unsigned int kgrabs = 0;
static unsigned int pgrabs = 0;
/*! The time at which the last grab was made */
static Time  grab_time = CurrentTime;

static Time ungrab_time()
{
    Time t = event_curtime;
    if (!(t == CurrentTime || event_time_after(t, grab_time)))
    {
        /* When the time moves backward on the server, then we can't use
           the grab time because that will be in the future. So instead we
           have to use CurrentTime.

           "XUngrabPointer does not release the pointer if the specified time
           is earlier than the last-pointer-grab time or is later than the
           current X server time."
        */
        t = CurrentTime; /*grab_time;*/
    }
    return t;
}

BOOL grab_on_keyboard()
{
    return kgrabs > 0;
}

BOOL grab_on_pointer()
{
    return pgrabs > 0;
}

BOOL grab_keyboard(BOOL grab)
{
    BOOL ret = NO;

    if (grab) {
        if (kgrabs++ == 0) {
            ret = XGrabKeyboard(ob_display, RootWindow(ob_display, ob_screen),
                                NO, GrabModeAsync, GrabModeAsync,
                                event_curtime) == Success;
            if (!ret)
                --kgrabs;
            else
                grab_time = event_curtime;
        } else
            ret = YES;
    } else if (kgrabs > 0) {
        if (--kgrabs == 0)
	{
            XUngrabKeyboard(ob_display,  ungrab_time());
	}
        ret = YES;
    }

    return ret;
}

BOOL grab_pointer(BOOL grab, ObCursor cur)
{
    BOOL ret = NO;

    if (grab) {
        if (pgrabs++ == 0) {
            ret = XGrabPointer(ob_display, 
			       [[AZScreen defaultScreen] supportXWindow],
                               False, GRAB_PTR_MASK, GrabModeAsync,
                               GrabModeAsync, None,
                               ob_cursor(cur), event_curtime) == Success;
            if (!ret)
                --pgrabs;
            else
                grab_time = event_curtime;
        } else
            ret = YES;
    } else if (pgrabs > 0) {
        if (--pgrabs == 0) {
            XUngrabPointer(ob_display, ungrab_time());
        }
        ret = YES;
    }
    return ret;
}

BOOL grab_pointer_window(BOOL grab, ObCursor cur, Window win)
{
    BOOL ret = NO;

    if (grab) {
        if (pgrabs++ == 0) {
            ret = XGrabPointer(ob_display, win, False, GRAB_PTR_MASK,
                               GrabModeAsync, GrabModeAsync, None,
                               ob_cursor(cur),
                               event_curtime) == Success;
            if (!ret)
                --pgrabs;
            else
                grab_time = event_curtime;
        } else
            ret = YES;
    } else if (pgrabs > 0) {
        if (--pgrabs == 0) {
            XUngrabPointer(ob_display, ungrab_time());
        }
        ret = YES;
    }
    return ret;
}

int grab_server(BOOL grab)
{
    static unsigned int sgrabs = 0;
    if (grab) {
        if (sgrabs++ == 0) {
            XGrabServer(ob_display);
            XSync(ob_display, NO);
        }
    } else if (sgrabs > 0) {
        if (--sgrabs == 0) {
            XUngrabServer(ob_display);
            XFlush(ob_display);
        }
    }
    return sgrabs;
}

void grab_startup(BOOL reconfig)
{
    unsigned int i = 0;

    if (reconfig) return;

    unsigned int NumLockMask = [[AZEventHandler defaultHandler] numLockMask];
    unsigned int ScrollLockMask = [[AZEventHandler defaultHandler] scrollLockMask];

    mask_list[i++] = 0;
    mask_list[i++] = LockMask;
    mask_list[i++] = NumLockMask;
    mask_list[i++] = LockMask | NumLockMask;
    mask_list[i++] = ScrollLockMask;
    mask_list[i++] = ScrollLockMask | LockMask;
    mask_list[i++] = ScrollLockMask | NumLockMask;
    mask_list[i++] = ScrollLockMask | LockMask | NumLockMask;
    if (i != MASK_LIST_SIZE)
      NSLog(@"Internal Error: more than MASK_LIST_SIZE");
}

void grab_shutdown(BOOL reconfig)
{
    if (reconfig) return;

    while (grab_keyboard(NO));
    while (grab_pointer(NO, OB_CURSOR_NONE));
    while (grab_pointer_window(NO, OB_CURSOR_NONE, None));
    while (grab_server(NO));
}

void grab_button_full(unsigned int button, unsigned int state, Window win, unsigned int mask, int pointer_mode, ObCursor cur)
{
    unsigned int i;

    AZXErrorSetIgnore(YES); /* can get BadAccess' from these */
    xerror_occured = NO;
    for (i = 0; i < MASK_LIST_SIZE; ++i)
        XGrabButton(ob_display, button, state | mask_list[i], win, NO, mask,
                    pointer_mode, GrabModeSync, None, ob_cursor(cur));
    AZXErrorSetIgnore(NO);
    if (xerror_occured)
	NSLog(@"Warning: failed to grab button %d modifiers %d", button, state);
}

void grab_button(unsigned int button, unsigned int state, Window win, unsigned int mask)
{
    grab_button_full(button, state, win, mask, GrabModeAsync, OB_CURSOR_NONE);
}

void ungrab_button(unsigned int button, unsigned int state, Window win)
{
    unsigned int i;

    for (i = 0; i < MASK_LIST_SIZE; ++i)
        XUngrabButton(ob_display, button, state | mask_list[i], win);
}

void grab_key(unsigned int keycode, unsigned int state, Window win, int keyboard_mode)
{
    unsigned int i;

    AZXErrorSetIgnore(YES); /* can get BadAccess' from these */
    xerror_occured = NO;
    for (i = 0; i < MASK_LIST_SIZE; ++i)
        XGrabKey(ob_display, keycode, state | mask_list[i], win, NO,
                 GrabModeAsync, keyboard_mode);
    AZXErrorSetIgnore(NO);
    if (xerror_occured)
	NSLog(@"Warning: failed to grab keycode %d modifiers %d", keycode, state);
}

void ungrab_all_keys(Window win)
{
    XUngrabKey(ob_display, AnyKey, AnyModifier, win);
}
