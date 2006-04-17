/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZStartupHandler.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

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

@interface AZWaitData: NSObject
{
    SnStartupSequence *seq;
    BOOL feedback;
}
- (SnStartupSequence *) seq;
- (BOOL) feedback;
- (void) set_seq: (SnStartupSequence *) seq;
- (void) set_feedback: (BOOL) feedback;
@end

@implementation AZWaitData
- (SnStartupSequence *) seq { return seq; }
- (BOOL) feedback { return feedback; }
- (void) set_seq: (SnStartupSequence *) s { seq = s; }
- (void) set_feedback: (BOOL) f { feedback = f; }
@end

/* callback */
static void sn_event_func(SnMonitorEvent *event, void *data);

@interface AZStartupHandler (AZPrivate)
- (AZWaitData* ) waitDataNew: (SnStartupSequence *)seq;
- (void) waitDataFree: (AZWaitData *) d;
- (AZWaitData*) waitFind: (const gchar *) iden;

/* ObjC version of callback in C */
- (void) snEventFunc: (SnMonitorEvent *) event data: (void *) data;
- (BOOL) snWaitTimeout: (id) data;
- (void) snWaitDestroy: (id) data;
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

    sn_waits = [[NSMutableArray alloc] init];

    [[AZMainLoop mainLoop] addXHandler: self];
}

- (void) shutdown: (BOOL) reconfig
{
    if (reconfig) return;

    [[AZMainLoop mainLoop] removeXHandler: self];

    int i, count = [sn_waits count];
    for (i = 0; i < count; i++) {
      [self waitDataFree: [sn_waits objectAtIndex: i]];
    }
    DESTROY(sn_waits);

    [[AZScreen defaultScreen] setRootCursor];

    sn_monitor_context_unref(sn_context);
    sn_display_unref(sn_display);
}

- (BOOL) applicationStarting
{
    int i, count = [sn_waits count];
    for (i = 0; i < count; i++) {
        AZWaitData *d = [sn_waits objectAtIndex: i];;
        if ([d feedback])
            return YES;
    }
    return NO;
}

- (void) applicationStarted: (char *) wmclass
{
    int i, count = [sn_waits count];
    for (i = 0; i < count; i++) {
        AZWaitData *d = [sn_waits objectAtIndex: i];
        if (sn_startup_sequence_get_wmclass([d seq]) &&
            !strcmp(sn_startup_sequence_get_wmclass([d seq]), wmclass))
        {
            sn_startup_sequence_complete([d seq]);
            break;
        }
    }
}

- (BOOL) getDesktop: (unsigned int *) desktop forIdentifier: (char *) iden
{
    AZWaitData *d;

    if (iden && (d = [self waitFind: iden])) {
        int desk = sn_startup_sequence_get_workspace([d seq]);
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

- (AZWaitData *) waitDataNew: (SnStartupSequence *) seq
{
    AZWaitData *d = [[AZWaitData alloc] init];
    [d set_seq: seq];
    [d set_feedback: YES];

    sn_startup_sequence_ref([d seq]);

    return d;
}

- (void) waitDataFree: (AZWaitData *) d;
{
    if (d) {
        sn_startup_sequence_unref([d seq]);

	DESTROY(d);
    }
}

- (AZWaitData*) waitFind: (const gchar *) iden;
{
    AZWaitData *ret = nil;
    int i, count = [sn_waits count];

    for (i = 0; i < count; i++) {
        AZWaitData *d = [sn_waits objectAtIndex: i];
        if (!strcmp(iden, sn_startup_sequence_get_id([d seq]))) {
            ret = d;
            break;
        }
    }
    return ret;
}

- (BOOL) snWaitTimeout: (id) data;
{
    AZWaitData *d = data;
    [d set_feedback: NO];
    [[AZScreen defaultScreen] setRootCursor];
    return NO; /* don't repeat */
}

- (void) snWaitDestroy: (id) data;
{
    AZWaitData *d = data;
    [sn_waits removeObject: d];
    [self waitDataFree: d];
}

- (void) snEventFunc: (SnMonitorEvent *) ev data: (void *) data;
{
    SnStartupSequence *seq;
    BOOL change = NO;
    AZWaitData *d;

    if (!(seq = sn_monitor_event_get_startup_sequence(ev)))
        return;

    AZMainLoop *mainLoop = [AZMainLoop mainLoop];

    switch (sn_monitor_event_get_type(ev)) {
    case SN_MONITOR_EVENT_INITIATED:
        d = [self waitDataNew: seq];
	[sn_waits insertObject: d atIndex: 0];
        /* 30 second timeout for apps to start */
	[mainLoop addTimeout: self handler: @selector(snWaitTimeout:)
		        microseconds: 30 & G_USEC_PER_SEC
			data: d
			notify: @selector(snWaitDestroy:)];
        change = YES;
        break;
    case SN_MONITOR_EVENT_CHANGED:
        /* XXX feedback changed? */
        change = YES;
        break;
    case SN_MONITOR_EVENT_COMPLETED:
    case SN_MONITOR_EVENT_CANCELED:
        if ((d = [self waitFind: sn_startup_sequence_get_id(seq)])) {
            [d set_feedback: NO];
	    [mainLoop removeTimeout: self handler: @selector(snWaitTimeout:)
		                      data: d];
            change = YES;
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

#endif

