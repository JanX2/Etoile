/* wdefaults.c - window specific defaults
 *
 *  Window Maker window manager
 *
 *  Copyright (c) 1997-2003 Alfredo K. Kojima
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
 *  USA.
 */

#include "wconfig.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <ctype.h>

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>

#include <wraster.h>


#include "WindowMaker.h"
#include "window.h"
#include "screen.h"
#include "funcs.h"
#include "workspace.h"
#include "defaults.h"
#include "icon.h"
#include "WMDefaults.h"


/* Global stuff */

extern WPreferences wPreferences;

/*
 *----------------------------------------------------------------------
 * wDefaultFillAttributes--
 * 	Retrieves attributes for the specified instance/class and
 * fills attr with it. Values that are actually defined are also
 * set in mask. If useGlobalDefault is True, the default for
 * all windows ("*") will be used for when no values are found
 * for that instance/class.
 *
 *----------------------------------------------------------------------
 */

/* This is only used for BOOL value */
static NSString *
get_value(NSDictionary *dict_win, NSDictionary *dict_class,
	  NSDictionary *dict_name, NSDictionary *dict_any,
	  NSString *option, NSString *default_value,
	  BOOL useGlobalDefault)
{
  id value = nil;

  if (dict_win) {
    value = [dict_win objectForKey: option];
    if (value)
      return value;
  }

  if (dict_name) {
    value = [dict_name objectForKey: option];
    if (value)
      return value;
  }

  if (dict_class) {
    value = [dict_class objectForKey: option];
    if (value)
      return value;
  }

  if (!useGlobalDefault)
    return nil;

  if (dict_any) {
    value = [dict_any objectForKey: option];
    if (value)
      return value;
  }

  return default_value;
}

void
wDefaultFillAttributes(WScreen *scr, char *instance, char *class,
                       WWindowAttributes *attr,
                       WWindowAttributes *mask,
                       Bool useGlobalDefault)
{
  /** FIXME: the implement may be wrong.
   * This only check one of the four combination:
   * instance.class, intance, class, anywindow.
   * The original try to check four of them in order.
   */
  NSString *key1, *key2, *key3;
  WMDefaults *defaults = [WMDefaults sharedDefaults];
  NSDictionary *dw = nil, *dc = nil, *dn = nil, *da = nil;
  id object;
  BOOL boolValue;

  if (class && instance)
  {
    key1 = [NSString stringWithFormat: @"%s.%s", instance, class];
  }
  else
  {
    key1 = nil;
  }

  if (instance)
  {
    key2 = [NSString stringWithCString: instance];
  }
  else
  {
    key2 = nil;
  }

  if (class)
  {
    key3 = [NSString stringWithCString: class];
  }
  else
  {
    key3 = nil;
  }

  if (key1)
    dw = [defaults attributesForWindow: key1];
  if (key2)
    dn = [defaults attributesForWindow: key2];
  if (key3)
    dc = [defaults attributesForWindow: key3];
  if (useGlobalDefault)
    da = [defaults attributesForWindow: WAAnyWindow];
  else
    da = nil;

#define APPLY_VAL(attrib, flag, df) \
  object = get_value(dw, dc, dn, da, attrib, df, useGlobalDefault); \
  if (object) { \
    boolValue = [object isEqualToString: @"YES"] ? YES : NO; \
    attr->flag = boolValue; \
    if (mask) mask->flag = 1; \
  }

  APPLY_VAL(WANoTitlebar, no_titlebar, WANo);
  APPLY_VAL(WANoResizebar, no_resizebar, WANo);
  APPLY_VAL(WANoMiniaturizeButton, no_miniaturize_button, WANo);
  APPLY_VAL(WANoCloseButton, no_close_button, WANo);
  APPLY_VAL(WANoBorder, no_border, WANo);
  APPLY_VAL(WANoHideOthers, no_hide_others, WANo);
  APPLY_VAL(WANoMouseBindings, no_bind_mouse, WANo);
  APPLY_VAL(WANoKeyBindings, no_bind_keys, WANo);
  APPLY_VAL(WANoAppIcon, no_appicon, WANo);
  APPLY_VAL(WASharedAppIcon, shared_appicon, WANo);
  APPLY_VAL(WAKeepOnTop, floating, WANo);
  APPLY_VAL(WAKeepOnBottom, sunken, WANo);
  APPLY_VAL(WAOmnipresent, omnipresent, WANo);
  APPLY_VAL(WASkipWindowList, skip_window_list, WANo);
  APPLY_VAL(WAKeepInsideScreen, dont_move_off, WANo);
  APPLY_VAL(WAUnfocusable, no_focusable, WANo);
  APPLY_VAL(WAAlwaysUserIcon, always_user_icon, WANo);
  APPLY_VAL(WAStartMiniaturized, start_miniaturized, WANo);
  APPLY_VAL(WAStartHidden, start_hidden, WANo);
  APPLY_VAL(WAStartMaximized, start_maximized, WANo);
  APPLY_VAL(WADontSaveSession, dont_save_session, WANo);
  APPLY_VAL(WAEmulateAppIcon, emulate_appicon, WANo);
  APPLY_VAL(WAFullMaximize, full_maximize, WANo);
#ifdef XKB_BUTTON_HINT
  APPLY_VAL(WANoLanguageButton, no_language_button, WANo);
#endif
}



