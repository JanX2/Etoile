/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   openbox.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   openbox.c for the Openbox window manager
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

#import "AZApplication.h"
#import "AZMainLoop.h"
#import "AZScreen.h"
#import "AZStartupHandler.h"
#import "AZEventHandler.h"
#import "AZDebug.h"
#import "AZDock.h"
#import "AZGroup.h"
#import "AZClientManager.h"
#import "AZMoveResizeHandler.h"
#import "AZFocusManager.h"
#import "AZKeyboardHandler.h"
#import "AZMouseHandler.h"
#import "AZMenuManager.h"

#import "openbox.h"
#import "session.h"
#import "prop.h"
#import "extensions.h"
#import "grab.h"
#import "config.h"
#import "parse.h"
#import "render/render.h"
#import "render/theme.h"

#ifdef HAVE_FCNTL_H
#  include <fcntl.h>
#endif
#ifdef HAVE_SIGNAL_H
#  include <signal.h>
#endif
#ifdef HAVE_STDLIB_H
#  include <stdlib.h>
#endif
#ifdef HAVE_LOCALE_H
#  include <locale.h>
#endif
#ifdef HAVE_SYS_STAT_H
#  include <sys/stat.h>
#  include <sys/types.h>
#endif
#ifdef HAVE_SYS_WAIT_H
#  include <sys/types.h>
#  include <sys/wait.h>
#endif
#ifdef HAVE_UNISTD_H
#  include <unistd.h>
#endif
#include <errno.h>

#include <X11/cursorfont.h>

#define ALTERNATIVE_RUN_LOOP 0

AZMainLoop *mainLoop = nil;

AZInstance *ob_rr_inst;
RrTheme    *ob_rr_theme;
Display    *ob_display;
int        ob_screen;
BOOL    ob_replace_wm;

static ObState   state;
static BOOL  xsync;
static BOOL  reconfigure;
static BOOL  restart;
static NSString *restart_path = nil;
static Cursor    cursors[OB_NUM_CURSORS];
static KeyCode   keys[OB_NUM_KEYS];
static int      exitcode = 0;

static void signal_handler(int signal, void *data);
static void parse_args(int argc, char **argv);

