/* -*- indent-tabs-mode: nil; tab-width: 4; c-basic-offset: 4; -*-

   session.m for the Azalea window manager
   Copyright (c) 2006        Yen-Ju Chen

   session.c for the Openbox window manager
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

/* This session code is largely inspired by metacity code. */

#import "session.h"
#import <GNUstepBase/GSXML.h>
NSMutableArray *session_saved_state;

@implementation AZSessionState

- (NSComparisonResult) compareStacking: (AZSessionState *) other
{
  if ([self stacking] < [other stacking])
    return NSOrderedAscending;
  else if ([self stacking] == [other stacking])
    return NSOrderedSame;
  else
    return NSOrderedDescending;
}

- (NSString *) identifier { return iden; }
- (NSString *) name { return name; }
- (NSString *) class { return class; }
- (NSString *) role { return role; }
- (unsigned int) stacking { return stacking; }
- (unsigned int) desktop { return desktop; }
- (int) x { return x; }
- (int) y { return y; }
- (int) w { return w; }
- (int )h { return h; }
- (BOOL) shaded { return shaded; }
- (BOOL) iconic { return iconic; }
- (BOOL) skip_pager { return skip_pager; }
- (BOOL) skip_taskbar { return skip_taskbar; }
- (BOOL) fullscreen { return fullscreen; }
- (BOOL) above { return above; }
- (BOOL) below { return below; }
- (BOOL) max_horz { return max_horz; }
- (BOOL) max_vert { return max_vert; }
- (BOOL) matched { return matched; }
- (void) set_identifier: (NSString *) i { ASSIGNCOPY(iden, i); }
- (void) set_name: (NSString *) n { ASSIGNCOPY(name, n); }
- (void) set_class: (NSString *) c { ASSIGNCOPY(class, c); }
- (void) set_role: (NSString *) r { ASSIGNCOPY(role, r); }
- (void) set_stacking: (unsigned int) s { stacking = s; }
- (void) set_desktop: (unsigned int) d { desktop = d; }
- (void) set_x: (int) _x { x = _x; }
- (void) set_y: (int) _y { y = _y; }
- (void) set_w: (int) _w { w = _w; }
- (void) set_h: (int) _h { h = _h; }
- (void) set_shaded: (BOOL) s { shaded = s; }
- (void) set_iconic: (BOOL) i { iconic = i; }
- (void) set_skip_pager: (BOOL) s { skip_pager = s; }
- (void) set_skip_taskbar: (BOOL) s { skip_taskbar = s; }
- (void) set_fullscreen: (BOOL) f { fullscreen = f; }
- (void) set_above: (BOOL) a { above = a; }
- (void) set_below: (BOOL) b { below = b; }
- (void) set_max_horz: (BOOL) m { max_horz = m; }
- (void) set_max_vert: (BOOL) m { max_vert = m; }
- (void) set_matched: (BOOL) m { matched = m; }
- (void) dealloc
{
  DESTROY(iden);
  DESTROY(name);
  DESTROY(class);
  DESTROY(role);
  [super dealloc];
}

@end

#ifndef USE_SM

void session_startup(int argc, char **argv) {}
void session_shutdown(BOOL permanent) {}
AZSessionState *session_state_find(AZClient *c) { return nil; }
BOOL session_state_cmp(AZSessionState *s, AZClient *c) { return NO; }

#else

#import "AZDock.h"
#import "AZDebug.h"
#import "AZClient.h"
#import <XWindowServerKit/XFunctions.h>
#import "openbox.h"
#include "prop.h"
#include "parse.h"

#include <time.h>
#include <errno.h>
#include <stdio.h>

#ifdef HAVE_UNISTD_H
#  include <sys/types.h>
#  include <unistd.h>
#endif

#include <X11/SM/SMlib.h>

static BOOL    sm_disable;
static SmcConn     sm_conn;
static NSString      *save_file;
static NSString      *sm_id;
static int        sm_argc;
static char     **sm_argv;
static NSString      *sm_sessions_path;

