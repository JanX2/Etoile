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
#import "AZScreen.h"
#import "menu.h"
#import "config.h"
#import "openbox.h"
#import "render/theme.h"

GList *menu_frame_visible;

#define PADDING 2
#define SEPARATOR_HEIGHT 3
#define MAX_MENU_WIDTH 400

#define FRAME_EVENTMASK (ButtonPressMask |ButtonMotionMask | EnterWindowMask |\
                         LeaveWindowMask)
#define TITLE_EVENTMASK (ButtonPressMask | ButtonMotionMask)

#define ENTRY_EVENTMASK (EnterWindowMask | LeaveWindowMask | \
                         ButtonPressMask | ButtonReleaseMask)

static Window createWindow(Window parent, unsigned long mask,
                           XSetWindowAttributes *attrib)
{
    return XCreateWindow(ob_display, parent, 0, 0, 1, 1, 0,
                         RrDepth(ob_rr_inst), InputOutput,
                         RrVisual(ob_rr_inst), mask, attrib);
}

@implementation AZMenuEntryFrame

- (id) initWithMenuEntry: (ObMenuEntry *) _entry 
               menuFrame: (AZMenuFrame *) _frame
{
  self = [super init];

  XSetWindowAttributes attr;

  entry = _entry;
  frame = _frame;

  attr.event_mask = ENTRY_EVENTMASK;
  window = createWindow([frame items], CWEventMask, &attr);
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
    int th; /* temp */
    ObMenu *sub;

    item_a = ((entry->type == OB_MENU_ENTRY_TYPE_NORMAL &&
               !entry->data.normal.enabled) ?
              a_disabled : (self == [frame selected] ?  a_selected : a_normal));
    switch (entry->type) {
    case OB_MENU_ENTRY_TYPE_NORMAL:
    case OB_MENU_ENTRY_TYPE_SUBMENU:
        th = [frame item_h];
        break;
    case OB_MENU_ENTRY_TYPE_SEPARATOR:
        th = SEPARATOR_HEIGHT + 2*PADDING;
        break;
    }
    RECT_SET_SIZE(area, [frame inner_w], th);
    XResizeWindow(ob_display, window, area.width, area.height);
    item_a->surface.parent = [frame a_items];
    item_a->surface.parentx = area.x;
    item_a->surface.parenty = area.y;
    RrPaint(item_a, window, area.width, area.height);

    text_a = ((entry->type == OB_MENU_ENTRY_TYPE_NORMAL &&
               !entry->data.normal.enabled) ?
              a_text_disabled :
              (self == [frame selected] ?  a_text_selected : a_text_normal));
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
                          [frame text_x], PADDING,
                          [frame text_w], [frame item_h] - 2*PADDING);
        text_a->surface.parent = item_a;
        text_a->surface.parentx = [frame text_x];
        text_a->surface.parenty = PADDING;
        RrPaint(text_a, text, [frame text_w], [frame item_h] - 2*PADDING);
        break;
    case OB_MENU_ENTRY_TYPE_SUBMENU:
        XMoveResizeWindow(ob_display, text,
                          [frame text_x], PADDING,
                          [frame text_w] - [frame item_h],
                          [frame item_h] - 2*PADDING);
        text_a->surface.parent = item_a;
        text_a->surface.parentx = [frame text_x];
        text_a->surface.parenty = PADDING;
        RrPaint(text_a, text, [frame text_w] - [frame item_h],
                [frame item_h] - 2*PADDING);
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
                          PADDING, [frame item_margin].top,
                          [frame item_h] - [frame item_margin].top
                          - [frame item_margin].bottom,
                          [frame item_h] - [frame item_margin].top
                          - [frame item_margin].bottom);
        a_icon->texture[0].data.rgba.width =
            entry->data.normal.icon_width;
        a_icon->texture[0].data.rgba.height =
            entry->data.normal.icon_height;
        a_icon->texture[0].data.rgba.data =
            entry->data.normal.icon_data;
        a_icon->surface.parent = item_a;
        a_icon->surface.parentx = PADDING;
        a_icon->surface.parenty = [frame item_margin].top;
        RrPaint(a_icon, icon,
                [frame item_h] - [frame item_margin].top
                - [frame item_margin].bottom,
                [frame item_h] - [frame item_margin].top
                - [frame item_margin].bottom);
        XMapWindow(ob_display, icon);
    } else if (entry->type != OB_MENU_ENTRY_TYPE_SEPARATOR &&
               entry->data.normal.mask)
    {
        RrColor *c;

        XMoveResizeWindow(ob_display, icon,
                          PADDING, [frame item_margin].top,
                          [frame item_h] - [frame item_margin].top
                          - [frame item_margin].bottom,
                          [frame item_h] - [frame item_margin].top
                          - [frame item_margin].bottom);
        a_mask->texture[0].data.mask.mask = entry->data.normal.mask;

        c = ((entry->type == OB_MENU_ENTRY_TYPE_NORMAL &&
              !entry->data.normal.enabled) ?
             entry->data.normal.mask_disabled_color :
             (self == [frame selected] ?
              entry->data.normal.mask_selected_color :
              entry->data.normal.mask_normal_color));
        a_mask->texture[0].data.mask.color = c;

        a_mask->surface.parent = item_a;
        a_mask->surface.parentx = PADDING;
        a_mask->surface.parenty = [frame item_margin].top;
        RrPaint(a_mask, icon,
                [frame item_h] - [frame item_margin].top
                - [frame item_margin].bottom,
                [frame item_h] - [frame item_margin].top
                - [frame item_margin].bottom);
        XMapWindow(ob_display, icon);
    } else
        XUnmapWindow(ob_display, icon);

    if (entry->type == OB_MENU_ENTRY_TYPE_SUBMENU) {
        RrAppearance *bullet_a;
        XMoveResizeWindow(ob_display, bullet,
                          [frame text_x] + [frame text_w]
                          - [frame item_h] + PADDING, PADDING,
                          [frame item_h] - 2*PADDING,
                          [frame item_h] - 2*PADDING);
        bullet_a = (self == [frame selected] ?
                    a_bullet_selected : a_bullet_normal);
        bullet_a->surface.parent = item_a;
        bullet_a->surface.parentx =
            [frame text_x] + [frame text_w] - [frame item_h] + PADDING;
        bullet_a->surface.parenty = PADDING;
        RrPaint(bullet_a, bullet,
                [frame item_h] - 2*PADDING,
                [frame item_h] - 2*PADDING);
        XMapWindow(ob_display, bullet);
    } else
        XUnmapWindow(ob_display, bullet);

    XFlush(ob_display);
}