int main(int argc, char **argv)
{
#ifdef DEBUG
    AZDebug_show_output(YES);
#endif

    CREATE_AUTORELEASE_POOL(x);

    state = OB_STATE_STARTING;

    parse_paths_startup();

    session_startup(&argc, &argv);

    /* parse out command line args */
    parse_args(argc, argv);

    ob_display = XOpenDisplay(NULL);
    if (ob_display == NULL)
        ob_exit_with_error("Failed to open the display.");
    if (fcntl(ConnectionNumber(ob_display), F_SETFD, 1) == -1)
        ob_exit_with_error("Failed to set display as close-on-exec.");

    /* Initiate NSApp */
#if ALTERNATIVE_RUN_LOOP
    NSApplication *app = [NSApplication sharedApplication];
    AZApplication *AZApp = [AZApplication sharedApplication];
    [app setDelegate: AZApp];
#endif

    AZScreen *defaultScreen = [AZScreen defaultScreen];
    AZStartupHandler *startupHandler = [AZStartupHandler defaultHandler];
    AZEventHandler *eventHandler = [AZEventHandler defaultHandler];
    AZGroupManager *groupManager = [AZGroupManager defaultManager];
    AZClientManager *clientManager = [AZClientManager defaultManager];
    AZMoveResizeHandler *mrHandler = [AZMoveResizeHandler defaultHandler];
    AZDock *defaultDock = [AZDock defaultDock];
    AZFocusManager *focusManager = [AZFocusManager defaultManager];
    AZKeyboardHandler *keyboardHandler = [AZKeyboardHandler defaultHandler];
    AZMenuManager *menuManager = [AZMenuManager defaultManager];
    AZMouseHandler *mouseHandler = [AZMouseHandler defaultHandler];

    /* Initiate main loop */
    mainLoop = [AZMainLoop mainLoop];

    /* set up signal handler */
    [mainLoop addSignalHandler: signal_handler forSignal: SIGUSR1];
    [mainLoop addSignalHandler: signal_handler forSignal: SIGUSR2];
    [mainLoop addSignalHandler: signal_handler forSignal: SIGTERM];
    [mainLoop addSignalHandler: signal_handler forSignal: SIGINT];
    [mainLoop addSignalHandler: signal_handler forSignal: SIGHUP];
    [mainLoop addSignalHandler: signal_handler forSignal: SIGPIPE];
    [mainLoop addSignalHandler: signal_handler forSignal: SIGCHLD];

    ob_screen = DefaultScreen(ob_display);

    ob_rr_inst = [[AZInstance alloc] initWithDisplay: ob_display screen: ob_screen];
    if (ob_rr_inst == nil)
        ob_exit_with_error("Failed to initialize the render library.");

    XSynchronize(ob_display, xsync);

    /* check for locale support */
    if (!XSupportsLocale())
        NSLog(@"Warning: X server does not support locale.");
    if (!XSetLocaleModifiers(""))
        NSLog(@"Warning: Cannot set locale modifiers for the X server.");

    /* set our error handler */
    XSetErrorHandler(AZXErrorHandler);

    /* set the DISPLAY environment variable for any lauched children, to the
       display we're using, so they open in the right place. */
    putenv((char*)[[NSString stringWithFormat: @"DISPLAY=%s", DisplayString(ob_display)] cString]);

    /* create available cursors */
    cursors[OB_CURSOR_NONE] = None;
    cursors[OB_CURSOR_POINTER] =
        XCreateFontCursor(ob_display, XC_left_ptr);
    cursors[OB_CURSOR_BUSY] =
        XCreateFontCursor(ob_display, XC_watch);
    cursors[OB_CURSOR_MOVE] =
        XCreateFontCursor(ob_display, XC_fleur);
    cursors[OB_CURSOR_NORTH] =
        XCreateFontCursor(ob_display, XC_top_side);
    cursors[OB_CURSOR_NORTHEAST] =
        XCreateFontCursor(ob_display, XC_top_right_corner);
    cursors[OB_CURSOR_EAST] =
        XCreateFontCursor(ob_display, XC_right_side);
    cursors[OB_CURSOR_SOUTHEAST] =
        XCreateFontCursor(ob_display, XC_bottom_right_corner);
    cursors[OB_CURSOR_SOUTH] =
        XCreateFontCursor(ob_display, XC_bottom_side);
    cursors[OB_CURSOR_SOUTHWEST] =
        XCreateFontCursor(ob_display, XC_bottom_left_corner);
    cursors[OB_CURSOR_WEST] =
        XCreateFontCursor(ob_display, XC_left_side);
    cursors[OB_CURSOR_NORTHWEST] =
        XCreateFontCursor(ob_display, XC_top_left_corner);

    /* create available keycodes */
    keys[OB_KEY_RETURN] =
        XKeysymToKeycode(ob_display, XStringToKeysym("Return"));
    keys[OB_KEY_ESCAPE] =
        XKeysymToKeycode(ob_display, XStringToKeysym("Escape"));
    keys[OB_KEY_LEFT] =
        XKeysymToKeycode(ob_display, XStringToKeysym("Left"));
    keys[OB_KEY_RIGHT] =
        XKeysymToKeycode(ob_display, XStringToKeysym("Right"));
    keys[OB_KEY_UP] =
        XKeysymToKeycode(ob_display, XStringToKeysym("Up"));
    keys[OB_KEY_DOWN] =
        XKeysymToKeycode(ob_display, XStringToKeysym("Down"));

    prop_startup(); /* get atoms values for the display */
    extensions_query_all(); /* find which extensions are present */

    if ([defaultScreen screenAnnex]) { /* it will be ours! */
        do {
            {
		AZParser *parser = nil;
                xmlDocPtr doc;
                xmlNodePtr node;

                /* startup the parsing so everything can register sections
                   of the rc */
		parser = [[AZParser alloc] init];

                config_startup(parser);
                /* parse/load user options */
                if (parse_load_rc(&doc, &node))
		    [parser parseDocument: doc node: node->xmlChildrenNode];
                /* we're done with parsing now, kill it */
                parse_close(doc);
		DESTROY(parser);
            }

            /* load the theme specified in the rc file */
            {
                RrTheme *theme;
                if ((theme = RrThemeNew(ob_rr_inst, config_theme))) {
                    RrThemeFree(ob_rr_theme);
                    ob_rr_theme = theme;
                }
                if (ob_rr_theme == NULL)
                    ob_exit_with_error("Unable to load a theme.");
            }

            if (reconfigure) {
		int j, jcount = [clientManager count];

                /* update all existing windows for the new theme */
		for (j = 0; j < jcount; j++) {
                    AZClient *c = [clientManager clientAtIndex: j];
		    [[c frame] adjustTheme];
                }
            }
	    [eventHandler startup: reconfigure];
            /* focus_backup is used for stacking, so this needs to come before
               anything that calls stacking_add */
	    [focusManager startup: reconfigure];
            window_startup(reconfigure);
	    [startupHandler startup: reconfigure];
	    [defaultScreen startup: reconfigure];
            grab_startup(reconfigure);
	    [groupManager startup: reconfigure];
	    [clientManager startup: reconfigure];
	    [defaultDock startup: reconfigure];
	    [mrHandler startup: reconfigure];
	    [keyboardHandler startup: reconfigure];
	    [mouseHandler startup: reconfigure];
	    [menuManager startup: reconfigure];

            if (!reconfigure) {
                /* get all the existing windows */
		[clientManager manageAll];
		[focusManager fallback: OB_FOCUS_FALLBACK_NOFOCUS];
            } else {
                /* redecorate all existing windows */
		int j, jcount = [clientManager count];

		for (j = 0; j < jcount; j++) {
                    AZClient *c = [clientManager clientAtIndex: j];
		    [[c frame] adjustAreaWithMoved: YES resized: YES fake: NO];
                }
            }

            reconfigure = NO;

            state = OB_STATE_RUNNING;
	    {
		[mainLoop setRun: YES];
		[mainLoop setRunning: YES];
		[mainLoop willStartRunning];
#if ALTERNATIVE_RUN_LOOP
		NSLog(@"ALTERNATIVE_RUN_LOOP");
		[mainLoop mainLoopRun]; /* run once in case reconfigure */
		[app run];
#else
		CREATE_AUTORELEASE_POOL(x);
		NSRunLoop *loop = [NSRunLoop currentRunLoop];
		NSDate *past = [NSDate distantPast];

		while ([mainLoop run] == YES)
		{
		  [mainLoop mainLoopRun]; /* run once in case reconfigure */
		  [loop acceptInputForMode: NSDefaultRunLoopMode
			   beforeDate: past];
		}
		DESTROY(x);
#endif
		[mainLoop didFinishRunning];
		[mainLoop setRunning: NO];
	    }
            state = OB_STATE_EXITING;

            if (!reconfigure) {
		[defaultDock removeAll];
		[clientManager unmanageAll];
            }

	    [menuManager shutdown: reconfigure];
	    [mouseHandler shutdown: reconfigure];
	    [keyboardHandler shutdown: reconfigure];
	    [mrHandler shutdown: reconfigure];
	    [defaultDock shutdown: reconfigure];
	    [clientManager shutdown: reconfigure];
	    [groupManager shutdown: reconfigure];
            grab_shutdown(reconfigure);
	    [defaultScreen shutdown: reconfigure];
	    [focusManager shutdown: reconfigure];
	    [startupHandler shutdown: reconfigure];
            window_shutdown(reconfigure);
	    [eventHandler shutdown: reconfigure];
            config_shutdown();
        } while (reconfigure);
    }

    XSync(ob_display, NO);

    RrThemeFree(ob_rr_theme);
    DESTROY(ob_rr_inst);

    session_shutdown();

    XCloseDisplay(ob_display);

    parse_paths_shutdown();

    if (restart) {
        if (restart_path != nil) {
#if 1
	    // This is a simplied version
	    int error = execlp([restart_path cString], NULL);
	    if (error == -1)
	      NSLog(@"Failed to execute '%@'", restart);
#else
            int argcp;
            gchar **argvp;
            GError *err = NULL;

            /* run other window manager */
            if (g_shell_parse_argv(restart_path, &argcp, &argvp, &err)) {
                execvp(argvp[0], argvp);
                g_strfreev(argvp);
            } else {
                g_warning("failed to execute '%s': %s", restart_path,
                          err->message);
                g_error_free(err);
            }
#endif
        }

        /* re-run me */
        execvp(argv[0], argv); /* try how we were run */
        execlp(argv[0], g_path_get_basename(argv[0]),
               (char *)NULL); /* last resort */
    }

    DESTROY(x);
     
    return exitcode;
}

