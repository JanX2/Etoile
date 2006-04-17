/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   AZMainLoop.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   mainloop.c for the Openbox window manager
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

#import "AZMainLoop.h"
#import "AZDock.h"
#import "AZClient.h"
#import "AZClientManager.h"
#import <X11/Xlib.h>
#import <glib.h>
#import <signal.h>
#import "action.h"

struct _ObMainLoop
{
  int fd_x; /* The X fd is a special case! */
  int fd_max;
  GHashTable *fd_handlers;
  fd_set fd_set;
};

typedef struct _ObMainLoop ObMainLoop;
typedef struct _ObMainLoopFdHandlerType     ObMainLoopFdHandlerType;

/* all created ObMainLoops. Used by the signal handler to pass along signals */
static NSMutableArray *all_loops = nil;

/* signals are global to all loops */
struct {
    unsigned int installed; /* a ref count */
    struct sigaction oldact;
} all_signals[NUM_SIGNALS];

/* a set of all possible signals */
sigset_t all_signals_set;

/* signals which cause a core dump, these can't be used for callbacks */
static int core_signals[] =
{
    SIGABRT,
    SIGSEGV,
    SIGFPE,
    SIGILL,
    SIGQUIT,
    SIGTRAP,
    SIGSYS,
    SIGBUS,
    SIGXCPU,
    SIGXFSZ
};
#define NUM_CORE_SIGNALS (sizeof(core_signals) / sizeof(core_signals[0]))

static void sighandler(int sig);
static void fd_handler_destroy(void * data);
static void fd_handle_foreach(void * key,
                              void * value,
                              void * data);
static void calc_max_fd(ObMainLoop *loop);

@interface AZMainLoopTimer: NSObject
{
    id target;
    unsigned long delay;
    SEL func;
    id data;
    SEL destroy;

    /* The timer needs to be freed */
    BOOL del_me;
    /* The time the last fire should've been at */
    GTimeVal last;
    /* When this timer will next trigger */
    GTimeVal timeout;
}
- (BOOL) fire;
- (void) cleanup; /* Don't confuse -dealloc */

- (void) addTimeout: (unsigned long) delta;
- (void) addLast: (unsigned long) delta;

- (id) target;
- (unsigned long) delay;
- (SEL) func;
- (id) data;
- (SEL) destroy;
- (BOOL) del_me;
- (GTimeVal) last;
- (GTimeVal) timeout;
- (void) set_target: (id) target;
- (void) set_delay: (unsigned long) delay;
- (void) set_func: (SEL) func;
- (void) set_data: (id) data;
- (void) set_destroy: (SEL) destroy;
- (void) set_del_me: (BOOL) del_me;
- (void) set_last: (GTimeVal) last;
- (void) set_timeout: (GTimeVal) timeout;
@end

@implementation AZMainLoopTimer

- (BOOL) fire
{
  if ((target == nil) || (func == NULL)) return NO;

  /* fire invocation */
  NSMethodSignature *ms = [target methodSignatureForSelector: func];
  NSInvocation *inv = [NSInvocation invocationWithMethodSignature: ms];
  [inv setTarget: target];
  [inv setSelector: func];
  if (data)
    [inv setArgument: &data atIndex: 2];

  [inv invoke];
  BOOL ret = NO;
  [inv getReturnValue: &ret];
  return ret;
}

- (void) cleanup
{
  if ((target == nil) || (destroy== NULL)) return;

  /* fire invocation */
  NSMethodSignature *ms = [target methodSignatureForSelector: destroy];
  NSInvocation *inv = [NSInvocation invocationWithMethodSignature: ms];
  [inv setTarget: target];
  [inv setSelector: destroy];
  if (data)
    [inv setArgument: &data atIndex: 2];
  [inv invoke];
}

- (void) addTimeout: (unsigned long) delta
{
    g_time_val_add(&timeout, delta);
}

- (void) addLast: (unsigned long) delta
{
    g_time_val_add(&last, delta);
}

