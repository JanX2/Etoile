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
#import "AZClient.h"
#import "AZClientManager.h"
#import "AZEventHandler.h"
#import <X11/Xlib.h>
#import <signal.h>
#import "action.h"

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

@interface AZMainLoopFdHandler: NSObject
{
    fd_set *_set; /* from AZMainLoop */
    int fd;
    void * data;
    ObMainLoopFdHandler func;
}
- (id) initWithFdSet: (fd_set *) fs;
- (void) fire;

- (void) fd_clear;
- (void) fd_set;
- (BOOL) fd_is_set: (fd_set *) set;

- (int) fd;
- (void *) data;
- (ObMainLoopFdHandler) func;
- (void) set_fd: (int) fd;
- (void) set_data: (void *) data;
- (void) set_func: (ObMainLoopFdHandler) func;
@end

@implementation AZMainLoopFdHandler
- (void) fd_clear
{
  FD_CLR(fd, _set);
}

- (void) fd_set
{
  FD_SET(fd, _set);
}

- (BOOL) fd_is_set: (fd_set *) set
{
  return FD_ISSET(fd, set);
}

- (void) fire
{
  func(fd, data);
}

- (id) initWithFdSet: (fd_set *) fs
{
  self = [super init];
  _set = fs;
  return self;
}

- (int) fd { return fd; }
- (void *) data { return data; }
- (ObMainLoopFdHandler) func { return func; }
- (void) set_fd: (int) f { fd = f; }
- (void) set_data: (void *) d { data = d; }
- (void) set_func: (ObMainLoopFdHandler) f { func = f; }
@end

extern Display *ob_display;

static AZMainLoop *sharedInstance;

@interface AZMainLoop (AZPrivate)
- (void) destroyActionForClient: (NSNotification *) not;
- (void) handleSignal: (int) signal;
- (void) calcMaxFd;
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
    AZMainLoopFdHandler *h;

    h = [[AZMainLoopFdHandler alloc] initWithFdSet: &_fd_set];
    [h set_fd: fd];
    [h set_func: handler];
    [h set_data: data];

    /* remove old one */
    [self removeFdHandlerForFd: fd];

    [fd_handlers setObject: h forKey: [NSNumber numberWithInt: fd]];
    [h fd_set];
    [self calcMaxFd];
}

- (void) removeFdHandlerForFd: (int) fd
{
  AZMainLoopFdHandler *temp = nil;
  NSNumber *key = [NSNumber numberWithInt: fd];
  temp = [fd_handlers objectForKey: key];
  if (temp) {
    /* Cannot wait until the object is autoreleased. */
    [temp fd_clear];
    [fd_handlers removeObjectForKey: key];
  }
}

- (void) setSignalHandler: (ObMainLoopSignalHandler) handler
                forSignal: (int) signal
{
    if (signal >= NUM_SIGNALS) return;

    signal_handlers[signal] = handler;

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
	// NOTE: May be we need to create additional autorelease pools per while 
	// loops in this method. For example, to dealloc autoreleased objects each 
	// time a X event has been processed.
	CREATE_AUTORELEASE_POOL(pool);

	XEvent e;
	fd_set selset;
	AZAction *act;

	if (signal_fired) 
	{
		unsigned int i;
		sigset_t oldset;

		/* block signals so that we can do this without the data changing
		   on us */
		sigprocmask(SIG_SETMASK, &all_signals_set, &oldset);

		for (i = 0; i < NUM_SIGNALS; ++i) 
		{
			while (signals_fired[i]) 
			{
				signal_handlers[i](i, NULL);
				signals_fired[i]--;
			}
		}
		signal_fired = NO;

		sigprocmask(SIG_SETMASK, &oldset, NULL);
	} 
	else if (XPending(ob_display)) 
	{
		do {
			XNextEvent(ob_display, &e);

			int i, count = [xHandlers count];
			for (i = 0; i < count; i++)
			{
				[[xHandlers objectAtIndex: i] processXEvent: &e];
			}
		} while (XPending(ob_display));
	} 
	else if ([actionQueue count]) 
	{
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

		if  (act) 
		{
			event_curtime = [act data].any.time;
			[act func]([act data_pointer]);
			event_curtime = CurrentTime;
			[actionQueue removeObjectAtIndex: 0];
		}
	} 
	else 
	{
		/* this only runs if there were no x events received */

		selset = _fd_set;
		/* there is a small race condition here. if a signal occurs
		   between this if() and the select() then we will not process
		   the signal until 'wait' expires. possible solutions include
		   using GStaticMutex, and having the signal handler set 'wait'
		   to 0 */
		struct timeval zero_wait;
		zero_wait.tv_sec = zero_wait.tv_usec = 0;

		if (!signal_fired)
			select(fd_max + 1, &selset, NULL, NULL, &zero_wait);

		/* handle the X events with highest prioirity */
		if (FD_ISSET(fd_x, &selset))
		{
			return;
		}

		NSArray *allKeys = [fd_handlers allKeys];
		NSEnumerator *e = [allKeys objectEnumerator];
		NSNumber *key = nil;
		AZMainLoopFdHandler *h = nil;
		while ((key = [e nextObject])) 
		{
			h = [fd_handlers objectForKey: key];
			if ([h fd_is_set: &selset])
				[h fire];
	    }
	}

	DESTROY(pool);
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

	fd_x = ConnectionNumber(ob_display);
	FD_ZERO(&_fd_set);
	FD_SET(fd_x, &_fd_set);
	fd_max = fd_x;

	fd_handlers = [[NSMutableDictionary alloc] init];

	gettimeofday(&now, NULL);

	/* only do this if we're the first loop created */
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
	for (i = 0; i < NUM_CORE_SIGNALS; ++i) 
	{
		/* SIGABRT is curiously not grabbed here!! that's because when we
		   get one of the core_signals, we use abort() to dump the core.
		   And having the abort() only go back to our signal handler again
		   is less than optimal */
		if (core_signals[i] != SIGABRT) 
		{
			sigaction(core_signals[i], &action,
			          &all_signals[core_signals[i]].oldact);
			all_signals[core_signals[i]].installed++;
		}
	}

	return self;
}

- (void) dealloc
{
	DESTROY(xHandlers);
	DESTROY(actionQueue);
	DESTROY(fd_handlers);
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

- (void) handleSignal: (int) sig
{
    unsigned int i;

    for (i = 0; i < NUM_CORE_SIGNALS; ++i)
        if (sig == core_signals[i]) {
            /* XXX special case for signals that default to core dump.
               but throw some helpful output here... */

            fprintf(stderr, "Core dump. (Openbox received signal %d)\n", sig);

            /* die with a core dump */
            abort();
        }

    signal_fired = YES;
    signals_fired[sig]++;
}

- (void) calcMaxFd
{
  fd_max = fd_x;

  NSArray *allKeys = [fd_handlers allKeys];
  NSEnumerator *e = [allKeys objectEnumerator];
  NSNumber *key = nil;
  AZMainLoopFdHandler *h = nil;
  while ((key = [e nextObject])) {
    h = [fd_handlers objectForKey: key];
    fd_max = MAX(fd_max, [h fd]);
  }
}

@end

/*** SIGNAL WATCHERS ***/

static void sighandler(int sig)
{
    if (sig >= NUM_SIGNALS) return;

    [[AZMainLoop mainLoop] handleSignal: sig];
}

