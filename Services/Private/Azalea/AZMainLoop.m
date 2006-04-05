// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

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

/* this should be more than the number of possible signals on any
 *    architecture... */
#define NUM_SIGNALS 99

struct _ObMainLoop
{
  gint fd_x; /* The X fd is a special case! */
  gint fd_max;
  GHashTable *fd_handlers;
  fd_set fd_set;

  gboolean signal_fired;
  guint signals_fired[NUM_SIGNALS];
  GSList *signal_handlers[NUM_SIGNALS];
};

typedef struct _ObMainLoop ObMainLoop;

typedef struct _ObMainLoopTimer             ObMainLoopTimer;
typedef struct _ObMainLoopSignal            ObMainLoopSignal;
typedef struct _ObMainLoopSignalHandlerType ObMainLoopSignalHandlerType;
typedef struct _ObMainLoopFdHandlerType     ObMainLoopFdHandlerType;

/* all created ObMainLoops. Used by the signal handler to pass along signals */
static GSList *all_loops;

/* signals are global to all loops */
struct {
    guint installed; /* a ref count */
    struct sigaction oldact;
} all_signals[NUM_SIGNALS];

/* a set of all possible signals */
sigset_t all_signals_set;

/* signals which cause a core dump, these can't be used for callbacks */
static gint core_signals[] =
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

static void sighandler(gint sig);
static void fd_handler_destroy(gpointer data);
static void fd_handle_foreach(gpointer key,
                              gpointer value,
                              gpointer data);
static void calc_max_fd(ObMainLoop *loop);

struct _ObMainLoopTimer
{
    gulong delay;
    GSourceFunc func;
    gpointer data;
    GDestroyNotify destroy;

    /* The timer needs to be freed */
    BOOL del_me;
    /* The time the last fire should've been at */
    GTimeVal last;
    /* When this timer will next trigger */
    GTimeVal timeout;
};

struct _ObMainLoopSignalHandlerType
{
    gint signal;
    ObMainLoopSignalHandler func;
};

struct _ObMainLoopFdHandlerType
{
    gint fd;
    gpointer data;
    ObMainLoopFdHandler func;
    GDestroyNotify destroy;
};

void ob_main_loop_client_destroy(ObClient *client, void *data);

struct _ObAction;

extern Display *ob_display;

struct _ObMainLoop *ob_main_loop;

static AZMainLoop *sharedInstance;

@interface AZMainLoop (AZPrivate)
- (void) destroyActionForClient: (ObClient *) client;
- (long) timeCompare: (GTimeVal *) a to: (GTimeVal *) b;
- (void) insertTimer: (ObMainLoopTimer *) ins;
- (BOOL) nearestTimeoutWait: (GTimeVal *) tm;
- (void) dispatchTimer: (GTimeVal **) wait;
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

- (void) addTimeoutHandler: (GSourceFunc) handler
              microseconds: (unsigned long) microseconds
                      data: (void *) data
                    notify: (GDestroyNotify) notify
{
    ObMainLoopTimer *t = g_new(ObMainLoopTimer, 1);
    t->delay = microseconds;
    t->func = handler;
    t->data = data;
    t->destroy = notify;
    t->del_me = FALSE;
    g_get_current_time(&now);
    t->last = t->timeout = now;
    g_time_val_add(&t->timeout, t->delay);

    [self insertTimer: t];
}

- (void) removeTimeoutHandler: (GSourceFunc) handler
{
    int i, count = [timers count];
    for (i = 0; i < count; i++)
    {
      ObMainLoopTimer *t = (ObMainLoopTimer *)[[timers objectAtIndex: i] pointerValue];
      if (t->func == handler)
        t->del_me = YES;
    }
}