- (id) target { return target; }
- (unsigned long) delay { return delay; }
- (SEL) func { return func; }
- (id) data { return data; }
- (SEL) destroy { return destroy; }
- (BOOL) del_me { return del_me; }
- (GTimeVal) last { return last; }
- (GTimeVal) timeout { return timeout; }
- (void) set_target: (id) t { target = t; }
- (void) set_delay: (unsigned long) d { delay = d; }
- (void) set_func: (SEL) f { func = f; }
- (void) set_data: (id) d { data = d; }
- (void) set_destroy: (SEL) d { destroy = d; }
- (void) set_del_me: (BOOL) d { del_me = d; }
- (void) set_last: (GTimeVal) l { last = l; }
- (void) set_timeout: (GTimeVal) t { timeout = t; }
@end

@interface AZMainLoopSignalHandler: NSObject
{
    int signal;
    ObMainLoopSignalHandler func;
}
- (void) fire;
- (int) signal;
- (ObMainLoopSignalHandler) func;
- (void) set_signal: (int) signal;
- (void) set_func: (ObMainLoopSignalHandler) func;
@end

@implementation AZMainLoopSignalHandler
- (void) fire
{
  func(signal, NULL);
}
- (int) signal { return signal; }
- (ObMainLoopSignalHandler) func { return func; }
- (void) set_signal: (int) s { signal = s; }
- (void) set_func: (ObMainLoopSignalHandler) f { func = f; }
@end


struct _ObMainLoopFdHandlerType
{
    int fd;
    void * data;
    ObMainLoopFdHandler func;
    GDestroyNotify destroy;
};

extern Display *ob_display;

struct _ObMainLoop *ob_main_loop;

static AZMainLoop *sharedInstance;

@interface AZMainLoop (AZPrivate)
- (void) destroyActionForClient: (NSNotification *) not;
- (long) timeCompare: (GTimeVal) a to: (GTimeVal) b;
- (void) insertTimer: (AZMainLoopTimer *) ins;
- (BOOL) nearestTimeoutWait: (GTimeVal *) tm;
- (void) dispatchTimer: (GTimeVal **) wait;
- (void) handleSignal: (int) signal;
@end

@implementation AZMainLoop

/*** XEVENT WATCHERS ***/
- (void) addXHandler: (id <AZXHandler>) handler
{
  [xHandlers addObject: handler];
}

- (void) removeXHandler: (id <AZXHandler>) handler
{
  [xHandlers removeObject: handler];
}

- (void) addFdHandler: (ObMainLoopFdHandler) handler
                forFd: (int) fd
                 data: (void *) data
{
    ObMainLoopFdHandlerType *h;

    h = g_new(ObMainLoopFdHandlerType, 1);
    h->fd = fd;
    h->func = handler;
    h->data = data;

    g_hash_table_replace(ob_main_loop->fd_handlers, &h->fd, h);
    FD_SET(h->fd, &ob_main_loop->fd_set);
    calc_max_fd(ob_main_loop);
}

- (void) removeFdHandlerForFd: (int) fd
{
  g_hash_table_remove(ob_main_loop->fd_handlers, &fd);
}

- (void) addTimeout: (id) target
            handler: (SEL) handler
       microseconds: (unsigned long) microseconds
               data: (id) data
             notify: (SEL) notify
{
    AZMainLoopTimer *t = [[AZMainLoopTimer alloc] init];
    [t set_target: target];
    [t set_delay: microseconds];
    [t set_func: handler];
    [t set_data: data];
    [t set_destroy: notify];
    [t set_del_me: NO];
    g_get_current_time(&now);
    [t set_last: now];
    [t set_timeout: now];
    [t addTimeout: [t delay]];

    [self insertTimer: AUTORELEASE(t)];
}

- (void) removeTimeout: (id) target handler: (SEL) handler
{
    int i, count = [timers count];
    for (i = 0; i < count; i++)
    {
      AZMainLoopTimer *t = [timers objectAtIndex: i];
      if (([t target] == target) && ([t func] == handler))
        [t set_del_me: YES];
    }
}

- (void) removeTimeout: (id) target handler: (SEL) handler
                         data: (id) data
{
  int i, count = [timers count];
  for (i = 0; i < count; i++)
  {
    AZMainLoopTimer *t = [timers objectAtIndex: i];
    if ([t target] == target && [t func] == handler && [t data] == data)
      [t set_del_me: YES];
  }
}

