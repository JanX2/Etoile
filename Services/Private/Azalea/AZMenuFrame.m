// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   menuframe.c for the Openbox window manager
   Copyright (c) 2004        Mikael Magnusson
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

#import "AZMenuFrame.h"
#import "AZClient.h"
#import "menu.h"
#import "openbox.h"
#import "render/theme.h"

#define PADDING 2
#define SEPARATOR_HEIGHT 3

#if 0
#define MAX_MENU_WIDTH 400

#define FRAME_EVENTMASK (ButtonPressMask |ButtonMotionMask | EnterWindowMask |\
                         LeaveWindowMask)
#define TITLE_EVENTMASK (ButtonPressMask | ButtonMotionMask)
#endif

#define ENTRY_EVENTMASK (EnterWindowMask | LeaveWindowMask | \
                         ButtonPressMask | ButtonReleaseMask)

static Window createWindow(Window parent, gulong mask,
                           XSetWindowAttributes *attrib)
{
    return XCreateWindow(ob_display, parent, 0, 0, 1, 1, 0,
                         RrDepth(ob_rr_inst), InputOutput,
                         RrVisual(ob_rr_inst), mask, attrib);
}

@implementation AZMenuEntryFrame

- (id) initWithMenuEntry: (ObMenuEntry *) _entry 
               menuFrame: (ObMenuFrame *) _frame
{
  self = [super init];

  XSetWindowAttributes attr;

  entry = _entry;
  frame = _frame;

  attr.event_mask = ENTRY_EVENTMASK;
  window = createWindow(frame->items, CWEventMask, &attr);
  text = createWindow(window, 0, NULL);
  if (entry->type != OB_MENU_ENTRY_TYPE_SEPARATOR) {
      icon = createWindow(window, 0, NULL);
      bullet = createWindow(window, 0, NULL);
  }

  XMapWindow(ob_display, window);
  XMapWindow(ob_display, text);

  a_normal = RrAppearanceCopy(ob_rr_theme->a_menu_normal);
  a_disabled = RrAppearanceCopy(ob_rr_theme->a_menu_disabled);
  a_selected = RrAppearanceCopy(ob_rr_theme->a_menu_selected);

  if (entry->type == OB_MENU_ENTRY_TYPE_SEPARATOR) {
    a_separator = RrAppearanceCopy(ob_rr_theme->a_clear_tex);
    a_separator->texture[0].type = RR_TEXTURE_LINE_ART;
  } else {
    a_icon = RrAppearanceCopy(ob_rr_theme->a_clear_tex);
    a_icon->texture[0].type = RR_TEXTURE_RGBA;
    a_mask = RrAppearanceCopy(ob_rr_theme->a_clear_tex);
    a_mask->texture[0].type = RR_TEXTURE_MASK;
    a_bullet_normal =
    RrAppearanceCopy(ob_rr_theme->a_menu_bullet_normal);
    a_bullet_selected =
      RrAppearanceCopy(ob_rr_theme->a_menu_bullet_selected);
  }

  a_text_normal = RrAppearanceCopy(ob_rr_theme->a_menu_text_normal);
  a_text_disabled = RrAppearanceCopy(ob_rr_theme->a_menu_text_disabled);
  a_text_selected = RrAppearanceCopy(ob_rr_theme->a_menu_text_selected);

  return self;
}

- (void) dealloc
{
        XDestroyWindow(ob_display, text);
        XDestroyWindow(ob_display, window);
        if (entry->type != OB_MENU_ENTRY_TYPE_SEPARATOR) {
            XDestroyWindow(ob_display, icon);
            XDestroyWindow(ob_display, bullet);
        }

        RrAppearanceFree(a_normal);
        RrAppearanceFree(a_disabled);
        RrAppearanceFree(a_selected);

        RrAppearanceFree(a_separator);
        RrAppearanceFree(a_icon);
        RrAppearanceFree(a_mask);
        RrAppearanceFree(a_text_normal);
        RrAppearanceFree(a_text_disabled);
        RrAppearanceFree(a_text_selected);
        RrAppearanceFree(a_bullet_normal);
        RrAppearanceFree(a_bullet_selected);

	[super dealloc];
}