static void signal_handler(int signal, void *data)
{
    switch (signal) {
    case SIGUSR1:
        AZDebug("Caught signal %d. Restarting.\n", signal);
        ob_restart();
        break;
    case SIGUSR2:
        AZDebug("Caught signal %d. Reconfiguring.\n", signal);
        ob_reconfigure(); 
        break;
    case SIGCHLD:
        /* reap children */
        while (waitpid(-1, NULL, WNOHANG) > 0);
        break;
    default:
        AZDebug("Caught signal %d. Exiting.\n", signal);
        /* TERM and INT return a 0 code */
        ob_exit(!(signal == SIGTERM || signal == SIGINT));
    }
}

static void print_version()
{
    printf("Openbox %s\n", PACKAGE_VERSION);
    printf("Copyright (c) 2006 Yen-ju Chen\n");
    printf("Copyright (c) 2004 Mikael Magnusson\n");
    printf("Copyright (c) 2003 Ben Jansens\n\n");
    printf("This program comes with ABSOLUTELY NO WARRANTY.\n");
    printf("This is free software, and you are welcome to redistribute it\n");
    printf("under certain conditions. See the file COPYING for details.\n\n");
}

static void print_help()
{
    printf("Syntax: openbox [options]\n\n");
    printf("Options:\n\n");
#ifdef USE_SM
    printf("  --sm-disable        Disable connection to session manager\n");
    printf("  --sm-client-id ID   Specify session management ID\n");
    printf("  --sm-save-file FILE Specify file to load a saved session"
            "from\n");
#endif
    printf("  --replace           Replace the currently running window "
            "manager\n");
    printf("  --help              Display this help and exit\n");
    printf("  --version           Display the version and exit\n");
    printf("  --sync              Run in synchronous mode (this is slow and "
            "meant for\n"
            "                      debugging X routines)\n");
    printf("  --debug             Display debugging output\n");
    printf("\nPlease report bugs at %s\n\n", PACKAGE_BUGREPORT);
}

