// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   menu.c for the Openbox window manager
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

#import "AZMenu.h"
#import "menu.h"

@implementation AZMenuEntry

- (id) initWithMenu: (struct _ObMenu *) m identifier: (int) iden
{
  self = [super init];
  menu = m;
  identifier = iden;
  return self;
}

- (ObMenuEntryType) type { return type; }
- (struct _ObMenu *) menu { return menu; }
- (int) identifier { return identifier; }
- (void) set_type: (ObMenuEntryType) t { type = t; }
- (void) set_menu: (struct _ObMenu *) m { menu = m; }
- (void) set_identifier: (int) i { identifier = i; }

@end

@implementation AZIconMenuEntry
- (int) icon_width { return icon_width; }
- (int) icon_height { return icon_height; }
- (RrPixel32 *) icon_data { return icon_data; }
- (RrPixmapMask *) mask { return mask; }
- (RrColor *) mask_normal_color { return mask_normal_color; }
- (RrColor *) mask_disabled_color { return mask_disabled_color; }
- (RrColor *) mask_selected_color { return mask_selected_color; }
- (void) set_icon_width: (int) i { icon_width = i; }
- (void) set_icon_height: (int) i { icon_height = i; }
- (void) set_icon_data: (RrPixel32 *) i { icon_data = i; }
- (void) set_mask: (RrPixmapMask *) m { mask = m; }
- (void) set_mask_normal_color: (RrColor *) m { mask_normal_color = m; }
- (void) set_mask_disabled_color: (RrColor *) m { mask_disabled_color = m; }
- (void) set_mask_selected_color: (RrColor *) m { mask_selected_color = m; }
@end

@implementation AZNormalMenuEntry

- (id) initWithMenu: (struct _ObMenu *) m identifier: (int) iden
              label: (gchar *) lab actions: (GSList *) acts
{
    self = [super initWithMenu: m identifier: iden];
    type = OB_MENU_ENTRY_TYPE_NORMAL;
    enabled = YES;
    label = g_strdup(lab);
    actions = acts;
    return self;
}

- (void) dealloc
{
  g_free(label);
  while (actions) {
    action_unref(actions->data);
    actions =
      g_slist_delete_link(actions, actions);
  }
  [super dealloc];
}

/* Accessories */
- (gchar *)label { return label; }
- (BOOL) enabled { return enabled; }
- (GSList *) actions { return actions; }
- (void) set_label: (gchar *) l { label = l; }
- (void) set_enabled: (BOOL) e { enabled = e; }
- (void) set_actions: (GSList *) a { actions = a; }

@end

@implementation AZSubmenuMenuEntry

- (gchar *) name { return name; }
- (struct _ObMenu *) submenu { return submenu; }
- (void) set_name: (gchar *) n { name = n; }
- (void) set_submenu: (struct _ObMenu *) s { submenu = s; }

- (id) initWithMenu: (struct _ObMenu *) m identifier: (int) iden submenu: (gchar *) s
{
  self = [super initWithMenu: m identifier: iden];
  type = OB_MENU_ENTRY_TYPE_SUBMENU;
  name = g_strdup(s);
  return self;
}

- (void) dealloc
{
  g_free(name);
  [super dealloc];
}

@end

@implementation AZSeparatorMenuEntry

- (id) initWithMenu: (struct _ObMenu *) m identifier: (int) iden
{
  self = [super initWithMenu: m identifier: iden];
  type = OB_MENU_ENTRY_TYPE_SEPARATOR;
  return self;
}

@end

