// Modified by Yen-Ju
/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   mainloop.h for the Openbox window manager
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

#import <Foundation/Foundation.h>
#import <X11/Xlib.h>
#import <glib.h>

@protocol AZXHandler <NSObject>
- (void) processXEvent: (XEvent *) e;
@end

@class AZAction;

typedef void (*ObMainLoopFdHandler) (int fd, void * data);
typedef void (*ObMainLoopSignalHandler) (int signal, void * data);

@interface AZMainLoop: NSObject
{
  NSMutableArray *timers;
  GTimeVal now;
  GTimeVal ret_wait;

  NSMutableArray *xHandlers;
  NSMutableArray *actionQueue;

  BOOL run; /* do keep running */
  BOOL running; /* is still running */
}

- (void) addXHandler: (id <AZXHandler>) handler;
- (void) removeXHandler: (id <AZXHandler>) handler;

/* fd is only used by ICE/SM in event.m */
- (void) addFdHandler: (ObMainLoopFdHandler) handler
                forFd: (int) fd
		 data: (void *) data;
- (void) removeFdHandlerForFd: (int) fd;
             
- (void) addTimeout: (id) target
            handler: (SEL) handler
       microseconds: (unsigned long) microseconds
               data: (id) data
             notify: (GDestroyNotify) notify;
- (void) removeTimeout: (id) target handler: (SEL) handler;
- (void) removeTimeout: (id) target handler: (SEL) handler
                         data: (id) data;
- (void) addSignalHandler: (ObMainLoopSignalHandler) handler 
                forSignal: (int) signal;
- (void) removeSignalHandler: (ObMainLoopSignalHandler) handler;

- (void) queueAction: (AZAction *) act;

- (void) willStartRunning;
- (void) didFinishRunning;

- (BOOL) run;
- (BOOL) running;
- (void) setRun: (BOOL) run;
- (void) setRunning: (BOOL) running;

- (void) mainLoopRun;
- (void) exit;

+ (AZMainLoop *) mainLoop;

@end

