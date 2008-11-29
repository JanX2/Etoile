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
#import "AZGroup.h"
#import "AZDebug.h"
#import "AZClientManager.h"
#import "AZMoveResizeHandler.h"
#import "AZFocusManager.h"
#import "AZKeyboardHandler.h"
#import "AZMouseHandler.h"
#ifdef USE_MENU
#import "AZMenuManager.h"
#endif
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
#if USE_XCURSOR
#include <X11/Xcursor/Xcursor.h>
#endif

#define ALTERNATIVE_RUN_LOOP 0

AZMainLoop *mainLoop = nil;

AZInstance *ob_rr_inst;
RrTheme    *ob_rr_theme;
Display    *ob_display;
int        ob_screen;
BOOL    ob_replace_wm = NO;

static ObState state;
static BOOL  xsync = NO;
static BOOL  reconfigure = NO;
static BOOL  restart = NO;
static NSString *restart_path = nil;
static Cursor    cursors[OB_NUM_CURSORS];
static KeyCode   keys[OB_NUM_KEYS];
static int      exitcode = 0;
static unsigned int remote_control = 0;
static BOOL being_replaced = NO;

static void signal_handler(int signal, void *data);
static void parse_args(int argc, char **argv);
static Cursor load_cursor(const char *name, unsigned int fontval);