- (void) removeTimeoutHandler: (GSourceFunc) handler
                         data: (void *) data
{
  int i, count = [timers count];
  for (i = 0; i < count; i++)
  {
    ObMainLoopTimer *t = (ObMainLoopTimer *)[[timers objectAtIndex: i] pointerValue];
    if (t->func == handler && t->data == data)
      t->del_me = YES;
  }
}

- (void) addSignalHandler: (ObMainLoopSignalHandler) handler
                forSignal: (int) signal
{
    ObMainLoopSignalHandlerType *h;

    g_return_if_fail(signal < NUM_SIGNALS);

    h = g_new(ObMainLoopSignalHandlerType, 1);
    h->signal = signal;
    h->func = handler;
    ob_main_loop->signal_handlers[h->signal] =
        g_slist_prepend(ob_main_loop->signal_handlers[h->signal], h);

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
    guint i;
    GSList *it, *next;

    for (i = 0; i < NUM_SIGNALS; ++i) {
        for (it = ob_main_loop->signal_handlers[i]; it; it = next) {
            ObMainLoopSignalHandlerType *h = it->data;

            next = g_slist_next(it);

            if (h->func == handler) {
                g_assert(all_signals[h->signal].installed > 0);

                all_signals[h->signal].installed--;
                if (!all_signals[h->signal].installed) {
                    sigaction(h->signal, &all_signals[h->signal].oldact, NULL);
                }

                ob_main_loop->signal_handlers[i] =
                    g_slist_delete_link(ob_main_loop->signal_handlers[i], it);

                g_free(h);
            }
        }
    }
}

/*! Queues an action, which will be run when there are no more X events
  to process */
- (void) queueAction: (struct _ObAction *) act
{
  [actionQueue addObject: [NSValue valueWithPointer: (void *)action_copy(act)]];
}

- (void) willStartRunning
{
  [[AZClientManager defaultManager] addDestructor: ob_main_loop_client_destroy data: (void *)self];
}