- (void) addSignalHandler: (ObMainLoopSignalHandler) handler
                forSignal: (int) signal
{
    if (signal >= NUM_SIGNALS) return;

    AZMainLoopSignalHandler *h = [[AZMainLoopSignalHandler alloc] init];
    [h set_signal: signal];
    [h set_func: handler];

    if (signal_handlers[signal]== nil)
      signal_handlers[signal] = [[NSMutableArray alloc] init];

    NSMutableArray *handlers = signal_handlers[signal];
    [handlers insertObject: h atIndex: 0];
    DESTROY(h);

    if (!all_signals[signal].installed) {
        struct sigaction action;
        sigset_t sigset;

        sigemptyset(&sigset);
        action.sa_handler = sighandler;
        action.sa_mask = sigset;
        action.sa_flags = SA_NOCLDSTOP;

        sigaction(signal, &action, &all_signals[signal].oldact);
    }

}

- (void) removeSignalHandler: (ObMainLoopSignalHandler) handler
{
    unsigned int i, j;
    GSList *it, *next;

    for (i = 0; i < NUM_SIGNALS; ++i) {
	NSMutableArray *handlers = signal_handlers[i];
	if ((handlers == nil) || ([handlers count] == 0))
          continue;
	for (j = 0; j < [handlers count]; j++) {
            AZMainLoopSignalHandler *h = [handlers objectAtIndex: j];

            if ([h func] == handler) {
		NSAssert(all_signals[[h signal]].installed > 0, @"Signal is not installed");

                all_signals[[h signal]].installed--;
                if (!all_signals[[h signal]].installed) {
                    sigaction([h signal], &all_signals[[h signal]].oldact, NULL);
                }

		[handlers removeObject: h];
		j--;
            }
        }
    }
}

/*! Queues an action, which will be run when there are no more X events
  to process */
- (void) queueAction: (AZAction *) act
{
  [actionQueue addObject: AUTORELEASE([act copy])];
}

- (void) willStartRunning
{
  [[NSNotificationCenter defaultCenter] addObserver: self
	  selector: @selector(destroyActionForClient:)
	  name: AZClientDestroyNotification
	  object: nil];
}

- (void) didFinishRunning
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (BOOL) run
{
  return run;
}

- (BOOL) running;
{
  return running;
}

- (void) setRun: (BOOL) r
{
  run = r;
}

- (void) setRunning: (BOOL) r
{
  running = r;
}

- (void) mainLoopRun
{
    XEvent e;
    struct timeval *wait;
    fd_set selset;
    AZAction *act;

    ObMainLoop *loop = ob_main_loop;

    while (run)
    {
        if (signal_fired) {
            unsigned int i, j;
            sigset_t oldset;

            /* block signals so that we can do this without the data changing
               on us */
            sigprocmask(SIG_SETMASK, &all_signals_set, &oldset);

            for (i = 0; i < NUM_SIGNALS; ++i) {
                while (signals_fired[i]) {
		    NSArray *handlers = signal_handlers[i];
		    for (j = 0; j < [handlers count]; j++) {
		        AZMainLoopSignalHandler *h = [handlers objectAtIndex: j];
			[h fire];
                    }
                    signals_fired[i]--;
                }
            }
            signal_fired = NO;

            sigprocmask(SIG_SETMASK, &oldset, NULL);
        } else if (XPending(ob_display)) {
            do {
                XNextEvent(ob_display, &e);

		int i, count = [xHandlers count];
		for (i = 0; i < count; i++)
		{
		  [[xHandlers objectAtIndex: i] processXEvent: &e];
		}
            } while (XPending(ob_display));
        } else if ([actionQueue count]) {
            /* only fire off one action at a time, then go back for more
               X events, since the action might cause some X events (like
               FocusIn :) */

            do {
		act = [actionQueue objectAtIndex: 0];
                if ([act data].any.client_action == OB_CLIENT_ACTION_ALWAYS &&
                    ![act data].any.c)
                {
		    [actionQueue removeObjectAtIndex: 0];
                    act = nil;
                }
            } while (!act && [actionQueue count]);

            if  (act) {
                [act func]([act data_pointer]);
		[actionQueue removeObjectAtIndex: 0];
            }
        } else {
            /* this only runs if there were no x events received */

	    [self dispatchTimer: (GTimeVal**)&wait];

            selset = loop->fd_set;
            /* there is a small race condition here. if a signal occurs
               between this if() and the select() then we will not process
               the signal until 'wait' expires. possible solutions include
               using GStaticMutex, and having the signal handler set 'wait'
               to 0 */
            if (!signal_fired)
                select(loop->fd_max + 1, &selset, NULL, NULL, wait);

            /* handle the X events with highest prioirity */
            if (FD_ISSET(loop->fd_x, &selset))
	    {
	       return;
               //continue;
	    }

            g_hash_table_foreach(loop->fd_handlers,
                                 fd_handle_foreach, &selset);
        }
    }
}