int main(int argc, char **argv)
{
    CREATE_AUTORELEASE_POOL(pool);

    state = OB_STATE_STARTING;

    /* parse out command line args */
    parse_args(argc, argv);

    if (!remote_control) {
        parse_paths_startup();

        session_startup(argc, argv);
    }

    ob_display = XOpenDisplay(NULL);
    if (ob_display == NULL)
        ob_exit_with_error("Failed to open the display.");
    if (fcntl(ConnectionNumber(ob_display), F_SETFD, 1) == -1)
        ob_exit_with_error("Failed to set display as close-on-exec.");

    if (remote_control) {
        prop_startup(); /* get atoms values for the display */
        /* Send client message telling the OB process to:
         * remote_control = 1 -> reconfigure 
         * remote_control = 2 -> restart */
        PROP_MSG(RootWindow(ob_display, ob_screen),
                 ob_control, remote_control, 0, 0, 0);
        XCloseDisplay(ob_display);
	exit(EXIT_SUCCESS);
    }

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
    AZFocusManager *focusManager = [AZFocusManager defaultManager];
    AZKeyboardHandler *keyboardHandler = [AZKeyboardHandler defaultHandler];
#ifdef USE_MENU
    AZMenuManager *menuManager = [AZMenuManager defaultManager];
#endif
    AZMouseHandler *mouseHandler = [AZMouseHandler defaultHandler];

    /* Initiate main loop */
    mainLoop = [AZMainLoop mainLoop];

    /* set up signal handler */
    [mainLoop setSignalHandler: signal_handler forSignal: SIGUSR1];
    [mainLoop setSignalHandler: signal_handler forSignal: SIGUSR2];
    [mainLoop setSignalHandler: signal_handler forSignal: SIGTERM];
    [mainLoop setSignalHandler: signal_handler forSignal: SIGINT];
    [mainLoop setSignalHandler: signal_handler forSignal: SIGHUP];
    [mainLoop setSignalHandler: signal_handler forSignal: SIGPIPE];
    [mainLoop setSignalHandler: signal_handler forSignal: SIGCHLD];

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
    cursors[OB_CURSOR_POINTER] = load_cursor("left_ptr", XC_left_ptr);
    cursors[OB_CURSOR_BUSY] = load_cursor("left_ptr_watch", XC_watch);
    cursors[OB_CURSOR_MOVE] = load_cursor("fleur", XC_fleur);
    cursors[OB_CURSOR_NORTH] = load_cursor("top_side", XC_top_side);
    cursors[OB_CURSOR_NORTHEAST] = load_cursor("top_right_corner",
                                               XC_top_right_corner);
    cursors[OB_CURSOR_EAST] = load_cursor("right_side", XC_right_side);
    cursors[OB_CURSOR_SOUTHEAST] = load_cursor("bottom_right_corner",
                                               XC_bottom_right_corner);
    cursors[OB_CURSOR_SOUTH] = load_cursor("bottom_side", XC_bottom_side);
    cursors[OB_CURSOR_SOUTHWEST] = load_cursor("bottom_left_corner",
                                               XC_bottom_left_corner);
    cursors[OB_CURSOR_WEST] = load_cursor("left_side", XC_left_side);
    cursors[OB_CURSOR_NORTHWEST] = load_cursor("top_left_corner",
                                               XC_top_left_corner);

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
	    [mrHandler startup: reconfigure];
	    [keyboardHandler startup: reconfigure];
	    [mouseHandler startup: reconfigure];
#ifdef USE_MENU
	    [menuManager startup: reconfigure];
#endif

            if (!reconfigure) {
                /* get all the existing windows */
		[clientManager manageAll];
		[focusManager fallback: YES];
            } else {
                /* redecorate all existing windows */
		int j, jcount = [clientManager count];

		for (j = 0; j < jcount; j++) {
                    AZClient *c = [clientManager clientAtIndex: j];
                    /* the new config can change the window's decorations */
                    [c setupDecorAndFunctions];
                    /* redraw the frames */
		    [[c frame] adjustAreaWithMoved: YES resized: YES fake: NO];
                }
            }

            reconfigure = NO;

            state = OB_STATE_RUNNING;
	    {
		[mainLoop setRun: YES];
		[mainLoop setRunning: YES];
		[mainLoop willStartRunning];

		// NOTE: We have to simulate NSWorkspaceDidLaunchApplicationNotification
		// in order to be properly tracked by System. This is necessary because
		// Azalea doesn't use NSApplication at this time.
		NSString *path = [[NSBundle mainBundle] executablePath];
		NSString *name = [[NSProcessInfo processInfo] processName];
		NSDictionary *userInfo = [NSDictionary 
			dictionaryWithObjectsAndKeys: path, @"NSApplicationPath", 
			name, @"NSApplicationName", nil]; 
		NSNotification *notif = [NSNotification
			notificationWithName: NSWorkspaceDidLaunchApplicationNotification
			              object: nil
			            userInfo: userInfo];
		[[[NSWorkspace sharedWorkspace] notificationCenter] 
			postNotification: notif];

#if ALTERNATIVE_RUN_LOOP
		NSLog(@"ALTERNATIVE_RUN_LOOP");
		[mainLoop mainLoopRun]; /* run once in case reconfigure */
		[app run];
#else
		NSRunLoop *loop = [NSRunLoop currentRunLoop];

		while ([mainLoop run] == YES)
		{
		  [mainLoop mainLoopRun];
	      /* We need this in order to get NSTimer working */
		  [loop runUntilDate: [NSDate dateWithTimeIntervalSinceNow: 0.01]];
		}
#endif
		[mainLoop didFinishRunning];
		[mainLoop setRunning: NO];
	    }
            state = OB_STATE_EXITING;

            if (!reconfigure) {
		[clientManager unmanageAll];
            }

#ifdef USE_MENU
	    [menuManager shutdown: reconfigure];
#endif
	    [mouseHandler shutdown: reconfigure];
	    [keyboardHandler shutdown: reconfigure];
	    [mrHandler shutdown: reconfigure];
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

    session_shutdown(being_replaced);

    XCloseDisplay(ob_display);

    parse_paths_shutdown();

    if (restart) {
        if (restart_path != nil) {
#if 1
	    // This is a simplied version
	    int error = execlp([restart_path cString], NULL, NULL);
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
	// FIXME: should use openapp
        execvp(argv[0], argv); /* try how we were run */
        execlp(argv[0], (char*)[[[NSString stringWithCString: argv[0]] lastPathComponent] cString], NULL); /* last resort */
    }

    DESTROY(pool);
     
    return exitcode;
}

static void signal_handler(int signal, void *data)
{
    switch (signal) {
    case SIGUSR1:
        NSDebugLLog(@"Signal", @"Caught signal %d. Restarting.", signal);
        ob_restart();
        break;
    case SIGUSR2:
        NSDebugLLog(@"Signal", @"Caught signal %d. Reconfiguring.", signal);
        ob_reconfigure(); 
        break;
    case SIGCHLD:
        /* reap children */
        while (waitpid(-1, NULL, WNOHANG) > 0);
        break;
    default:
        NSDebugLLog(@"Signal", @"Caught signal %d. Exiting.", signal);
        /* TERM and INT return a 0 code */
        ob_exit(!(signal == SIGTERM || signal == SIGINT));
    }
}

static void print_version()
{
    printf("Openbox %s\n", PACKAGE_VERSION);
    printf("Copyright (c) 2007 Yen-ju Chen\n");
    printf("Copyright (c) 2007 Dana Jansens\n\n");
    printf("Copyright (c) 2007 Mikael Magnusson\n");
    printf("This program comes with ABSOLUTELY NO WARRANTY.\n");
    printf("This is free software, and you are welcome to redistribute it\n");
    printf("under certain conditions. See the file COPYING for details.\n\n");
}

static void print_help()
{
    printf("Syntax: openbox [options]\n\n");
    printf("Options:\n\n");
    printf("  --reconfigure       Tell the currently running instance of "
           "Openbox to\n"
           "                      reconfigure (and then exit immediately)\n");
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
        } else if (!strcmp(argv[i], "--reconfigure")) {
            remote_control = 1;
        } else if (!strcmp(argv[i], "--restart")) {
            remote_control = 2;
        }
    }
}

static Cursor load_cursor(const char *name, unsigned int fontval)
{
    Cursor c = None;

#if USE_XCURSOR
    c = XcursorLibraryLoadCursor(ob_display, name);
#endif
    if (c == None)
        c = XCreateFontCursor(ob_display, fontval);
    return c;
}

void ob_exit_with_error(const char *msg)
{
    NSLog(@"Critical: %s", msg);
    session_shutdown(YES);
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

void ob_exit_replace()
{
    exitcode = 0;
    being_replaced = YES;
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