static void session_load(NSString *path);
static BOOL session_save();

static void sm_save_yourself(SmcConn conn, SmPointer data, int save_type,
                             Bool shutdown, int interact_style, Bool fast);
static void sm_die(SmcConn conn, SmPointer data);
static void sm_save_complete(SmcConn conn, SmPointer data);
static void sm_shutdown_cancelled(SmcConn conn, SmPointer data);

static void save_commands()
{
    SmProp *props[2];
    SmProp prop_cmd = { SmCloneCommand, SmLISTofARRAY8, 1, };
    SmProp prop_res = { SmRestartCommand, SmLISTofARRAY8, };
    int i;

    prop_cmd.vals = calloc(sizeof(SmPropValue), sm_argc);
    prop_cmd.num_vals = sm_argc;
    for (i = 0; i < sm_argc; ++i) {
        prop_cmd.vals[i].value = sm_argv[i];
        prop_cmd.vals[i].length = strlen(sm_argv[i]);
    }

    prop_res.vals = calloc(sizeof(SmPropValue), sm_argc + 2);
    prop_res.num_vals = sm_argc + 2;
    for (i = 0; i < sm_argc; ++i) { 
        prop_res.vals[i].value = sm_argv[i];
        prop_res.vals[i].length = strlen(sm_argv[i]);
    }

    prop_res.vals[i].value = "--sm-save-file";
    prop_res.vals[i++].length = strlen("--sm-save-file");
    prop_res.vals[i].value = (char*)[save_file fileSystemRepresentation];
    prop_res.vals[i++].length = strlen([save_file fileSystemRepresentation]);

    props[0] = &prop_res;
    props[1] = &prop_cmd;
    SmcSetProperties(sm_conn, 2, props);

    free(prop_res.vals);
    free(prop_cmd.vals);
}

static void remove_args(int *argc, char ***argv, int index, int num)
{
    int i;

    for (i = index; i < index + num; ++i)
        (*argv)[i] = (*argv)[i+num];
    *argc -= num;
}

static void parse_args(int *argc, char ***argv)
{
    int i;

    for (i = 1; i < *argc; ++i) {
        if (!strcmp((*argv)[i], "--sm-client-id")) {
            if (i == *argc - 1) /* no args left */
                NSLog(@"Error: --sm-client-id requires an argument\n");
            else {
		ASSIGN(sm_id, ([NSString stringWithCString: (*argv)[i+1]]));
                remove_args(argc, argv, i, 2);
                ++i;
            }
        } else if (!strcmp((*argv)[i], "--sm-save-file")) {
            if (i == *argc - 1) /* no args left */
                NSLog(@"Error: --sm-save-file requires an argument\n");
            else {
                ASSIGN(save_file, ([NSString stringWithCString: (*argv)[i+1]]));
                remove_args(argc, argv, i, 2);
                ++i;
            }
        } else if (!strcmp((*argv)[i], "--sm-disable")) {
            sm_disable = YES;
            remove_args(argc, argv, i, 1);
        }
    }
}