id get_generic_value(WScreen *scr, char *instance, char *class, NSString *key,
                  Bool noDefault)
{
  WMDefaults *defaults = [WMDefaults sharedDefaults];
  id object = nil;

  if (class && instance)
  {
    object = [defaults objectForKey: key window: [NSString stringWithFormat: @"%s.%s", instance, class]];
    if (object)
    {
      return object;
    }
  }

  if (!object && instance)
  {
    object = [defaults objectForKey: key window: [NSString stringWithCString: instance]];
    if (object)
      return object;
  }

  if (!object && class)
  {
    object = [defaults objectForKey: key window: [NSString stringWithCString: class]];
    if (object)
      return object;
  }

  if (!object && !noDefault)
  {
    object = [defaults objectForKey: key window: WAAnyWindow];
    if (object)
      return object;
  }

  return nil;
}


char*
wDefaultGetIconFile(WScreen *scr, char *instance, char *class,
                    Bool noDefault)
{
    NSString *value;

    value = get_generic_value(scr, instance, class, WAIcon, noDefault);

    if (!value)
        return NULL;
    
    return (char*)[value cString];
}


RImage*
wDefaultGetImage(WScreen *scr, char *winstance, char *wclass)
{
    char *file_name;
    char *path;
    RImage *image;

    file_name = wDefaultGetIconFile(scr, winstance, wclass, False);
    if (!file_name)
        return NULL;

    path = FindImage(wPreferences.icon_path, file_name);

    if (!path) {
        wwarning(("could not find icon file \"%s\""), file_name);
        return NULL;
    }

    image = RLoadImage(scr->rcontext, path, 0);
    if (!image) {
        wwarning(("error loading image file \"%s\""), path, RMessageForError(RErrorCode));
    }
    wfree(path);

    image = wIconValidateIconSize(scr, image);

    return image;
}


int
wDefaultGetStartWorkspace(WScreen *scr, char *instance, char *class)
{
    int i;
    char *tmp;
    id value;

    value = get_generic_value(scr, instance, class, WAStartWorkspace,
                              False);

    if (!value)
        return -1;

    tmp = (char*)[value cString];

    if (!tmp || strlen(tmp)==0)
        return -1;

    for (i=0; i < scr->workspace_count; i++) {
      if (strcmp(scr->workspaces[i]->name, tmp)==0) {
        return i;
      }
    } 

    return -1;
}


void
wDefaultChangeIcon(WScreen *scr, char *instance, char* class, char *file)
{
  NSMutableString *ms = AUTORELEASE([[NSMutableString alloc] init]);
  WMDefaults *defaults = [WMDefaults sharedDefaults];
  id object, def_icon;
  int same = 0;

  if (instance)
    [ms appendString: [NSString stringWithCString: instance]];
  if (class)
  {
    if ([ms length] > 0)
      [ms appendString: @"."];

    [ms appendString: [NSString stringWithCString: class]];
  }

  if ([ms length] == 0)
  {
    [ms appendString: WAAnyWindow]; 
  }

  if (file) {
    object = [NSString stringWithCString: file];
    /* compare to default icon */
    def_icon = [defaults objectForKey: WAIcon window: WAAnyWindow];
    if ([object isEqual: def_icon])
    {
      same = 1;
    }

    if (same)
    {
      [defaults removeObjectForKey: WAIcon window: ms];
    }
    else
    {
      [defaults setObject: object forKey: WAIcon window: ms];
    }

    if (!wPreferences.flags.noupdates) {
      [defaults synchronize];
    }
  }
}


