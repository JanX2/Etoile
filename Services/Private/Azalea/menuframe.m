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

#import "AZScreen.h"
#import "AZDock.h"
#import "AZClient.h"
#import "AZMenuFrame.h"
#include "menuframe.h"
#include "menu.h"
#include "grab.h"
#include "openbox.h"
#include "config.h"
#include "render/theme.h"

#define PADDING 2
#define SEPARATOR_HEIGHT 3
#define MAX_MENU_WIDTH 400

#define FRAME_EVENTMASK (ButtonPressMask |ButtonMotionMask | EnterWindowMask |\
                         LeaveWindowMask)
#define TITLE_EVENTMASK (ButtonPressMask | ButtonMotionMask)

GList *menu_frame_visible;

static void menu_frame_render(ObMenuFrame *self);
static void menu_frame_update(ObMenuFrame *self);

static Window createWindow(Window parent, gulong mask,
                           XSetWindowAttributes *attrib)
{
    return XCreateWindow(ob_display, parent, 0, 0, 1, 1, 0,
                         RrDepth(ob_rr_inst), InputOutput,
                         RrVisual(ob_rr_inst), mask, attrib);
}

ObMenuFrame* menu_frame_new(ObMenu *menu, ObClient *client)
{
    ObMenuFrame *self;
    XSetWindowAttributes attr;

    self = g_new0(ObMenuFrame, 1);
    self->type = Window_Menu;
    self->menu = menu;
    self->selected = nil;
    self->show_title = TRUE;
    self->client = client;

    attr.event_mask = FRAME_EVENTMASK;
    self->window = createWindow(RootWindow(ob_display, ob_screen),
                                   CWEventMask, &attr);
    attr.event_mask = TITLE_EVENTMASK;
    self->title = createWindow(self->window, CWEventMask, &attr);
    self->items = createWindow(self->window, 0, NULL);

    XMapWindow(ob_display, self->items);

    self->a_title = RrAppearanceCopy(ob_rr_theme->a_menu_title);
    self->a_items = RrAppearanceCopy(ob_rr_theme->a_menu);

    [[AZStacking stacking] addWindow: MENU_AS_WINDOW(self)];

    return self;
}

void menu_frame_free(ObMenuFrame *self)
{
    if (self) {
        while (self->entries) {
	    DESTROY(self->entries->data);
            self->entries = g_list_delete_link(self->entries, self->entries);
        }

        [[AZStacking stacking] removeWindow: MENU_AS_WINDOW(self)];

        XDestroyWindow(ob_display, self->items);
        XDestroyWindow(ob_display, self->title);
        XDestroyWindow(ob_display, self->window);

        RrAppearanceFree(self->a_items);
        RrAppearanceFree(self->a_title);

        g_free(self);
    }
}

void menu_frame_move(ObMenuFrame *self, gint x, gint y)
{
    RECT_SET_POINT(self->area, x, y);
    XMoveWindow(ob_display, self->window, self->area.x, self->area.y);
}

void menu_frame_move_on_screen(ObMenuFrame *self)
{
    Rect *a = NULL;
    guint i;
    gint dx = 0, dy = 0;
    gint pos, half;

    a = [[AZScreen defaultScreen] physicalAreaOfMonitor: self->monitor];

    half = g_list_length(self->entries) / 2;
    pos = g_list_index(self->entries, self->selected);

    /* if in the bottom half then check this shit first, will keep the bottom
       edge of the menu visible */
    if (pos > half) {
        dx = MAX(dx, a->x - self->area.x);
        dy = MAX(dy, a->y - self->area.y);
    }
    dx = MIN(dx, (a->x + a->width) - (self->area.x + self->area.width));
    dy = MIN(dy, (a->y + a->height) - (self->area.y + self->area.height));
    /* if in the top half then check this shit last, will keep the top
       edge of the menu visible */
    if (pos <= half) {
        dx = MAX(dx, a->x - self->area.x);
        dy = MAX(dy, a->y - self->area.y);
    }

    if (dx || dy) {
        ObMenuFrame *f;

        /* move the current menu frame to fit, but dont touch parents yet */
        menu_frame_move(self, self->area.x + dx, self->area.y + dy);
        if (!config_menu_xorstyle)
            dy = 0; /* if we want to be like xor, move parents in y- *
                     * and x-direction, otherwise just in x-dir      */
        for (f = self->parent; f; f = f->parent)
            menu_frame_move(f, f->area.x + dx, f->area.y + dy);
        for (f = self->child; f; f = f->child)
            menu_frame_move(f, f->area.x + dx, f->area.y + dy);
        if (config_menu_warppointer)
            XWarpPointer(ob_display, None, None, 0, 0, 0, 0, dx, dy);
    }
}

