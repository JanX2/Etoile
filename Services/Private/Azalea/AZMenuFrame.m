/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZMenuFrame.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

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
#import "AZMenu.h"
#import "config.h"
#import "openbox.h"
#import "render/theme.h"
#import "action.h"

static NSMutableArray *menu_frame_visible = nil;

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

- (id) initWithMenuEntry: (AZMenuEntry *) _entry 
               menuFrame: (AZMenuFrame *) _frame
{
  self = [super init];

  XSetWindowAttributes attr;

  entry = _entry;
  frame = _frame;

  attr.event_mask = ENTRY_EVENTMASK;
  window = createWindow([frame items], CWEventMask, &attr);
  text = createWindow(window, 0, NULL);
  if ([entry type] != OB_MENU_ENTRY_TYPE_SEPARATOR) {
      icon = createWindow(window, 0, NULL);
      bullet = createWindow(window, 0, NULL);
  }

  XMapWindow(ob_display, window);
  XMapWindow(ob_display, text);

  a_normal = RrAppearanceCopy(ob_rr_theme->a_menu_normal);
  a_disabled = RrAppearanceCopy(ob_rr_theme->a_menu_disabled);
  a_selected = RrAppearanceCopy(ob_rr_theme->a_menu_selected);

  if ([entry type] == OB_MENU_ENTRY_TYPE_SEPARATOR) {
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
        if ([entry type] != OB_MENU_ENTRY_TYPE_SEPARATOR) {
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
    AZMenu *sub;

    item_a = (([entry type] == OB_MENU_ENTRY_TYPE_NORMAL &&
               ![(AZNormalMenuEntry *)entry enabled]) ?
              a_disabled : (self == [frame selected] ?  a_selected : a_normal));

    switch ([entry type]) {
    case OB_MENU_ENTRY_TYPE_NORMAL:
    case OB_MENU_ENTRY_TYPE_SUBMENU:
        th = [frame item_h];
        break;
    case OB_MENU_ENTRY_TYPE_SEPARATOR:
        th = SEPARATOR_HEIGHT + 2*PADDING;
        break;
    default: 
	NSLog(@"Internal Error: unknown type");
    }
    RECT_SET_SIZE(area, [frame inner_w], th);
    XResizeWindow(ob_display, window, area.width, area.height);
    item_a->surface.parent = [frame a_items];
    item_a->surface.parentx = area.x;
    item_a->surface.parenty = area.y;
    RrPaint(item_a, window, area.width, area.height);

    RECT_SET_SIZE(area, [frame inner_w], th);
    text_a = (([entry type] == OB_MENU_ENTRY_TYPE_NORMAL &&
               ![(AZNormalMenuEntry *)entry enabled]) ?
              a_text_disabled :
              (self == [frame selected] ?  a_text_selected : a_text_normal));
    switch ([entry type]) {
    case OB_MENU_ENTRY_TYPE_NORMAL:
        text_a->texture[0].data.text.string = (char*)[[(AZNormalMenuEntry *)entry label] cString];
        break;
    case OB_MENU_ENTRY_TYPE_SUBMENU:
        sub = [(AZSubmenuMenuEntry *)entry submenu];
        text_a->texture[0].data.text.string = sub ? (char*)[[sub title] cString]: "";
        break;
    case OB_MENU_ENTRY_TYPE_SEPARATOR:
        break;
    }

    switch ([entry type]) {
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

    if ([entry type] != OB_MENU_ENTRY_TYPE_SEPARATOR &&
        [(AZIconMenuEntry *)entry icon_data])
    {
        XMoveResizeWindow(ob_display, icon,
                          PADDING, [frame item_margin].top,
                          [frame item_h] - [frame item_margin].top
                          - [frame item_margin].bottom,
                          [frame item_h] - [frame item_margin].top
                          - [frame item_margin].bottom);
        a_icon->texture[0].data.rgba.width =
            [(AZIconMenuEntry *)entry icon_width];
        a_icon->texture[0].data.rgba.height =
            [(AZIconMenuEntry *)entry icon_height];
        a_icon->texture[0].data.rgba.data =
            [(AZIconMenuEntry *)entry icon_data];
        a_icon->surface.parent = item_a;
        a_icon->surface.parentx = PADDING;
        a_icon->surface.parenty = [frame item_margin].top;
        RrPaint(a_icon, icon,
                [frame item_h] - [frame item_margin].top
                - [frame item_margin].bottom,
                [frame item_h] - [frame item_margin].top
                - [frame item_margin].bottom);
        XMapWindow(ob_display, icon);
    } else if ([entry type] != OB_MENU_ENTRY_TYPE_SEPARATOR &&
               [(AZIconMenuEntry *)entry mask])
    {
        RrColor *c;

        XMoveResizeWindow(ob_display, icon,
                          PADDING, [frame item_margin].top,
                          [frame item_h] - [frame item_margin].top
                          - [frame item_margin].bottom,
                          [frame item_h] - [frame item_margin].top
                          - [frame item_margin].bottom);
        a_mask->texture[0].data.mask.mask = [(AZIconMenuEntry *)entry mask];

        c = (([entry type] == OB_MENU_ENTRY_TYPE_NORMAL &&
              ![(AZNormalMenuEntry *)entry enabled]) ?
             [(AZNormalMenuEntry *)entry mask_disabled_color] :
             (self == [frame selected] ?
              [(AZNormalMenuEntry *)entry mask_selected_color] :
              [(AZNormalMenuEntry *)entry mask_normal_color]));
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

    if ([entry type] == OB_MENU_ENTRY_TYPE_SUBMENU) {
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

    if (!(([entry type] == OB_MENU_ENTRY_TYPE_SUBMENU) && 
	    ([(AZSubmenuMenuEntry *)entry submenu] != NULL))) return;

    f = [[AZMenuFrame alloc] initWithMenu: [(AZSubmenuMenuEntry *)entry submenu]
	                           client: [frame client]];
    [f moveToX: [frame area].x + [frame area].width
                    - ob_rr_theme->menu_overlap - ob_rr_theme->bwidth
	     y: [frame area].y + [frame title_h] +
                    area.y + ob_rr_theme->menu_overlap];
    [f showWithParent: frame];
}

- (void) execute: (unsigned int) state
{
    if ([entry type] == OB_MENU_ENTRY_TYPE_NORMAL &&
        [(AZNormalMenuEntry *)entry enabled])
    {
        /* grab all this shizzle, cuz when the menu gets hidden, 'self'
           gets freed */
        NSArray *acts = [(AZNormalMenuEntry *)entry actions];
        AZClient *client = [frame client];

        /* release grabs before executing the shit */
        if (!(state & ControlMask))
	    AZMenuFrameHideAll();

	if ([[frame menu] execute: entry state: state] == NO) {
            action_run(acts, client, state);
	}
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
- (AZMenuEntry *) entry { return entry; }
- (void) set_entry: (AZMenuEntry *) e { entry = e; }

@end

AZMenuEntryFrame* AZMenuEntryFrameUnder(int x, int y)
{
    AZMenuFrame *frame;
    AZMenuEntryFrame *ret = nil;

    if ((frame = AZMenuFrameUnder(x, y))) {
        x -= ob_rr_theme->bwidth + [frame area].x;
        y -= [frame title_h] + ob_rr_theme->bwidth + [frame area].y;

	int i, count = [[frame entries] count];
	for (i = 0; i < count; i++) {
	    AZMenuEntryFrame *e = [[frame entries] objectAtIndex: i];

            if (RECT_CONTAINS([e area], x, y)) {
                ret = e;            
                break;
            }
        }
    }
    return ret;
}

@implementation AZMenuFrame

+ (NSMutableArray *) visibleFrames
{
  if (menu_frame_visible == nil)
  {
    menu_frame_visible = [[NSMutableArray alloc] init];
  }
  return menu_frame_visible;
}

- (id) initWithMenu: (AZMenu *) _menu 
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

    entries = [[NSMutableArray alloc] init];

    return self;
}

- (void) dealloc
{
	DESTROY(entries);

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

    half = [entries count] / 2;
    pos = [entries indexOfObject: selected];

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
    BOOL has_icon = NO;
    AZMenu *sub;

    XSetWindowBorderWidth(ob_display, window, ob_rr_theme->bwidth);
    XSetWindowBorder(ob_display, window, RrColorPixel(ob_rr_theme->b_color));

    if (!parent && show_title) {
        XMoveWindow(ob_display, title, 
                    -ob_rr_theme->bwidth, h - ob_rr_theme->bwidth);

        a_title->texture[0].data.text.string = (char*)[[menu title] cString];
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

    if ([entries count]) {
        AZMenuEntryFrame *e = [entries objectAtIndex: 0];
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

    int i, count = [entries count];
    for (i = 0; i < count; i++) {
        RrAppearance *text_a;
        AZMenuEntryFrame *e = [entries objectAtIndex: i];

	Rect _area = [e area];
        RECT_SET_POINT(_area, 0, allitems_h);
	[e set_area: _area];
        XMoveWindow(ob_display, [e window], 0, [e area].y);

        text_a = (([[e entry] type] == OB_MENU_ENTRY_TYPE_NORMAL &&
                   ![(AZNormalMenuEntry *)[e entry] enabled]) ?
                  [e a_text_disabled] :
                  (e == self->selected ?
                   [e a_text_selected] :
                   [e a_text_normal]));
        switch ([[e entry] type]) {
        case OB_MENU_ENTRY_TYPE_NORMAL:
            text_a->texture[0].data.text.string = (char*)[[(AZNormalMenuEntry *)[e entry] label] cString];
            RrMinsize(text_a, &tw, &th);
            tw = MIN(tw, MAX_MENU_WIDTH);

            if ([(AZIconMenuEntry *)[e entry] icon_data] ||
                [(AZIconMenuEntry *)[e entry] mask])
                has_icon = YES;
            break;
        case OB_MENU_ENTRY_TYPE_SUBMENU:
            sub = [(AZSubmenuMenuEntry *)[e entry] submenu];
            text_a->texture[0].data.text.string = sub ? (char*)[[sub title] cString]: "";
            RrMinsize(text_a, &tw, &th);
            tw = MIN(tw, MAX_MENU_WIDTH);

            if ([(AZIconMenuEntry *)[e entry] icon_data] ||
                [(AZIconMenuEntry *)[e entry] mask])
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

    if ([entries count]) {
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

    count = [entries count];
    for (i = 0; i < count; i++) {
	[(AZMenuEntryFrame*)[entries objectAtIndex: i] render];
    }

    w += ob_rr_theme->bwidth * 2;
    h += ob_rr_theme->bwidth * 2;

    RECT_SET_SIZE(area, w, h);

    XFlush(ob_display);
}

- (void) update
{
    int fit, fcount;
    int mit, mcount;

    [menu pipeExecute];
    [menu findSubmenus];

    selected = nil;

    fcount = [entries count];
    mcount = [[menu entries] count];
    for (mit = 0, fit = 0; mit < mcount, fit < fcount; mit++, fit++)
    {
        AZMenuEntryFrame *f = [entries objectAtIndex: fit];
        [f set_entry: [[menu entries] objectAtIndex: mit]];
    }

    for (; mit < mcount; mit++) {
        AZMenuEntryFrame *e = [[AZMenuEntryFrame alloc] initWithMenuEntry: [[menu entries] objectAtIndex: mit] menuFrame: self];
	[entries addObject: e];
	DESTROY(e);
    }
    
    for(; fit < fcount; fit++) {
      [entries removeObjectAtIndex: fit];
    }

    [self render];
}

- (BOOL) showWithParent: (AZMenuFrame *) p
{
    NSMutableArray *visibles = [AZMenuFrame visibleFrames];
    int i, count = [visibles count];

    if ([visibles containsObject: self])
        return YES;

    if (count == 0) {
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
    int found = NSNotFound;
    for (i = 0; i < count; i++) {
        AZMenuFrame *f = [visibles objectAtIndex: i];
        if ([f menu] == menu) {
	    found = i;
            break;
	}
    }
    if (found == NSNotFound) {
	[menu update: self];
    }

    [self update];

    [visibles insertObject: self atIndex: 0];

    [self moveOnScreen];

    XMapWindow(ob_display, window);

    return YES;
}

- (void) hide
{
    NSMutableArray *visibles = [AZMenuFrame visibleFrames];

    if ([visibles containsObject: self] == NO)
        return;

    if (child)
	[child hide];

    if (parent)
        [parent set_child: nil];
    parent = nil;

    [visibles removeObject: self];

    if ([visibles count] == 0) {
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

    if (entry && [[entry entry] type] == OB_MENU_ENTRY_TYPE_SEPARATOR)
        entry = old;

    if (old == entry) return;

    selected = entry;

    if (old)
	[old render];
    if (oldchild)
	[oldchild hide];

    if (selected) {
	[selected render];

        if ([[selected entry] type] == OB_MENU_ENTRY_TYPE_SUBMENU)
	    [selected showSubmenu];
    }
}

- (void) selectPrevious
{
    int start, it;

    if ([entries count]) {
	start = it = [entries indexOfObject: selected];
	if (start == NSNotFound) start = 0;
        while (YES) {
            AZMenuEntryFrame *e;

	    it = (it == NSNotFound) ? [entries count]-1 : it-1;
	    if (it < 0) it = [entries count]-1;
	    
            if (it == start)
                break;

            {
                e = (AZMenuEntryFrame*)[entries objectAtIndex: it];
                if ([[e entry] type] == OB_MENU_ENTRY_TYPE_SUBMENU)
                    break;
                if ([[e entry] type] == OB_MENU_ENTRY_TYPE_NORMAL &&
                    [(AZNormalMenuEntry *)[e entry] enabled])
                    break;
            }
        }
    }
    [self selectMenuEntryFrame: ((it == NSNotFound) ? nil : [entries objectAtIndex: it])];
}

- (void) selectNext
{
    int start, it;

    if (entries) {
	start = it = [entries indexOfObject: selected];
	if (start == NSNotFound) start = [entries count]-1;
        while (YES) {
            AZMenuEntryFrame *e;

	    it = (it == NSNotFound) ? 0 : it+1;
	    if (it >= [entries count]) it = 0;
            if (it == start)
                break;

            {
                e = (AZMenuEntryFrame *)[entries objectAtIndex: it];
                if ([[e entry] type] == OB_MENU_ENTRY_TYPE_SUBMENU)
                    break;
                if ([[e entry] type] == OB_MENU_ENTRY_TYPE_NORMAL &&
                    [(AZNormalMenuEntry *)[e entry] enabled])
                    break;
            }
        }
    }
    [self selectMenuEntryFrame: ((it == NSNotFound) ? nil : [entries objectAtIndex: it])];
}

/* Accessories */
- (Rect) area { return area; }
- (AZMenuFrame *) parent { return parent; }
- (AZMenuFrame *) child { return child; }
- (AZMenuEntryFrame *) selected { return selected; }
- (int) monitor { return monitor; }
- (AZMenu *) menu { return menu; }
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
- (NSArray *) entries { return entries; }
- (void) set_show_title: (BOOL) b { show_title = b; }

- (Window_InternalType) windowType { return Window_Menu; }
- (int) windowLayer { return OB_STACKING_LAYER_INTERNAL; }
- (Window) windowTop { return window; }

@end

void AZMenuFrameHideAll()
{
    AZMenuFrame *last = [[AZMenuFrame visibleFrames] lastObject];
    if (last) {
      [last hide];
    }
}

void AZMenuFrameHideAllClient (AZClient *_client)
{
    AZMenuFrame *f = [[AZMenuFrame visibleFrames] lastObject];
    if (f) {
      if ([f client] == _client)
        [f hide];
    }
}

AZMenuFrame *AZMenuFrameUnder(int x, int y)
{
    NSArray *visibles = [AZMenuFrame visibleFrames];
    int i, count = [visibles count];
    for (i = 0; i < count; i++) {
	AZMenuFrame *f = [visibles objectAtIndex: i];
	if (RECT_CONTAINS([f area], x, y)) {
	    return f;
	}
    }

    return nil;
}