- (void) didFinishRunning
{
  [[AZClientManager defaultManager] removeDestructor: ob_main_loop_client_destroy];
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
    GSList *it;
    ObAction *act;

    ObMainLoop *loop = ob_main_loop;

    while (run)
    {
        if (loop->signal_fired) {
            guint i;
            sigset_t oldset;

            /* block signals so that we can do this without the data changing
               on us */
            sigprocmask(SIG_SETMASK, &all_signals_set, &oldset);

            for (i = 0; i < NUM_SIGNALS; ++i) {
                while (loop->signals_fired[i]) {
                    for (it = loop->signal_handlers[i];
                            it; it = g_slist_next(it)) {
                        ObMainLoopSignalHandlerType *h = it->data;
                        h->func(i, NULL);
                    }
                    loop->signals_fired[i]--;
                }
            }
            loop->signal_fired = FALSE;

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
		act = [[actionQueue objectAtIndex: 0] pointerValue];
                if (act->data.any.client_action == OB_CLIENT_ACTION_ALWAYS &&
                    !act->data.any.c)
                {
		    [actionQueue removeObjectAtIndex: 0];
                    action_unref(act);
                    act = NULL;
                }
            } while (!act && [actionQueue count]);

            if  (act) {
                act->func(&act->data);
		[actionQueue removeObjectAtIndex: 0];
                action_unref(act);
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
            if (!loop->signal_fired)
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
        guint i;
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

  all_loops = g_slist_prepend(all_loops, loop);

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
- (void) destroyActionForClient: (ObClient *) client
{
  int i, count = [actionQueue count];
  for (i = 0; i < count; i++)
  {
    ObAction *act = (ObAction *)[[actionQueue objectAtIndex: i] pointerValue];
    if (act->data.any.c == client)
    {
      act->data.any.c = NULL;
    }
  }
}

/*** TIMEOUTS ***/

#define NEAREST_TIMEOUT \
    (((ObMainLoopTimer *)[[timers objectAtIndex: 0] pointerValue])->timeout)

- (long) timeCompare: (GTimeVal *) a to: (GTimeVal *) b
{
    long r = 0;

    if ((r = b->tv_sec - a->tv_sec)) return r;
    return b->tv_usec - a->tv_usec;
}

- (void) insertTimer: (ObMainLoopTimer *) ins
{
  int i, count = [timers count];

  for (i = 0; i < count; i++)
  {
    ObMainLoopTimer *t = (ObMainLoopTimer *)[[timers objectAtIndex: i] pointerValue];
    if ([self timeCompare: &ins->timeout to: &t->timeout] >= 0)
    {
      [timers insertObject: [NSValue valueWithPointer: (void *)ins]
	           atIndex: i];
      return;
    }
  }
  
  /* didn't fit anywhere in the list */
  [timers addObject: [NSValue valueWithPointer: (void *)ins]];
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
    ObMainLoopTimer *curr;

    curr = (ObMainLoopTimer *)[[timers objectAtIndex: i] pointerValue];

    /* since timer_stop doesn't actually free the timer, we have to do our
       real freeing in here.
     */
    if (curr->del_me) {
      /* delete the top */
      [timers removeObjectAtIndex: i];
      if (curr->destroy)
        curr->destroy(curr->data);
      g_free(curr);
      i--; /* because object is deleted, reduce i by 1 */
      continue;
    }

    /* the queue is sorted, so if this timer shouldn't fire,
     * none are ready */
    if ([self timeCompare: &NEAREST_TIMEOUT to: &now] < 0)
      break;

    /* we set the last fired time to delay msec after the previous firing,
       then re-insert.  timers maintain their order and may trigger more
       than once if they've waited more than one delay's worth of time.
     */
    [timers removeObjectAtIndex: i];
    g_time_val_add(&curr->last, curr->delay);
    if (curr->func(curr->data)) {
      g_time_val_add(&curr->timeout, curr->delay);
      [self insertTimer: curr];
    } else {
      if (curr->destroy)
        curr->destroy(curr->data);
      g_free(curr);
    }

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

@end

static void fd_handle_foreach(gpointer key,
                              gpointer value,
                              gpointer data)
{
    ObMainLoopFdHandlerType *h = value;
    fd_set *set = data;

    if (FD_ISSET(h->fd, set))
        h->func(h->fd, h->data);
}

void ob_main_loop_client_destroy(ObClient *client, void *data)
{
  AZMainLoop *mainLoop = (AZMainLoop *) data;
  [mainLoop destroyActionForClient: client];
}

/*** SIGNAL WATCHERS ***/

static void sighandler(gint sig)
{
    GSList *it;
    guint i;

    g_return_if_fail(sig < NUM_SIGNALS);

    for (i = 0; i < NUM_CORE_SIGNALS; ++i)
        if (sig == core_signals[i]) {
            /* XXX special case for signals that default to core dump.
               but throw some helpful output here... */

            fprintf(stderr, "Fuck yah. Core dump. (Signal=%d)\n", sig);

            /* die with a core dump */
            abort();
        }

    for (it = all_loops; it; it = g_slist_next(it)) {
        ObMainLoop *loop = it->data;
        loop->signal_fired = TRUE;
        loop->signals_fired[sig]++;
    }
}

/*** FILE DESCRIPTOR WATCHERS ***/

static void max_fd_func(gpointer key, gpointer value, gpointer data)
{
    ObMainLoop *loop = data;

    /* key is the fd */
    loop->fd_max = MAX(loop->fd_max, *(gint*)key);
}

static void calc_max_fd(ObMainLoop *loop)
{
    loop->fd_max = loop->fd_x;

    g_hash_table_foreach(loop->fd_handlers, max_fd_func, loop);
}

static void fd_handler_destroy(gpointer data)
{
    ObMainLoopFdHandlerType *h = data;

    FD_CLR(h->fd, &ob_main_loop->fd_set);

    if (h->destroy)
        h->destroy(h->data);
}