- (void) render
{
    RrAppearance *item_a, *text_a;
    gint th; /* temp */
    ObMenu *sub;

    item_a = ((entry->type == OB_MENU_ENTRY_TYPE_NORMAL &&
               !entry->data.normal.enabled) ?
              a_disabled : (self == frame->selected ?  a_selected : a_normal));
    switch (entry->type) {
    case OB_MENU_ENTRY_TYPE_NORMAL:
    case OB_MENU_ENTRY_TYPE_SUBMENU:
        th = frame->item_h;
        break;
    case OB_MENU_ENTRY_TYPE_SEPARATOR:
        th = SEPARATOR_HEIGHT + 2*PADDING;
        break;
    }
    RECT_SET_SIZE(area, frame->inner_w, th);
    XResizeWindow(ob_display, window,
                  area.width, area.height);
    item_a->surface.parent = frame->a_items;
    item_a->surface.parentx = area.x;
    item_a->surface.parenty = area.y;
    RrPaint(item_a, window, area.width, area.height);

    text_a = ((entry->type == OB_MENU_ENTRY_TYPE_NORMAL &&
               !entry->data.normal.enabled) ?
              a_text_disabled :
              (self == frame->selected ?
               a_text_selected :
               a_text_normal));
    switch (entry->type) {
    case OB_MENU_ENTRY_TYPE_NORMAL:
        text_a->texture[0].data.text.string = entry->data.normal.label;
        break;
    case OB_MENU_ENTRY_TYPE_SUBMENU:
        sub = entry->data.submenu.submenu;
        text_a->texture[0].data.text.string = sub ? sub->title : "";
        break;
    case OB_MENU_ENTRY_TYPE_SEPARATOR:
        break;
    }

    switch (entry->type) {
    case OB_MENU_ENTRY_TYPE_NORMAL:
        XMoveResizeWindow(ob_display, text,
                          frame->text_x, PADDING,
                          frame->text_w,
                          frame->item_h - 2*PADDING);
        text_a->surface.parent = item_a;
        text_a->surface.parentx = frame->text_x;
        text_a->surface.parenty = PADDING;
        RrPaint(text_a, text, frame->text_w,
                frame->item_h - 2*PADDING);
        break;
    case OB_MENU_ENTRY_TYPE_SUBMENU:
        XMoveResizeWindow(ob_display, text,
                          frame->text_x, PADDING,
                          frame->text_w - frame->item_h,
                          frame->item_h - 2*PADDING);
        text_a->surface.parent = item_a;
        text_a->surface.parentx = frame->text_x;
        text_a->surface.parenty = PADDING;
        RrPaint(text_a, text, frame->text_w - frame->item_h,
                frame->item_h - 2*PADDING);
        break;
    case OB_MENU_ENTRY_TYPE_SEPARATOR:
        XMoveResizeWindow(ob_display, text, PADDING, PADDING,
                          area.width - 2*PADDING, SEPARATOR_HEIGHT);
        a_separator->surface.parent = item_a;
        a_separator->surface.parentx = PADDING;
        a_separator->surface.parenty = PADDING;
        a_separator->texture[0].data.lineart.color =
            text_a->texture[0].data.text.color;
        a_separator->texture[0].data.lineart.x1 = 2*PADDING;
        a_separator->texture[0].data.lineart.y1 = SEPARATOR_HEIGHT / 2;
        a_separator->texture[0].data.lineart.x2 =
            area.width - 4*PADDING;
        a_separator->texture[0].data.lineart.y2 = SEPARATOR_HEIGHT / 2;
        RrPaint(a_separator, text,
                area.width - 2*PADDING, SEPARATOR_HEIGHT);
        break;
    }

    if (entry->type != OB_MENU_ENTRY_TYPE_SEPARATOR &&
        entry->data.normal.icon_data)
    {
        XMoveResizeWindow(ob_display, icon,
                          PADDING, frame->item_margin.top,
                          frame->item_h - frame->item_margin.top
                          - frame->item_margin.bottom,
                          frame->item_h - frame->item_margin.top
                          - frame->item_margin.bottom);
        a_icon->texture[0].data.rgba.width =
            entry->data.normal.icon_width;
        a_icon->texture[0].data.rgba.height =
            entry->data.normal.icon_height;
        a_icon->texture[0].data.rgba.data =
            entry->data.normal.icon_data;
        a_icon->surface.parent = item_a;
        a_icon->surface.parentx = PADDING;
        a_icon->surface.parenty = frame->item_margin.top;
        RrPaint(a_icon, icon,
                frame->item_h - frame->item_margin.top
                - frame->item_margin.bottom,
                frame->item_h - frame->item_margin.top
                - frame->item_margin.bottom);
        XMapWindow(ob_display, icon);
    } else if (entry->type != OB_MENU_ENTRY_TYPE_SEPARATOR &&
               entry->data.normal.mask)
    {
        RrColor *c;

        XMoveResizeWindow(ob_display, icon,
                          PADDING, frame->item_margin.top,
                          frame->item_h - frame->item_margin.top
                          - frame->item_margin.bottom,
                          frame->item_h - frame->item_margin.top
                          - frame->item_margin.bottom);
        a_mask->texture[0].data.mask.mask =
            entry->data.normal.mask;

        c = ((entry->type == OB_MENU_ENTRY_TYPE_NORMAL &&
              !entry->data.normal.enabled) ?
             entry->data.normal.mask_disabled_color :
             (self == frame->selected ?
              entry->data.normal.mask_selected_color :
              entry->data.normal.mask_normal_color));
        a_mask->texture[0].data.mask.color = c;

        a_mask->surface.parent = item_a;
        a_mask->surface.parentx = PADDING;
        a_mask->surface.parenty = frame->item_margin.top;
        RrPaint(a_mask, icon,
                frame->item_h - frame->item_margin.top
                - frame->item_margin.bottom,
                frame->item_h - frame->item_margin.top
                - frame->item_margin.bottom);
        XMapWindow(ob_display, icon);
    } else
        XUnmapWindow(ob_display, icon);

    if (entry->type == OB_MENU_ENTRY_TYPE_SUBMENU) {
        RrAppearance *bullet_a;
        XMoveResizeWindow(ob_display, bullet,
                          frame->text_x + frame->text_w
                          - frame->item_h + PADDING, PADDING,
                          frame->item_h - 2*PADDING,
                          frame->item_h - 2*PADDING);
        bullet_a = (self == frame->selected ?
                    a_bullet_selected :
                    a_bullet_normal);
        bullet_a->surface.parent = item_a;
        bullet_a->surface.parentx =
            frame->text_x + frame->text_w - frame->item_h
            + PADDING;
        bullet_a->surface.parenty = PADDING;
        RrPaint(bullet_a, bullet,
                frame->item_h - 2*PADDING,
                frame->item_h - 2*PADDING);
        XMapWindow(ob_display, bullet);
    } else
        XUnmapWindow(ob_display, bullet);

    XFlush(ob_display);
}