static void menu_frame_render(ObMenuFrame *self)
{
    gint w = 0, h = 0;
    gint allitems_h = 0;
    gint tw, th; /* temps */
    GList *it;
    gboolean has_icon = FALSE;
    ObMenu *sub;

    XSetWindowBorderWidth(ob_display, self->window, ob_rr_theme->bwidth);
    XSetWindowBorder(ob_display, self->window,
                     RrColorPixel(ob_rr_theme->b_color));

    if (!self->parent && self->show_title) {
        XMoveWindow(ob_display, self->title, 
                    -ob_rr_theme->bwidth, h - ob_rr_theme->bwidth);

        self->a_title->texture[0].data.text.string = self->menu->title;
        RrMinsize(self->a_title, &tw, &th);
        tw = MIN(tw, MAX_MENU_WIDTH) + ob_rr_theme->padding * 2;
        w = MAX(w, tw);

        th = ob_rr_theme->menu_title_height;
        h += (self->title_h = th + ob_rr_theme->bwidth);

        XSetWindowBorderWidth(ob_display, self->title, ob_rr_theme->bwidth);
        XSetWindowBorder(ob_display, self->title,
                         RrColorPixel(ob_rr_theme->b_color));
    }

    XMoveWindow(ob_display, self->items, 0, h);

    STRUT_SET(self->item_margin, 0, 0, 0, 0);

    if (self->entries) {
        AZMenuEntryFrame *e = self->entries->data;
        gint l, t, r, b;

        [e a_text_normal]->texture[0].data.text.string = "";
        RrMinsize([e a_text_normal], &tw, &th);
        tw += 2*PADDING;
        th += 2*PADDING;
        self->item_h = th;

        RrMargins([e a_normal], &l, &t, &r, &b);
        STRUT_SET(self->item_margin,
                  MAX(self->item_margin.left, l),
                  MAX(self->item_margin.top, t),
                  MAX(self->item_margin.right, r),
                  MAX(self->item_margin.bottom, b));
        RrMargins([e a_selected], &l, &t, &r, &b);
        STRUT_SET(self->item_margin,
                  MAX(self->item_margin.left, l),
                  MAX(self->item_margin.top, t),
                  MAX(self->item_margin.right, r),
                  MAX(self->item_margin.bottom, b));
        RrMargins([e a_disabled], &l, &t, &r, &b);
        STRUT_SET(self->item_margin,
                  MAX(self->item_margin.left, l),
                  MAX(self->item_margin.top, t),
                  MAX(self->item_margin.right, r),
                  MAX(self->item_margin.bottom, b));
    } else
        self->item_h = 0;

    for (it = self->entries; it; it = g_list_next(it)) {
        RrAppearance *text_a;
        AZMenuEntryFrame *e = it->data;

	Rect _area = [e area];
        RECT_SET_POINT(_area, 0, allitems_h);
	[e set_area: _area];
        XMoveWindow(ob_display, [e window], 0, [e area].y);

        text_a = (([e entry]->type == OB_MENU_ENTRY_TYPE_NORMAL &&
                   ![e entry]->data.normal.enabled) ?
                  [e a_text_disabled] :
                  (e == self->selected ?
                   [e a_text_selected] :
                   [e a_text_normal]));
        switch ([e entry]->type) {
        case OB_MENU_ENTRY_TYPE_NORMAL:
            text_a->texture[0].data.text.string = [e entry]->data.normal.label;
            RrMinsize(text_a, &tw, &th);
            tw = MIN(tw, MAX_MENU_WIDTH);

            if ([e entry]->data.normal.icon_data ||
                [e entry]->data.normal.mask)
                has_icon = TRUE;
            break;
        case OB_MENU_ENTRY_TYPE_SUBMENU:
            sub = [e entry]->data.submenu.submenu;
            text_a->texture[0].data.text.string = sub ? sub->title : "";
            RrMinsize(text_a, &tw, &th);
            tw = MIN(tw, MAX_MENU_WIDTH);

            if ([e entry]->data.normal.icon_data ||
                [e entry]->data.normal.mask)
                has_icon = TRUE;

            tw += self->item_h - PADDING;
            break;
        case OB_MENU_ENTRY_TYPE_SEPARATOR:
            tw = 0;
            th = SEPARATOR_HEIGHT;
            break;
        }
        tw += 2*PADDING;
        th += 2*PADDING;
        w = MAX(w, tw);
        h += th;
        allitems_h += th;
    }

    self->text_x = PADDING;
    self->text_w = w;

    if (self->entries) {
        if (has_icon) {
            w += self->item_h + PADDING;
            self->text_x += self->item_h + PADDING;
        }
    }

    if (!w) w = 10;
    if (!allitems_h) {
        allitems_h = 3;
        h += 3;
    }

    XResizeWindow(ob_display, self->window, w, h);
    XResizeWindow(ob_display, self->items, w, allitems_h);

    self->inner_w = w;

    if (!self->parent && self->show_title) {
        XResizeWindow(ob_display, self->title,
                      w, self->title_h - ob_rr_theme->bwidth);
        RrPaint(self->a_title, self->title,
                w, self->title_h - ob_rr_theme->bwidth);
        XMapWindow(ob_display, self->title);
    } else
        XUnmapWindow(ob_display, self->title);

    RrPaint(self->a_items, self->items, w, allitems_h);

    for (it = self->entries; it; it = g_list_next(it))
	[((AZMenuEntryFrame*)(it->data)) render];

    w += ob_rr_theme->bwidth * 2;
    h += ob_rr_theme->bwidth * 2;

    RECT_SET_SIZE(self->area, w, h);

    XFlush(ob_display);
}