static void parse_args(int argc, char **argv)
{
    int i;

    for (i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--version")) {
            print_version();
            exit(0);
        } else if (!strcmp(argv[i], "--help")) {
            print_help();
            exit(0);
        } else if (!strcmp(argv[i], "--replace")) {
            ob_replace_wm = YES;
        } else if (!strcmp(argv[i], "--sync")) {
            xsync = YES;
        } else if (!strcmp(argv[i], "--debug")) {
            AZDebugShowOutput(YES);
        } else {
            printf("Invalid option: '%s'\n\n", argv[i]);
            print_help();
            exit(1);
        }
    }
}

void ob_exit_with_error(char *msg)
{
    NSLog(@"Critical: %s", msg);
    session_shutdown();
    exit(EXIT_FAILURE);
}

void ob_restart_other(const char *path)
{
    if (path) {
      ASSIGN(restart_path, ([NSString stringWithCString: path]));
    } else {
      DESTROY(restart_path);
    }
    ob_restart();
}

void ob_restart()
{
    restart = YES;
    ob_exit(0);
}

void ob_reconfigure()
{
    reconfigure = YES;
    ob_exit(0);
}

void ob_exit(int code)
{
    exitcode = code;
    [mainLoop exit];
}

Cursor ob_cursor(ObCursor cursor)
{
    if (cursor >= OB_NUM_CURSORS)
      NSLog(@"Warning: cursor out of range");
    return cursors[cursor];
}

KeyCode ob_keycode(ObKey key)
{
    if (key >= OB_NUM_KEYS)
      NSLog(@"Warning: key out of range");
    return keys[key];
}

ObState ob_state()
{
    return state;
}
