/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

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

#include "openbox.h"
#include "session.h"
#include "menu.h"
#include "prop.h"
#include "keyboard.h"
#include "mouse.h"
#include "extensions.h"
#include "menuframe.h"
#include "grab.h"
#include "config.h"
#include "parser/parse.h"
#include "render/render.h"
#include "render/theme.h"

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

RrInstance *ob_rr_inst;
RrTheme    *ob_rr_theme;
Display    *ob_display;
int        ob_screen;
gboolean    ob_replace_wm;

static ObState   state;
static gboolean  xsync;
static gboolean  reconfigure;
static gboolean  restart;
static gchar    *restart_path;
static Cursor    cursors[OB_NUM_CURSORS];
static KeyCode   keys[OB_NUM_KEYS];
static gint      exitcode = 0;

static void signal_handler(gint signal, gpointer data);
static void parse_args(gint argc, gchar **argv);

gint main(gint argc, gchar **argv)
{
#ifdef DEBUG
    AZDebug_show_output(TRUE);
#endif

    CREATE_AUTORELEASE_POOL(x);

    state = OB_STATE_STARTING;

    g_set_prgname(argv[0]);

    if (chdir(g_get_home_dir()) == -1)
        g_warning("Unable to change to home directory (%s): %s",
                  g_get_home_dir(), g_strerror(errno));
     
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
    NSApplication *app = [NSApplication sharedApplication];
#if ALTERNATIVE_RUN_LOOP
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

    ob_rr_inst = RrInstanceNew(ob_display, ob_screen);
    if (ob_rr_inst == NULL)
        ob_exit_with_error("Failed to initialize the render library.");

    XSynchronize(ob_display, xsync);

    /* check for locale support */
    if (!XSupportsLocale())
        g_warning("X server does not support locale.");
    if (!XSetLocaleModifiers(""))
        g_warning("Cannot set locale modifiers for the X server.");

    /* set our error handler */
    XSetErrorHandler(AZXErrorHandler);

    /* set the DISPLAY environment variable for any lauched children, to the
       display we're using, so they open in the right place. */
    putenv(g_strdup_printf("DISPLAY=%s", DisplayString(ob_display)));

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
                ObParseInst *i;
                xmlDocPtr doc;
                xmlNodePtr node;

                /* startup the parsing so everything can register sections
                   of the rc */
                i = parse_startup();

                config_startup(i);
                /* parse/load user options */
                if (parse_load_rc(&doc, &node))
                    parse_tree(i, doc, node->xmlChildrenNode);
                /* we're done with parsing now, kill it */
                parse_close(doc);
                parse_shutdown(i);
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
            keyboard_startup(reconfigure);
            mouse_startup(reconfigure);
            menu_startup(reconfigure);

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

            reconfigure = FALSE;

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
		NSRunLoop *loop = [NSRunLoop currentRunLoop];
		NSDate *past = [NSDate distantPast];

		while ([mainLoop run] == YES)
		{
		  [mainLoop mainLoopRun]; /* run once in case reconfigure */
		  [loop acceptInputForMode: NSDefaultRunLoopMode
			   beforeDate: past];
		}
#endif
		[mainLoop didFinishRunning];
		[mainLoop setRunning: NO];
	    }
            state = OB_STATE_EXITING;

            if (!reconfigure) {
		[defaultDock removeAll];
		[clientManager unmanageAll];
            }

            menu_shutdown(reconfigure);
            mouse_shutdown(reconfigure);
            keyboard_shutdown(reconfigure);
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

    XSync(ob_display, FALSE);

    RrThemeFree(ob_rr_theme);
    RrInstanceFree(ob_rr_inst);

    session_shutdown();

    XCloseDisplay(ob_display);

    parse_paths_shutdown();

    if (restart) {
        if (restart_path != NULL) {
            gint argcp;
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
        }

        /* re-run me */
        execvp(argv[0], argv); /* try how we were run */
        execlp(argv[0], g_path_get_basename(argv[0]),
               (char *)NULL); /* last resort */
    }

    DESTROY(x);
     
    return exitcode;
}

static void signal_handler(gint signal, gpointer data)
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
    g_print("Openbox %s\n", PACKAGE_VERSION);
    g_print("Copyright (c) 2004 Mikael Magnusson\n");
    g_print("Copyright (c) 2003 Ben Jansens\n\n");
    g_print("This program comes with ABSOLUTELY NO WARRANTY.\n");
    g_print("This is free software, and you are welcome to redistribute it\n");
    g_print("under certain conditions. See the file COPYING for details.\n\n");
}

static void print_help()
{
    g_print("Syntax: openbox [options]\n\n");
    g_print("Options:\n\n");
#ifdef USE_SM
    g_print("  --sm-disable        Disable connection to session manager\n");
    g_print("  --sm-client-id ID   Specify session management ID\n");
    g_print("  --sm-save-file FILE Specify file to load a saved session"
            "from\n");
#endif
    g_print("  --replace           Replace the currently running window "
            "manager\n");
    g_print("  --help              Display this help and exit\n");
    g_print("  --version           Display the version and exit\n");
    g_print("  --sync              Run in synchronous mode (this is slow and "
            "meant for\n"
            "                      debugging X routines)\n");
    g_print("  --debug             Display debugging output\n");
    g_print("\nPlease report bugs at %s\n\n", PACKAGE_BUGREPORT);
}

static void parse_args(gint argc, gchar **argv)
{
    gint i;

    for (i = 1; i < argc; ++i) {
        if (!strcmp(argv[i], "--version")) {
            print_version();
            exit(0);
        } else if (!strcmp(argv[i], "--help")) {
            print_help();
            exit(0);
        } else if (!strcmp(argv[i], "--g-fatal-warnings")) {
            g_log_set_always_fatal(G_LOG_LEVEL_CRITICAL);
        } else if (!strcmp(argv[i], "--replace")) {
            ob_replace_wm = TRUE;
        } else if (!strcmp(argv[i], "--sync")) {
            xsync = TRUE;
        } else if (!strcmp(argv[i], "--debug")) {
            AZDebugShowOutput(TRUE);
        } else {
            g_printerr("Invalid option: '%s'\n\n", argv[i]);
            print_help();
            exit(1);
        }
    }
}

void ob_exit_with_error(gchar *msg)
{
    g_critical(msg);
    session_shutdown();
    exit(EXIT_FAILURE);
}

void ob_restart_other(const gchar *path)
{
    restart_path = g_strdup(path);
    ob_restart();
}

void ob_restart()
{
    restart = TRUE;
    ob_exit(0);
}

void ob_reconfigure()
{
    reconfigure = TRUE;
    ob_exit(0);
}

void ob_exit(gint code)
{
    exitcode = code;
    [mainLoop exit];
}

Cursor ob_cursor(ObCursor cursor)
{
    g_assert(cursor < OB_NUM_CURSORS);
    return cursors[cursor];
}

KeyCode ob_keycode(ObKey key)
{
    g_assert(key < OB_NUM_KEYS);
    return keys[key];
}

ObState ob_state()
{
    return state;
}