static void menu_frame_update(ObMenuFrame *self)
{
    GList *mit, *fit;

    menu_pipe_execute(self->menu);
    menu_find_submenus(self->menu);

    self->selected = NULL;

    for (mit = self->menu->entries, fit = self->entries; mit && fit;
         mit = g_list_next(mit), fit = g_list_next(fit))
    {
        AZMenuEntryFrame *f = fit->data;
        [f set_entry: mit->data];
    }

    while (mit) {
        AZMenuEntryFrame *e = [[AZMenuEntryFrame alloc] initWithMenuEntry: mit->data menuFrame: self];
        self->entries = g_list_append(self->entries, e);
        mit = g_list_next(mit);
    }
    
    while (fit) {
        GList *n = g_list_next(fit);
	DESTROY(fit->data);
        self->entries = g_list_delete_link(self->entries, fit);
        fit = n;
    }

    menu_frame_render(self);
}

gboolean menu_frame_show(ObMenuFrame *self, ObMenuFrame *parent)
{
    GList *it;

    if (g_list_find(menu_frame_visible, self))
        return TRUE;

    if (menu_frame_visible == NULL) {
        /* no menus shown yet */
        if (!grab_pointer(TRUE, OB_CURSOR_NONE))
            return FALSE;
        if (!grab_keyboard(TRUE)) {
            grab_pointer(FALSE, OB_CURSOR_NONE);
            return FALSE;
        }
    }

    if (parent) {
        self->monitor = parent->monitor;
        if (parent->child)
            menu_frame_hide(parent->child);
        parent->child = self;
    }
    self->parent = parent;

    /* determine if the underlying menu is already visible */
    for (it = menu_frame_visible; it; it = g_list_next(it)) {
        ObMenuFrame *f = it->data;
        if (f->menu == self->menu)
            break;
    }
    if (!it) {
        if (self->menu->update_func)
            self->menu->update_func(self, self->menu->data);
    }

    menu_frame_update(self);

    menu_frame_visible = g_list_prepend(menu_frame_visible, self);

    menu_frame_move_on_screen(self);

    XMapWindow(ob_display, self->window);

    return TRUE;
}