- (void) showSubmenu
{
    AZMenuFrame *f;

    if (!entry->data.submenu.submenu) return;

    f = [[AZMenuFrame alloc] initWithMenu: entry->data.submenu.submenu
	                           client: [frame client]];
    [f moveToX: [frame area].x + [frame area].width
                    - ob_rr_theme->menu_overlap - ob_rr_theme->bwidth
	     y: [frame area].y + [frame title_h] +
                    area.y + ob_rr_theme->menu_overlap];
    [f showWithParent: frame];
}

- (void) execute: (unsigned int) state
{
    if (entry->type == OB_MENU_ENTRY_TYPE_NORMAL &&
        entry->data.normal.enabled)
    {
        /* grab all this shizzle, cuz when the menu gets hidden, 'self'
           gets freed */
        ObMenuExecuteFunc func = [frame menu]->execute_func;
        gpointer data = [frame menu]->data;
        GSList *acts = entry->data.normal.actions;
        AZClient *client = [frame client];

        /* release grabs before executing the shit */
        if (!(state & ControlMask))
	    AZMenuFrameHideAll();

        if (func)
            func(entry, state, data);
        else
            action_run(acts, [client obClient], state);
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
    AZMenuFrame *frame;
    AZMenuEntryFrame *ret = nil;
    GList *it;

    if ((frame = AZMenuFrameUnder(x, y))) {
        x -= ob_rr_theme->bwidth + [frame area].x;
        y -= [frame title_h] + ob_rr_theme->bwidth + [frame area].y;

        for (it = [frame entries]; it; it = g_list_next(it)) {
            AZMenuEntryFrame *e = it->data;

            if (RECT_CONTAINS([e area], x, y)) {
                ret = e;            
                break;
            }
        }
    }
    return ret;
}

@implementation AZMenuFrame

- (id) initWithMenu: (struct _ObMenu *) _menu 
             client: (AZClient *) _client
{
    self = [super init];
    XSetWindowAttributes attr;

    menu = _menu;
    selected = nil;
    show_title = YES;
    client = _client;

    attr.event_mask = FRAME_EVENTMASK;
    window = createWindow(RootWindow(ob_display, ob_screen), CWEventMask, &attr);
    attr.event_mask = TITLE_EVENTMASK;
    title = createWindow(window, CWEventMask, &attr);
    items = createWindow(window, 0, NULL);

    XMapWindow(ob_display, items);

    a_title = RrAppearanceCopy(ob_rr_theme->a_menu_title);
    a_items = RrAppearanceCopy(ob_rr_theme->a_menu);

    [[AZStacking stacking] addWindow: self];

    return self;
}

- (void) dealloc
{
        while (entries) {
	    DESTROY(entries->data);
            entries = g_list_delete_link(entries, entries);
        }

        [[AZStacking stacking] removeWindow: self];

        XDestroyWindow(ob_display, items);
        XDestroyWindow(ob_display, title);
        XDestroyWindow(ob_display, window);

        RrAppearanceFree(a_items);
        RrAppearanceFree(a_title);

	[super dealloc];
}

- (void) moveToX: (int) x y: (int) y
{
    RECT_SET_POINT(area, x, y);
    XMoveWindow(ob_display, window, area.x, area.y);
}

- (void) moveOnScreen
{
    Rect *a = NULL;
    unsigned int i;
    int dx = 0, dy = 0;
    int pos, half;

    a = [[AZScreen defaultScreen] physicalAreaOfMonitor: monitor];

    half = g_list_length(entries) / 2;
    pos = g_list_index(entries, selected);

    /* if in the bottom half then check this shit first, will keep the bottom
       edge of the menu visible */
    if (pos > half) {
        dx = MAX(dx, a->x - area.x);
        dy = MAX(dy, a->y - area.y);
    }
    dx = MIN(dx, (a->x + a->width) - (area.x + area.width));
    dy = MIN(dy, (a->y + a->height) - (area.y + area.height));
    /* if in the top half then check this shit last, will keep the top
       edge of the menu visible */
    if (pos <= half) {
        dx = MAX(dx, a->x - area.x);
        dy = MAX(dy, a->y - area.y);
    }

    if (dx || dy) {
        AZMenuFrame *f;

        /* move the current menu frame to fit, but dont touch parents yet */
	[self moveToX: area.x + dx y: area.y + dy];
        if (!config_menu_xorstyle)
            dy = 0; /* if we want to be like xor, move parents in y- *
                     * and x-direction, otherwise just in x-dir      */
        for (f = parent; f; f = [f parent])
	    [f moveToX: [f area].x + dx y: [f area].y + dy];
        for (f = child; f; f = [f child])
	    [f moveToX: [f area].x + dx y: [f area].y + dy];
        if (config_menu_warppointer)
            XWarpPointer(ob_display, None, None, 0, 0, 0, 0, dx, dy);
    }
}

- (void) render
{
    int w = 0, h = 0;
    int allitems_h = 0;
    int tw, th; /* temps */
    GList *it;
    BOOL has_icon = NO;
    ObMenu *sub;

    XSetWindowBorderWidth(ob_display, window, ob_rr_theme->bwidth);
    XSetWindowBorder(ob_display, window, RrColorPixel(ob_rr_theme->b_color));

    if (!parent && show_title) {
        XMoveWindow(ob_display, title, 
                    -ob_rr_theme->bwidth, h - ob_rr_theme->bwidth);

        a_title->texture[0].data.text.string = menu->title;
        RrMinsize(a_title, &tw, &th);
        tw = MIN(tw, MAX_MENU_WIDTH) + ob_rr_theme->padding * 2;
        w = MAX(w, tw);

        th = ob_rr_theme->menu_title_height;
        h += (title_h = th + ob_rr_theme->bwidth);

        XSetWindowBorderWidth(ob_display, title, ob_rr_theme->bwidth);
        XSetWindowBorder(ob_display, title, RrColorPixel(ob_rr_theme->b_color));
    }

    XMoveWindow(ob_display, items, 0, h);

    STRUT_SET(item_margin, 0, 0, 0, 0);

    if (entries) {
        AZMenuEntryFrame *e = entries->data;
        int l, t, r, b;

        [e a_text_normal]->texture[0].data.text.string = "";
        RrMinsize([e a_text_normal], &tw, &th);
        tw += 2*PADDING;
        th += 2*PADDING;
        item_h = th;

        RrMargins([e a_normal], &l, &t, &r, &b);
        STRUT_SET(item_margin,
                  MAX(item_margin.left, l),
                  MAX(item_margin.top, t),
                  MAX(item_margin.right, r),
                  MAX(item_margin.bottom, b));
        RrMargins([e a_selected], &l, &t, &r, &b);
        STRUT_SET(item_margin,
                  MAX(item_margin.left, l),
                  MAX(item_margin.top, t),
                  MAX(item_margin.right, r),
                  MAX(item_margin.bottom, b));
        RrMargins([e a_disabled], &l, &t, &r, &b);
        STRUT_SET(item_margin,
                  MAX(item_margin.left, l),
                  MAX(item_margin.top, t),
                  MAX(item_margin.right, r),
                  MAX(item_margin.bottom, b));
    } else
        item_h = 0;

    for (it = entries; it; it = g_list_next(it)) {
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
                has_icon = YES;
            break;
        case OB_MENU_ENTRY_TYPE_SUBMENU:
            sub = [e entry]->data.submenu.submenu;
            text_a->texture[0].data.text.string = sub ? sub->title : "";
            RrMinsize(text_a, &tw, &th);
            tw = MIN(tw, MAX_MENU_WIDTH);

            if ([e entry]->data.normal.icon_data ||
                [e entry]->data.normal.mask)
                has_icon = YES;

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

    text_x = PADDING;
    text_w = w;

    if (entries) {
        if (has_icon) {
            w += item_h + PADDING;
            text_x += item_h + PADDING;
        }
    }

    if (!w) w = 10;
    if (!allitems_h) {
        allitems_h = 3;
        h += 3;
    }

    XResizeWindow(ob_display, window, w, h);
    XResizeWindow(ob_display, items, w, allitems_h);

    inner_w = w;

    if (!parent && show_title) {
        XResizeWindow(ob_display, title, w, title_h - ob_rr_theme->bwidth);
        RrPaint(a_title, title, w, title_h - ob_rr_theme->bwidth);
        XMapWindow(ob_display, title);
    } else
        XUnmapWindow(ob_display, title);

    RrPaint(a_items, items, w, allitems_h);

    for (it = entries; it; it = g_list_next(it))
	[((AZMenuEntryFrame*)(it->data)) render];

    w += ob_rr_theme->bwidth * 2;
    h += ob_rr_theme->bwidth * 2;

    RECT_SET_SIZE(area, w, h);

    XFlush(ob_display);
}

- (void) update
{
    GList *mit, *fit;

    menu_pipe_execute(menu);
    menu_find_submenus(menu);

    selected = nil;

    for (mit = menu->entries, fit = entries; mit && fit;
         mit = g_list_next(mit), fit = g_list_next(fit))
    {
        AZMenuEntryFrame *f = fit->data;
        [f set_entry: mit->data];
    }

    while (mit) {
        AZMenuEntryFrame *e = [[AZMenuEntryFrame alloc] initWithMenuEntry: mit->data menuFrame: self];
        entries = g_list_append(entries, e);
        mit = g_list_next(mit);
    }
    
    while (fit) {
        GList *n = g_list_next(fit);
	DESTROY(fit->data);
        entries = g_list_delete_link(entries, fit);
        fit = n;
    }

    [self render];
}

- (BOOL) showWithParent: (AZMenuFrame *) p
{
    GList *it;

    if (g_list_find(menu_frame_visible, self))
        return YES;

    if (menu_frame_visible == NULL) {
        /* no menus shown yet */
        if (!grab_pointer(YES, OB_CURSOR_NONE))
            return NO;
        if (!grab_keyboard(YES)) {
            grab_pointer(NO, OB_CURSOR_NONE);
            return NO;
        }
    }

    if (p) {
        monitor = [p monitor];
        if ([p child])
	    [[p child] hide];
	[p set_child: self];
    }

    parent = p;

    /* determine if the underlying menu is already visible */
    for (it = menu_frame_visible; it; it = g_list_next(it)) {
        AZMenuFrame *f = it->data;
        if ([f menu] == menu)
            break;
    }
    if (!it) {
        if (menu->update_func)
            menu->update_func(self, menu->data);
    }

    [self update];

    menu_frame_visible = g_list_prepend(menu_frame_visible, self);

    [self moveOnScreen];

    XMapWindow(ob_display, window);

    return YES;
}

- (void) hide
{
    GList *it = g_list_find(menu_frame_visible, self);

    if (!it)
        return;

    if (child)
	[child hide];

    if (parent)
        [parent set_child: nil];
    parent = nil;

    menu_frame_visible = g_list_delete_link(menu_frame_visible, it);

    if (menu_frame_visible == NULL) {
        /* last menu shown */
        grab_pointer(NO, OB_CURSOR_NONE);
        grab_keyboard(NO);
    }

    XUnmapWindow(ob_display, window);

    // FIXME
    RELEASE(self);
}

- (void) selectMenuEntryFrame: (AZMenuEntryFrame *) entry
{
    AZMenuEntryFrame *old = selected;
    AZMenuFrame *oldchild = child;

    if (entry && [entry entry]->type == OB_MENU_ENTRY_TYPE_SEPARATOR)
        entry = old;

    if (old == entry) return;

    selected = entry;

    if (old)
	[old render];
    if (oldchild)
	[oldchild hide];

    if (selected) {
	[selected render];

        if ([selected entry]->type == OB_MENU_ENTRY_TYPE_SUBMENU)
	    [selected showSubmenu];
    }
}

- (void) selectPrevious
{
    GList *it = NULL, *start;

    if (entries) {
        start = it = g_list_find(entries, selected);
        while (YES) {
            AZMenuEntryFrame *e;

            it = it ? g_list_previous(it) : g_list_last(entries);
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
    [self selectMenuEntryFrame: (it ? it->data : nil)];
}

- (void) selectNext
{
    GList *it = NULL, *start;

    if (entries) {
        start = it = g_list_find(entries, selected);
        while (YES) {
            AZMenuEntryFrame *e;

            it = it ? g_list_next(it) : entries;
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
    [self selectMenuEntryFrame: (it ? it->data : nil)];
}

/* Accessories */
- (Rect) area { return area; }
- (AZMenuFrame *) parent { return parent; }
- (AZMenuFrame *) child { return child; }
- (AZMenuEntryFrame *) selected { return selected; }
- (int) monitor { return monitor; }
- (struct _ObMenu *) menu { return menu; }
- (AZClient *) client { return client; }
- (void) set_child: (AZMenuFrame *) c { child = c; }
- (void) set_parent: (AZMenuFrame *) p { parent = p; }
- (void) set_monitor: (int) m { monitor = m; }

- (Window) items { return items; }
- (Window) window { return window; }
- (int) item_h { return item_h; }
- (int) title_h { return title_h; }
- (int) inner_w { return inner_w; }
- (RrAppearance *) a_items { return a_items; }
- (int) text_x { return text_x; }
- (int) text_w { return text_w; }
- (Strut) item_margin { return item_margin; }
- (GList *) entries { return entries; }
- (void) set_show_title: (BOOL) b { show_title = b; }

- (Window_InternalType) windowType { return Window_Menu; }
- (int) windowLayer { return OB_STACKING_LAYER_INTERNAL; }
- (Window) windowTop { return window; }

@end

void AZMenuFrameHideAll()
{
    GList *it = g_list_last(menu_frame_visible);
    if (it) 
	[((AZMenuFrame *)(it->data)) hide];
}

void AZMenuFrameHideAllClient (AZClient *_client)
{
    GList *it = g_list_last(menu_frame_visible);
    if (it) {
        AZMenuFrame *f = it->data;
        if ([f client] == _client)
	    [f hide];
    }
}

AZMenuFrame *AZMenuFrameUnder(int x, int y)
{
    AZMenuFrame *ret = nil;
    GList *it;

    for (it = menu_frame_visible; it; it = g_list_next(it)) {
        AZMenuFrame *f = it->data;

        if (RECT_CONTAINS([f area], x, y)) {
            ret = f;
            break;
        }
    }
    return ret;
}