void session_startup(int argc, char **argv)
{
#define SM_ERR_LEN 1024

    SmcCallbacks cb;
    char sm_err[SM_ERR_LEN];
    int i;

    sm_argc = argc;
    sm_argv = malloc(sizeof(char*)*argc);
    for (i = 0; i < argc; ++i)
        sm_argv[i] = argv[i];

    parse_args(&sm_argc, &sm_argv);

    if (sm_disable)
    {
	free(sm_argv);
	sm_argv = NULL;
        return;
    }

    ASSIGN(sm_sessions_path, ([NSString pathWithComponents: [NSArray arrayWithObjects: XDGDataHomePath(), @"openbox", @"sessions", nil]]));
    if (!parse_mkdir_path(sm_sessions_path, 0700))
        NSLog(@"Warning: Unable to make directory '%@'", sm_sessions_path);

    session_saved_state = [[NSMutableArray alloc] init];

    if (save_file)
        session_load(save_file);
    else {
        NSString *filename;

        /* this algo is from metacity */
	filename = [NSString stringWithFormat: @"%d-%d-%u.obs", (int)time(NULL), (int)getpid(), random()];
	ASSIGN(save_file, [sm_sessions_path stringByAppendingPathComponent: filename]);
    }

    cb.save_yourself.callback = sm_save_yourself;
    cb.save_yourself.client_data = NULL;

    cb.die.callback = sm_die;
    cb.die.client_data = NULL;

    cb.save_complete.callback = sm_save_complete;
    cb.save_complete.client_data = NULL;

    cb.shutdown_cancelled.callback = sm_shutdown_cancelled;
    cb.shutdown_cancelled.client_data = NULL;

    char *_sm_id = (char*)[sm_id cString];
    sm_conn = SmcOpenConnection(NULL, NULL, 1, 0,
                                SmcSaveYourselfProcMask |
                                SmcDieProcMask |
                                SmcSaveCompleteProcMask |
                                SmcShutdownCancelledProcMask,
                                &cb, _sm_id, &_sm_id,
                                SM_ERR_LEN, sm_err);
    if (_sm_id)
      ASSIGN(sm_id, ([NSString stringWithCString: _sm_id]));
    else {
      [sm_id release];
      sm_id = nil;
    }

    if (sm_conn == NULL)
        AZDebug("Failed to connect to session manager: %s\n", sm_err);
    else {
        SmPropValue val_prog;
        SmPropValue val_uid;
        SmPropValue val_hint; 
        SmPropValue val_pri;
        SmPropValue val_pid;
        SmProp prop_prog = { SmProgram, SmARRAY8, 1, };
        SmProp prop_uid = { SmUserID, SmARRAY8, 1, };
        SmProp prop_hint = { SmRestartStyleHint, SmCARD8, 1, };
        SmProp prop_pid = { SmProcessID, SmARRAY8, 1, };
        SmProp prop_pri = { "_GSM_Priority", SmCARD8, 1, };
        SmProp *props[6];
        char hint, pri;
        char *pid;

        val_prog.value = sm_argv[0];
        val_prog.length = strlen(sm_argv[0]);

        val_uid.value = (char*)[NSUserName() cString];
        val_uid.length = strlen(val_uid.value);

        hint = SmRestartImmediately;
        val_hint.value = &hint;
        val_hint.length = 1;

	pid = (char*)[[NSString stringWithFormat: @"%ld", (long)getpid()] cString];
        val_pid.value = pid;
        val_pid.length = strlen(pid);

        /* priority with gnome-session-manager, low to run before other apps */
        pri = 20;
        val_pri.value = &pri;
        val_pri.length = 1;

        prop_prog.vals = &val_prog;
        prop_uid.vals = &val_uid;
        prop_hint.vals = &val_hint;
        prop_pid.vals = &val_pid;
        prop_pri.vals = &val_pri;

        props[0] = &prop_prog;
        props[1] = &prop_uid;
        props[2] = &prop_hint;
        props[3] = &prop_pid;
        props[4] = &prop_pri;

        SmcSetProperties(sm_conn, 5, props);

        save_commands();
    }
}

void session_shutdown()
{
    if (sm_disable)
      return;

    DESTROY(sm_sessions_path);
    DESTROY(save_file);
    DESTROY(sm_id);
    free(sm_argv);
    sm_argv = NULL;

    if (sm_conn) {
        /* if permanent is true then we will change our session state so that
           the SM won't run us again */
        if (permanent) {
            SmPropValue val_hint;
            SmProp prop_hint = { SmRestartStyleHint, SmCARD8, 1, };
            SmProp *props[1];
            unsigned long hint;

            /* when we exit, we want to reset this to a more friendly state */
            hint = SmRestartIfRunning;
            val_hint.value = &hint;
            val_hint.length = 1;

            prop_hint.vals = &val_hint;

            props[0] = &prop_hint;

            SmcSetProperties(sm_conn, 1, props);
        }

        SmcCloseConnection(sm_conn, 0, NULL);

	DESTROY(session_saved_state);
    }
}

