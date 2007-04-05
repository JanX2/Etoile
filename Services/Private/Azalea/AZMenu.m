/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZMenu.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

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
#import "AZMenuManager.h"

@implementation AZMenuEntry

- (id) initWithMenu: (AZMenu *) m identifier: (int) iden
{
  self = [super init];
  menu = m;
  identifier = iden;
  return self;
}

- (ObMenuEntryType) type { return type; }
- (AZMenu *) menu { return menu; }
- (int) identifier { return identifier; }
- (void) set_type: (ObMenuEntryType) t { type = t; }
- (void) set_menu: (AZMenu *) m { menu = m; }
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

- (id) initWithMenu: (AZMenu *) m identifier: (int) iden
              label: (NSString *) lab actions: (NSArray *) acts
{
    self = [super initWithMenu: m identifier: iden];
    type = OB_MENU_ENTRY_TYPE_NORMAL;
    enabled = YES;
    ASSIGNCOPY(label, lab);
    ASSIGNCOPY(actions, acts);
    return self;
}

- (void) dealloc
{
  DESTROY(label);
  DESTROY(actions);
  [super dealloc];
}

/* Accessories */
- (NSString *)label { return label; }
- (BOOL) enabled { return enabled; }
- (NSArray *) actions { return actions; }
- (void) set_label: (NSString *) l { ASSIGNCOPY(label, l); }
- (void) set_enabled: (BOOL) e { enabled = e; }
- (void) set_actions: (NSArray *) a { ASSIGNCOPY(actions, a); }

@end

@implementation AZSubmenuMenuEntry

- (NSString *) name { return name; }
- (AZMenu *) submenu { return submenu; }
- (void) set_name: (NSString *) n { ASSIGNCOPY(name, n); }
- (void) set_submenu: (AZMenu *) s { submenu = s; }

- (id) initWithMenu: (AZMenu *) m identifier: (int) iden submenu: (NSString *) s
{
  self = [super initWithMenu: m identifier: iden];
  type = OB_MENU_ENTRY_TYPE_SUBMENU;
  ASSIGNCOPY(name, s);
  return self;
}

- (void) dealloc
{
  DESTROY(name);
  [super dealloc];
}

@end

@implementation AZSeparatorMenuEntry

- (id) initWithMenu: (AZMenu *) m identifier: (int) iden
{
  self = [super initWithMenu: m identifier: iden];
  type = OB_MENU_ENTRY_TYPE_SEPARATOR;
  return self;
}

@end

@implementation AZMenu

- (AZMenuEntry *) entryWithIdentifier: (int) identifier
{
    AZMenuEntry *ret = nil;
    int i, count = [entries count];
    for (i = 0; i < count; i++) {
        AZMenuEntry *e = [entries objectAtIndex: i];
        if ([e identifier] == identifier) {
	        ret = e;
	        break;
        }
    }
    return ret;
}


- (void) findSubmenus
{
  AZMenuManager *mManager = [AZMenuManager defaultManager];
  int i, count = [entries count];
  for (i = 0; i < count; i++) {
     AZMenuEntry *e = [entries objectAtIndex: i];
     if ([e type] == OB_MENU_ENTRY_TYPE_SUBMENU)
       [(AZSubmenuMenuEntry *)e set_submenu: [mManager menuWithName: [(AZSubmenuMenuEntry *)e name]]];
  }
}

- (AZNormalMenuEntry *) addNormalMenuEntry: (int) identifier 
                        label: (NSString *) label actions: (NSArray *) actions
{
  AZNormalMenuEntry *e = [[AZNormalMenuEntry alloc] initWithMenu: self 
	                                  identifier: identifier
	                                  label: label actions: actions];
  [entries addObject: e];
  return AUTORELEASE(e);
}

- (AZSubmenuMenuEntry *) addSubmenuMenuEntry: (int) iden 
                         submenu: (NSString *) submenu
{
  AZSubmenuMenuEntry *e = [[AZSubmenuMenuEntry alloc] initWithMenu: self 
	                             identifier: iden submenu: submenu];

  [entries addObject: e];
  return AUTORELEASE(e);
}

- (AZSeparatorMenuEntry *) addSeparatorMenuEntry: (int) identifier
{
  AZSeparatorMenuEntry *e = [[AZSeparatorMenuEntry alloc] initWithMenu: self 
	           identifier: identifier];
  [entries addObject: e];
  return AUTORELEASE(e);
}

- (void) removeEntryWithIdentifier: (int) iden
{
  AZMenuEntry *e = [self entryWithIdentifier: iden];
  if (e)
    [entries removeObject: e];
}

- (void) clearEntries
{
#ifdef DEBUG_AZALEA
    /* assert that the menu isn't visible */
    {
        GList *it;
        AZMenuFrame *f;

        for (it = menu_frame_visible; it; it = g_list_next(it)) {
            f = it->data;
            g_assert([f menu] != self);
        }
    }
#endif

    [entries removeAllObjects];
}

- (id) initWithName: (NSString *) n title: (NSString *) t
{
  self = [super init];
  ASSIGNCOPY(name, n);
  ASSIGNCOPY(title, t);
  entries = [[NSMutableArray alloc] init];
  return self;
}

- (void) dealloc
{
  [self clearEntries];
  DESTROY(entries);
  DESTROY(name);
  DESTROY(title);
  DESTROY(execute);
  [super dealloc];
}

- (void) pipeExecute
{
  menu_pipe_execute(self);
}

- (void) update: (AZMenuFrame *) frame 
{
  // subclass
}

- (BOOL) execute: (AZMenuEntry *) entry state: (unsigned int) state 
            time: (Time) time
{
  return NO;
}


- (NSString *) name { return name; }
- (NSString *) title { return title; }
- (NSString *) execute { return execute; }
- (NSMutableArray *) entries { return entries; }
- (AZMenu *) pipe_creator { return pipe_creator; }
- (void) set_name: (NSString *) n { ASSIGNCOPY(name, n); }
- (void) set_title: (NSString *) t { ASSIGNCOPY(title, t); }
- (void) set_execute: (NSString *) e { ASSIGNCOPY(execute, e); }
- (void) set_pipe_creator: (AZMenu *) p { pipe_creator = p; }

@end


