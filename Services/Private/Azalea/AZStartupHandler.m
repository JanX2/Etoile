// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   startupnotify.c for the Openbox window manager
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

#import "AZStartupHandler.h"

static AZStartupHandler *sharedInstance;

#ifndef USE_LIBSN

@implementation AZStartupHandler
- (void) processXEvent: (XEvent *) e {}
- (void) startup: (BOOL) reconfig {}
- (void) shutdown: (BOOL) reconfig {}
- (BOOL) applicationStarting { return NO; }
- (void) applicationStarted: (char *) wmclass {}
- (BOOL) getDesktop: (unsigned int *) desktop forIdentifier: (char *) iden { return NO; }

+ (AZStartupHandler *) defaultHandler
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[AZStartupHandler alloc] init];
  }
  return sharedInstance;
}

@end

#else

#import "openbox.h"
#import "AZMainLoop.h"
#import "AZScreen.h"

typedef struct {
    SnStartupSequence *seq;
    gboolean feedback;
} ObWaitData;

/* callback */
static void sn_event_func(SnMonitorEvent *event, void *data);
static gboolean sn_wait_timeout(void *data);
static void sn_wait_destroy(void *data);

@interface AZStartupHandler (AZPrivate)
- (ObWaitData* ) waitDataNew: (SnStartupSequence *)seq;
- (void) waitDataFree: (ObWaitData *) d;
- (ObWaitData*) waitFind: (const gchar *) iden;

/* ObjC version of callback in C */
- (void) snEventFunc: (SnMonitorEvent *) event data: (void *) data;
- (BOOL) snWaitTimeout: (void *) data;
- (void) snWaitDestroy: (void *) data;
@end

@implementation AZStartupHandler

/* sn_handler */
- (void) processXEvent: (XEvent *) e
{
  XEvent ec;
  ec = *e;
  sn_display_process_event(sn_display, &ec);
}

- (void) startup: (BOOL) reconfig
{
    if (reconfig) return;

    sn_display = sn_display_new(ob_display, NULL, NULL);
    sn_context = sn_monitor_context_new(sn_display, ob_screen,
                                        sn_event_func, NULL, NULL);

    [[AZMainLoop mainLoop] addXHandler: self];
}

- (void) shutdown: (BOOL) reconfig
{
    GSList *it;

    if (reconfig) return;

    [[AZMainLoop mainLoop] removeXHandler: self];

    for (it = sn_waits; it; it = g_slist_next(it))
        [self waitDataFree: it->data];
    g_slist_free(sn_waits);
    sn_waits = NULL;

    [[AZScreen defaultScreen] setRootCursor];

    sn_monitor_context_unref(sn_context);
    sn_display_unref(sn_display);
}

- (BOOL) applicationStarting
{
    GSList *it;

    for (it = sn_waits; it; it = g_slist_next(it)) {
        ObWaitData *d = it->data;
        if (d->feedback)
            return YES;
    }
    return NO;
}

- (void) applicationStarted: (char *) wmclass
{
    GSList *it;

    for (it = sn_waits; it; it = g_slist_next(it)) {
        ObWaitData *d = it->data;
        if (sn_startup_sequence_get_wmclass(d->seq) &&
            !strcmp(sn_startup_sequence_get_wmclass(d->seq), wmclass))
        {
            sn_startup_sequence_complete(d->seq);
            break;
        }
    }
}

- (BOOL) getDesktop: (unsigned int *) desktop forIdentifier: (char *) iden
{
    ObWaitData *d;

    if (iden && (d = [self waitFind: iden])) {
        gint desk = sn_startup_sequence_get_workspace(d->seq);
        if (desk != -1) {
            *desktop = desk;
            return YES;
        }
    }
    return NO;
}

- (id) copyWithZone: (NSZone *) zone
{
  return RETAIN(self);
}

+ (AZStartupHandler *) defaultHandler
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[AZStartupHandler alloc] init];
  }
  return sharedInstance;
}

@end

@implementation AZStartupHandler (AZPrivate)

- (ObWaitData *) waitDataNew: (SnStartupSequence *) seq
{
    ObWaitData *d = g_new(ObWaitData, 1);
    d->seq = seq;
    d->feedback = TRUE;

    sn_startup_sequence_ref(d->seq);

    return d;
}

- (void) waitDataFree: (ObWaitData *) d;
{
    if (d) {
        sn_startup_sequence_unref(d->seq);

        g_free(d);
    }
}

- (ObWaitData*) waitFind: (const gchar *) iden;
{
    ObWaitData *ret = NULL;
    GSList *it;

    for (it = sn_waits; it; it = g_slist_next(it)) {
        ObWaitData *d = it->data;
        if (!strcmp(iden, sn_startup_sequence_get_id(d->seq))) {
            ret = d;
            break;
        }
    }
    return ret;
}

- (BOOL) snWaitTimeout: (void *) data;
{
    ObWaitData *d = data;
    d->feedback = NO;
    [[AZScreen defaultScreen] setRootCursor];
    return NO; /* don't repeat */
}

- (void) snWaitDestroy: (void *) data;
{
    ObWaitData *d = data;
    sn_waits = g_slist_remove(sn_waits, d);
    [self waitDataFree: d];
}

- (void) snEventFunc: (SnMonitorEvent *) ev data: (void *) data;
{
    SnStartupSequence *seq;
    gboolean change = FALSE;
    ObWaitData *d;

    if (!(seq = sn_monitor_event_get_startup_sequence(ev)))
        return;

    AZMainLoop *mainLoop = [AZMainLoop mainLoop];

    switch (sn_monitor_event_get_type(ev)) {
    case SN_MONITOR_EVENT_INITIATED:
        d = [self waitDataNew: seq];
        sn_waits = g_slist_prepend(sn_waits, d);
        /* 30 second timeout for apps to start */
	[mainLoop addTimeoutHandler: sn_wait_timeout
		        microseconds: 30 & G_USEC_PER_SEC
			data: d
			notify: sn_wait_destroy];
        change = TRUE;
        break;
    case SN_MONITOR_EVENT_CHANGED:
        /* XXX feedback changed? */
        change = TRUE;
        break;
    case SN_MONITOR_EVENT_COMPLETED:
    case SN_MONITOR_EVENT_CANCELED:
        if ((d = [self waitFind: sn_startup_sequence_get_id(seq)])) {
            d->feedback = FALSE;
	    [mainLoop removeTimeoutHandler: sn_wait_timeout
		                      data: d];
            change = TRUE;
        }
        break;
    };

    if (change)
    {
      [[AZScreen defaultScreen] setRootCursor];
    }
}

@end

/* callback */
static void sn_event_func(SnMonitorEvent *event, void *data)
{
  [[AZStartupHandler defaultHandler] snEventFunc: event data: data];
}

static gboolean sn_wait_timeout(void *data)
{
  [[AZStartupHandler defaultHandler] snWaitTimeout: data];
}

static void sn_wait_destroy(void *data)
{
  [[AZStartupHandler defaultHandler] snWaitDestroy: data];
}

#endif