static void sm_save_yourself_phase2(SmcConn conn, SmPointer data)
{
    BOOL success;

    success = session_save();
    save_commands();

    SmcSaveYourselfDone(conn, success);
}

static void sm_save_yourself(SmcConn conn, SmPointer data, int save_type,
                             Bool shutdown, int interact_style, Bool fast)
{
    if (!SmcRequestSaveYourselfPhase2(conn, sm_save_yourself_phase2, data)) {
        AZDebug("SAVE YOURSELF PHASE 2 failed\n");
        SmcSaveYourselfDone(conn, NO);
    }
}

static void sm_die(SmcConn conn, SmPointer data)
{
    ob_exit(0);
}

static void sm_save_complete(SmcConn conn, SmPointer data)
{
}

static void sm_shutdown_cancelled(SmcConn conn, SmPointer data)
{
}

static BOOL session_save()
{
    FILE *f;
    BOOL success = YES;
    int i, count = [[AZStacking stacking] count];

    f = fopen([save_file fileSystemRepresentation], "w");
    if (!f) {
        success = NO;
        NSLog(@"Warning: unable to save the session to %@", save_file);
    } else {
        unsigned int stack_pos = 0;

        fprintf(f, "<?xml version=\"1.0\"?>\n\n");
        fprintf(f, "<openbox_session id=\"%s\">\n\n", [sm_id cString]);

	for (i = 0; i < count; i++) {
	    id <AZWindow> temp = [[AZStacking stacking] windowAtIndex: i];
            int prex, prey, prew, preh;
            AZClient *c;
            char *t;

            if (WINDOW_IS_CLIENT(temp))
                c = (AZClient *)temp;
            else
                continue;

            if (![c normal])
                continue;

            if (![c sm_client_id])
                continue;

            prex = [c area].x;
            prey = [c area].y;
            prew = [c area].width;
            preh = [c area].height;
            if ([c fullscreen]) {
                prex = [c pre_fullscreen_area].x;
                prey = [c pre_fullscreen_area].x;
                prew = [c pre_fullscreen_area].width;
                preh = [c pre_fullscreen_area].height;
            }
            if ([c max_horz]) {
                prex = [c pre_max_area].x;
                prew = [c pre_max_area].width;
            }
            if ([c max_vert]) {
                prey = [c pre_max_area].y;
                preh = [c pre_max_area].height;
            }

            fprintf(f, "<window id=\"%s\">\n", (char*)[[c sm_client_id] cString]);

	    t = (char*)[[[c name] stringByEscapingXML] cString];
            fprintf(f, "\t<name>%s</name>\n", t);

	    t = (char*)[[[c class] stringByEscapingXML] cString];
            fprintf(f, "\t<class>%s</class>\n", t);

	    t = (char*)[[[c role] stringByEscapingXML] cString];
            fprintf(f, "\t<role>%s</role>\n", t);

            fprintf(f, "\t<desktop>%d</desktop>\n", [c desktop]);
            fprintf(f, "\t<stacking>%d</stacking>\n", stack_pos);
            fprintf(f, "\t<x>%d</x>\n", prex);
            fprintf(f, "\t<y>%d</y>\n", prey);
            fprintf(f, "\t<width>%d</width>\n", prew);
            fprintf(f, "\t<height>%d</height>\n", preh);
            if ([c shaded])
                fprintf(f, "\t<shaded />\n");
            if ([c iconic])
                fprintf(f, "\t<iconic />\n");
            if ([c skip_pager])
                fprintf(f, "\t<skip_pager />\n");
            if ([c skip_taskbar])
                fprintf(f, "\t<skip_taskbar />\n");
            if ([c fullscreen])
                fprintf(f, "\t<fullscreen />\n");
            if ([c above])
                fprintf(f, "\t<above />\n");
            if ([c below])
                fprintf(f, "\t<below />\n");
            if ([c max_horz])
                fprintf(f, "\t<max_horz />\n");
            if ([c max_vert])
                fprintf(f, "\t<max_vert />\n");
            fprintf(f, "</window>\n\n");

            ++stack_pos;
        }

        fprintf(f, "</openbox_session>\n");

        if (fflush(f)) {
            success = NO;
            NSLog(@"Warning: error while saving the session to %@", save_file);
        }
        fclose(f);
    }

    return success;
}