void menu_frame_hide(ObMenuFrame *self)
{
    GList *it = g_list_find(menu_frame_visible, self);

    if (!it)
        return;

    if (self->child)
        menu_frame_hide(self->child);

    if (self->parent)
        self->parent->child = NULL;
    self->parent = NULL;

    menu_frame_visible = g_list_delete_link(menu_frame_visible, it);

    if (menu_frame_visible == NULL) {
        /* last menu shown */
        grab_pointer(FALSE, OB_CURSOR_NONE);
        grab_keyboard(FALSE);
    }

    XUnmapWindow(ob_display, self->window);

    menu_frame_free(self);
}

void menu_frame_hide_all()
{
    GList *it = g_list_last(menu_frame_visible);
    if (it) 
        menu_frame_hide(it->data);
}

void menu_frame_hide_all_client(ObClient *client)
{
    GList *it = g_list_last(menu_frame_visible);
    if (it) {
        ObMenuFrame *f = it->data;
        if (f->client == client)
            menu_frame_hide(f);
    }
}


ObMenuFrame* menu_frame_under(gint x, gint y)
{
    ObMenuFrame *ret = NULL;
    GList *it;

    for (it = menu_frame_visible; it; it = g_list_next(it)) {
        ObMenuFrame *f = it->data;

        if (RECT_CONTAINS(f->area, x, y)) {
            ret = f;
            break;
        }
    }
    return ret;
}

void menu_frame_select(ObMenuFrame *self, AZMenuEntryFrame *entry)
{
    AZMenuEntryFrame *old = self->selected;
    ObMenuFrame *oldchild = self->child;

    if (entry && [entry entry]->type == OB_MENU_ENTRY_TYPE_SEPARATOR)
        entry = old;

    if (old == entry) return;

    self->selected = entry;

    if (old)
	[old render];
    if (oldchild)
        menu_frame_hide(oldchild);

    if (self->selected) {
	[self->selected render];

        if ([self->selected entry]->type == OB_MENU_ENTRY_TYPE_SUBMENU)
	    [self->selected showSubmenu];
    }
}

void menu_frame_select_previous(ObMenuFrame *self)
{
    GList *it = NULL, *start;

    if (self->entries) {
        start = it = g_list_find(self->entries, self->selected);
        while (TRUE) {
            AZMenuEntryFrame *e;

            it = it ? g_list_previous(it) : g_list_last(self->entries);
            if (it == start)
                break;

            if (it) {
                e = ((AZMenuEntryFrame*)(it->data));
                if ([e entry]->type == OB_MENU_ENTRY_TYPE_SUBMENU)
                    break;
                if ([e entry]->type == OB_MENU_ENTRY_TYPE_NORMAL &&
                    [e entry]->data.normal.enabled)
                    break;
            }
        }
    }
    menu_frame_select(self, it ? it->data : NULL);
}

void menu_frame_select_next(ObMenuFrame *self)
{
    GList *it = NULL, *start;

    if (self->entries) {
        start = it = g_list_find(self->entries, self->selected);
        while (TRUE) {
            AZMenuEntryFrame *e;

            it = it ? g_list_next(it) : self->entries;
            if (it == start)
                break;

            if (it) {
                e = ((AZMenuEntryFrame *)(it->data));
                if ([e entry]->type == OB_MENU_ENTRY_TYPE_SUBMENU)
                    break;
                if ([e entry]->type == OB_MENU_ENTRY_TYPE_NORMAL &&
                    [e entry]->data.normal.enabled)
                    break;
            }
        }
    }
    menu_frame_select(self, it ? it->data : NULL);
}