- (void) exit
{
  [self setRun: NO];
}

- (id) init
{
  self = [super init];

  xHandlers = [[NSMutableArray alloc] init];
  actionQueue = [[NSMutableArray alloc] init];
  timers = [[NSMutableArray alloc] init];

    ObMainLoop *loop;

    loop = g_new0(ObMainLoop, 1);
    loop->fd_x = ConnectionNumber(ob_display);
    FD_ZERO(&loop->fd_set);
    FD_SET(loop->fd_x, &loop->fd_set);
    loop->fd_max = loop->fd_x;

    loop->fd_handlers = g_hash_table_new_full(g_int_hash, g_int_equal,
                                              NULL, fd_handler_destroy);

    g_get_current_time(&now);

    /* only do this if we're the first loop created */
    if (!all_loops) {
        all_loops = [[NSMutableArray alloc] init];

        unsigned int i;
        struct sigaction action;
        sigset_t sigset;

        /* initialize the all_signals_set */
        sigfillset(&all_signals_set);

        sigemptyset(&sigset);
        action.sa_handler = sighandler;
        action.sa_mask = sigset;
        action.sa_flags = SA_NOCLDSTOP;

        /* grab all the signals that cause core dumps */
        for (i = 0; i < NUM_CORE_SIGNALS; ++i) {
            /* SIGABRT is curiously not grabbed here!! that's because when we
               get one of the core_signals, we use abort() to dump the core.
               And having the abort() only go back to our signal handler again
               is less than optimal */
            if (core_signals[i] != SIGABRT) {
                sigaction(core_signals[i], &action,
                          &all_signals[core_signals[i]].oldact);
                all_signals[core_signals[i]].installed++;
            }
        }
    }

  [all_loops insertObject: self atIndex: 0];

  ob_main_loop = loop;

  return self;
}

- (void) dealloc
{
  DESTROY(xHandlers);
  DESTROY(actionQueue);
  DESTROY(timers);
  [super dealloc];
}

+ (AZMainLoop *) mainLoop
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[AZMainLoop alloc] init];
  }
  return sharedInstance;
}

@end

@implementation AZMainLoop (AZPrivate)
- (void) destroyActionForClient: (NSNotification *) not 
{
  AZClient *client = [not object];
  int i, count = [actionQueue count];
  for (i = 0; i < count; i++)
  {
    AZAction *act = [actionQueue objectAtIndex: i];
    if ([act data].any.c == client)
    {
      [act data_pointer]->any.c = nil;
    }
  }
}

/*** TIMEOUTS ***/

#define NEAREST_TIMEOUT \
    ([[timers objectAtIndex: 0] timeout])

- (long) timeCompare: (GTimeVal) a to: (GTimeVal) b
{
    long r = 0;

    if ((r = b.tv_sec - a.tv_sec)) return r;
    return b.tv_usec - a.tv_usec;
}

- (void) insertTimer: (AZMainLoopTimer *) ins
{
  int i, count = [timers count];

  for (i = 0; i < count; i++)
  {
    AZMainLoopTimer *t = [timers objectAtIndex: i];
    if ([self timeCompare: [ins timeout] to: [t timeout]] >= 0)
    {
      [timers insertObject: ins atIndex: i];
      return;
    }
  }
  
  /* didn't fit anywhere in the list */
  [timers addObject: ins];
}