BOOL session_state_cmp(AZSessionState *s, AZClient *c)
{
    return ([c sm_client_id] &&
            [[s identifier] isEqualToString: [c sm_client_id]] &&
            [[s name] isEqualToString: [c name]] &&
            [[s class] isEqualToString: [c class]] &&
            [[s role] isEqualToString: [c role]]);
    /* Considering nil == nil ? */
}

AZSessionState *session_state_find(AZClient *c)
{
    int i, count = [session_saved_state count];
    AZSessionState *s = nil;
    for (i = 0; i < count; i++) {
        s = [session_saved_state objectAtIndex: i];
        if (![s matched] && session_state_cmp(s, c)) {
            [s set_matched: YES];
	    return s;
        }
    }
    return nil;
}

static void session_load(NSString *path)
{
    xmlDocPtr doc;
    xmlNodePtr node, n;
    NSString *id;

    if (!parse_load(path, "openbox_session", &doc, &node))
        return;

    if (!parse_attr_string("id", node, &id))
        return;

    [sm_id release];
    sm_id = [id copy];

    node = parse_find_node("window", node->children);
    while (node) {
        AZSessionState *state = [[AZSessionState alloc] init];

	NSString *_id;
        if (!parse_attr_string("id", node, &_id)) {
            goto session_load_bail;
	} else {
	  [state set_identifier: _id];
	}

        if (!(n = parse_find_node("name", node->children)))
            goto session_load_bail;
        [state set_name: parse_string(doc, n)];

        if (!(n = parse_find_node("class", node->children)))
            goto session_load_bail;
        [state set_class: parse_string(doc, n)];

        if (!(n = parse_find_node("role", node->children)))
            goto session_load_bail;
        [state set_role: parse_string(doc, n)];

        if (!(n = parse_find_node("stacking", node->children)))
            goto session_load_bail;
        [state set_stacking: parse_int(doc, n)];

        if (!(n = parse_find_node("desktop", node->children)))
            goto session_load_bail;
        [state set_desktop: parse_int(doc, n)];

        if (!(n = parse_find_node("x", node->children)))
            goto session_load_bail;
        [state set_x: parse_int(doc, n)];

        if (!(n = parse_find_node("y", node->children)))
            goto session_load_bail;
        [state set_y: parse_int(doc, n)];

        if (!(n = parse_find_node("width", node->children)))
            goto session_load_bail;
        [state set_w: parse_int(doc, n)];

        if (!(n = parse_find_node("height", node->children)))
            goto session_load_bail;
        [state set_h: parse_int(doc, n)];

        [state set_shaded: 
            parse_find_node("shaded", node->children) != NULL];
        [state set_iconic:
            parse_find_node("iconic", node->children) != NULL];
        [state set_skip_pager:
            parse_find_node("skip_pager", node->children) != NULL];
        [state set_skip_taskbar:
            parse_find_node("skip_taskbar", node->children) != NULL];
        [state set_fullscreen:
            parse_find_node("fullscreen", node->children) != NULL];
        [state set_above:
            parse_find_node("above", node->children) != NULL];
        [state set_below:
            parse_find_node("below", node->children) != NULL];
        [state set_max_horz:
            parse_find_node("max_horz", node->children) != NULL];
        [state set_max_vert:
            parse_find_node("max_vert", node->children) != NULL];
        
        /* save this */
	[session_saved_state addObject: state];
	[state release];
	state = NULL;
        goto session_load_ok;

    session_load_bail:
        [state dealloc];
	state = NULL;

    session_load_ok:

        node = parse_find_node("window", node->next);
    }

    /* sort them by their stacking order */
    [session_saved_state sortUsingSelector: @selector(compareStacking:)];
    xmlFreeDoc(doc);
}

#endif