- (void) showSubmenu
{
    ObMenuFrame *f;

    if (!entry->data.submenu.submenu) return;

    f = menu_frame_new(entry->data.submenu.submenu,
                       frame->client);
    menu_frame_move(f,
                    frame->area.x + frame->area.width
                    - ob_rr_theme->menu_overlap - ob_rr_theme->bwidth,
                    frame->area.y + frame->title_h +
                    area.y + ob_rr_theme->menu_overlap);
    menu_frame_show(f, frame);
}

- (void) execute: (unsigned int) state
{
    if (entry->type == OB_MENU_ENTRY_TYPE_NORMAL &&
        entry->data.normal.enabled)
    {
        /* grab all this shizzle, cuz when the menu gets hidden, 'self'
           gets freed */
        ObMenuExecuteFunc func = frame->menu->execute_func;
        gpointer data = frame->menu->data;
        GSList *acts = entry->data.normal.actions;
        ObClient *client = frame->client;

        /* release grabs before executing the shit */
        if (!(state & ControlMask))
            menu_frame_hide_all();

        if (func)
            func(entry, state, data);
        else
            action_run(acts, client, state);
    }
}

- (Rect) area { return area; }
- (void) set_area: (Rect) a { area = a; }
- (RrAppearance *) a_text_normal { return a_text_normal; }
- (RrAppearance *) a_text_disabled { return a_text_disabled; }
- (RrAppearance *) a_text_selected { return a_text_selected; }
- (RrAppearance *) a_normal { return a_normal; }
- (RrAppearance *) a_selected { return a_selected; }
- (RrAppearance *) a_disabled { return a_disabled; }
- (Window) window { return window; }
- (struct _ObMenuEntry *) entry { return entry; }
- (void) set_entry: (struct _ObMenuEntry *) e { entry = e; }

@end

AZMenuEntryFrame* AZMenuEntryFrameUnder(int x, int y)
{
    ObMenuFrame *frame;
    AZMenuEntryFrame *ret = nil;
    GList *it;

    if ((frame = menu_frame_under(x, y))) {
        x -= ob_rr_theme->bwidth + frame->area.x;
        y -= frame->title_h + ob_rr_theme->bwidth + frame->area.y;

        for (it = frame->entries; it; it = g_list_next(it)) {
            AZMenuEntryFrame *e = it->data;

            if (RECT_CONTAINS([e area], x, y)) {
                ret = e;            
                break;
            }
        }
    }
    return ret;
}