/* find the time to wait for the nearest timeout */
- (BOOL) nearestTimeoutWait: (GTimeVal *) tm
{
  if ([timers count] == 0)
    return NO;

  tm->tv_sec = NEAREST_TIMEOUT.tv_sec - now.tv_sec;
  tm->tv_usec = NEAREST_TIMEOUT.tv_usec - now.tv_usec;

  while (tm->tv_usec < 0) {
    tm->tv_usec += G_USEC_PER_SEC;
    tm->tv_sec--;
  }
  tm->tv_sec += tm->tv_usec / G_USEC_PER_SEC;
  tm->tv_usec %= G_USEC_PER_SEC;
  if (tm->tv_sec < 0)
    tm->tv_sec = 0;

  return YES;
}

- (void) dispatchTimer: (GTimeVal **) wait
{
  BOOL fired = NO;
  g_get_current_time(&now);

  int i;
  for (i = 0; i < [timers count]; i++)
  {
    AZMainLoopTimer *curr;

    curr = [timers objectAtIndex: i];

    /* since timer_stop doesn't actually free the timer, we have to do our
       real freeing in here.
     */
    if ([curr del_me]) {
      /* delete the top */
      RETAIN(curr);
      [timers removeObjectAtIndex: i];
      [curr cleanup];
      RELEASE(curr);

      i--; /* because object is deleted, reduce i by 1 */
      continue;
    }

    /* the queue is sorted, so if this timer shouldn't fire,
     * none are ready */
    if ([self timeCompare: NEAREST_TIMEOUT to: now] < 0)
      break;

    /* we set the last fired time to delay msec after the previous firing,
       then re-insert.  timers maintain their order and may trigger more
       than once if they've waited more than one delay's worth of time.
     */
    RETAIN(curr);
    [timers removeObjectAtIndex: i];
    [curr addLast: [curr delay]];

    if ([curr fire]) {
      [curr addTimeout: [curr delay]];
      [self insertTimer: curr];
    } else {
      [curr cleanup];
    }
    RELEASE(curr);

    fired = YES;
  }

  if (fired) {
    /* if at least one timer fires, then don't wait on X events, as there
       may already be some in the queue from the timer callbacks.
     */
    ret_wait.tv_sec = ret_wait.tv_usec = 0;
    *wait = &ret_wait;
  } else if ([self nearestTimeoutWait: &ret_wait]) {
    *wait = &ret_wait;
  } else {
    *wait = NULL;
  }
}

- (void) handleSignal: (int) sig
{
    unsigned int i;

    for (i = 0; i < NUM_CORE_SIGNALS; ++i)
        if (sig == core_signals[i]) {
            /* XXX special case for signals that default to core dump.
               but throw some helpful output here... */

            fprintf(stderr, "Fuck yah. Core dump. (Signal=%d)\n", sig);

            /* die with a core dump */
            abort();
        }

    signal_fired = YES;
    signals_fired[sig]++;
}

@end

static void fd_handle_foreach(void * key,
                              void * value,
                              void * data)
{
    ObMainLoopFdHandlerType *h = value;
    fd_set *set = data;

    if (FD_ISSET(h->fd, set))
        h->func(h->fd, h->data);
}

/*** SIGNAL WATCHERS ***/

static void sighandler(int sig)
{
    if (sig >= NUM_SIGNALS) return;

    int i, count = [all_loops count];
    for (i = 0; i < count; i++) {
        AZMainLoop *loop = [all_loops objectAtIndex: i];
	[loop handleSignal: sig]; 
    }
}

/*** FILE DESCRIPTOR WATCHERS ***/

static void max_fd_func(void * key, void * value, void * data)
{
    ObMainLoop *loop = data;

    /* key is the fd */
    loop->fd_max = MAX(loop->fd_max, *(int*)key);
}

static void calc_max_fd(ObMainLoop *loop)
{
    loop->fd_max = loop->fd_x;

    g_hash_table_foreach(loop->fd_handlers, max_fd_func, loop);
}

static void fd_handler_destroy(void * data)
{
    ObMainLoopFdHandlerType *h = data;

    FD_CLR(h->fd, &ob_main_loop->fd_set);

    if (h->destroy)
        h->destroy(h->data);
}

