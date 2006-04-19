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

#ifndef USE_SM

#import "session.h"

GList *session_saved_state;

void session_startup(int *argc, gchar ***argv) {}
void session_shutdown() {}
GList* session_state_find(AZClient *c) { return NULL; }
BOOL session_state_cmp(ObSessionState *s, AZClient *c) { return NO; }
void session_state_free(ObSessionState *state) {}

#else

#import "AZDock.h"
#import "AZDebug.h"
#import "AZClient.h"
#include "openbox.h"
#include "session.h"
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

GList *session_saved_state;

static BOOL    sm_disable;
static SmcConn     sm_conn;
static gchar      *save_file;
static gchar      *sm_id;
static int        sm_argc;
static gchar     **sm_argv;
static gchar      *sm_sessions_path;

static void session_load(gchar *path);
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
    prop_res.vals[i].value = save_file;
    prop_res.vals[i++].length = strlen(save_file);

    props[0] = &prop_res;
    props[1] = &prop_cmd;
    SmcSetProperties(sm_conn, 2, props);

    free(prop_res.vals);
    free(prop_cmd.vals);
}

static void remove_args(int *argc, gchar ***argv, int index, int num)
{
    int i;

    for (i = index; i < index + num; ++i)
        (*argv)[i] = (*argv)[i+num];
    *argc -= num;
}

static void parse_args(int *argc, gchar ***argv)
{
    int i;

    for (i = 1; i < *argc; ++i) {
        if (!strcmp((*argv)[i], "--sm-client-id")) {
            if (i == *argc - 1) /* no args left */
                g_printerr(("--sm-client-id requires an argument\n"));
            else {
                sm_id = g_strdup((*argv)[i+1]);
                remove_args(argc, argv, i, 2);
                ++i;
            }
        } else if (!strcmp((*argv)[i], "--sm-save-file")) {
            if (i == *argc - 1) /* no args left */
                g_printerr(("--sm-save-file requires an argument\n"));
            else {
                save_file = g_strdup((*argv)[i+1]);
                remove_args(argc, argv, i, 2);
                ++i;
            }
        } else if (!strcmp((*argv)[i], "--sm-disable")) {
            sm_disable = YES;
            remove_args(argc, argv, i, 1);
        }
    }
}

void session_startup(int *argc, gchar ***argv)
{
#define SM_ERR_LEN 1024

    SmcCallbacks cb;
    gchar sm_err[SM_ERR_LEN];

    parse_args(argc, argv);

    if (sm_disable)
        return;

    sm_sessions_path = g_build_filename((char*)[parse_xdg_data_home_path() cString],
                                        "openbox", "sessions", NULL);
    if (!parse_mkdir_path(sm_sessions_path, 0700))
        g_warning(("Unable to make directory '%s': %s"),
                  sm_sessions_path, g_strerror(errno));

    if (save_file)
        session_load(save_file);
    else {
        gchar *filename;

        /* this algo is from metacity */
        filename = g_strdup_printf("%d-%d-%u.obs",
                                   (int) time(NULL),
                                   (int) getpid(),
                                   g_random_int());
        save_file = g_build_filename(sm_sessions_path, filename, NULL);
        free(filename);
    }

    sm_argc = *argc;
    sm_argv = *argv;

    cb.save_yourself.callback = sm_save_yourself;
    cb.save_yourself.client_data = NULL;

    cb.die.callback = sm_die;
    cb.die.client_data = NULL;

    cb.save_complete.callback = sm_save_complete;
    cb.save_complete.client_data = NULL;

    cb.shutdown_cancelled.callback = sm_shutdown_cancelled;
    cb.shutdown_cancelled.client_data = NULL;

    sm_conn = SmcOpenConnection(NULL, NULL, 1, 0,
                                SmcSaveYourselfProcMask |
                                SmcDieProcMask |
                                SmcSaveCompleteProcMask |
                                SmcShutdownCancelledProcMask,
                                &cb, sm_id, &sm_id,
                                SM_ERR_LEN, sm_err);
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
        gchar hint, pri;
        gchar pid[32];

        val_prog.value = sm_argv[0];
        val_prog.length = strlen(sm_argv[0]);

        val_uid.value = g_strdup(g_get_user_name());
        val_uid.length = strlen(val_uid.value);

        hint = SmRestartImmediately;
        val_hint.value = &hint;
        val_hint.length = 1;

        g_snprintf(pid, sizeof(pid), "%ld", (glong) getpid());
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

        free(val_uid.value);

        save_commands();
    }
}

void session_shutdown()
{
    free(sm_sessions_path);
    free(save_file);
    free(sm_id);

    if (sm_conn) {
        SmPropValue val_hint;
        SmProp prop_hint = { SmRestartStyleHint, SmCARD8, 1, };
        SmProp *props[1];
        gulong hint;

        /* when we exit, we want to reset this to a more friendly state */
        hint = SmRestartIfRunning;
        val_hint.value = &hint;
        val_hint.length = 1;

        prop_hint.vals = &val_hint;

        props[0] = &prop_hint;

        SmcSetProperties(sm_conn, 1, props);

        SmcCloseConnection(sm_conn, 0, NULL);

        while (session_saved_state) {
            session_state_free(session_saved_state->data);
            session_saved_state = g_list_delete_link(session_saved_state,
                                                     session_saved_state);
        }
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
    //GList *it;
    BOOL success = YES;
    int i, count = [[AZStacking stacking] count];

    f = fopen(save_file, "w");
    if (!f) {
        success = NO;
        g_warning("unable to save the session to %s: %s",
                  save_file, g_strerror(errno));
    } else {
        unsigned int stack_pos = 0;

        fprintf(f, "<?xml version=\"1.0\"?>\n\n");
        fprintf(f, "<openbox_session id=\"%s\">\n\n", sm_id);

	for (i = 0; i < count; i++) {
	    id <AZWindow> temp = [[AZStacking stacking] windowAtIndex: i];
            int prex, prey, prew, preh;
            AZClient *c;
            gchar *t;

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

            t = g_markup_escape_text((char*)[[c name] cString], -1);
            fprintf(f, "\t<name>%s</name>\n", t);
            free(t);

            t = g_markup_escape_text((char*)[[c class] cString], -1);
            fprintf(f, "\t<class>%s</class>\n", t);
            free(t);

            t = g_markup_escape_text((char*)[[c role] cString], -1);
            fprintf(f, "\t<role>%s</role>\n", t);
            free(t);

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
            g_warning("error while saving the session to %s: %s",
                      save_file, g_strerror(errno));
        }
        fclose(f);
    }

    return success;
}

void session_state_free(ObSessionState *state)
{
    if (state) {
        DESTROY(state->id);
        DESTROY(state->name);
        DESTROY(state->class);
        DESTROY(state->role);

        free(state);
    }
}

BOOL session_state_cmp(ObSessionState *s, AZClient *c)
{
    return ([c sm_client_id] &&
            [s->id isEqualToString: [c sm_client_id]] &&
            [s->name isEqualToString: [c name]] &&
            [s->class isEqualToString: [c class]] &&
            [s->role isEqualToString: [c role]]);
    /* Considering nil == nil ? */
}

GList* session_state_find(AZClient *c)
{
    GList *it;

    for (it = session_saved_state; it; it = g_list_next(it)) {
        ObSessionState *s = it->data;
        if (!s->matched && session_state_cmp(s, c)) {
            s->matched = YES;
            break;
        }
    }
    return it;
}

static int stack_sort(const ObSessionState *s1, const ObSessionState *s2)
{
    return s1->stacking - s2->stacking;
}

static void session_load(gchar *path)
{
    xmlDocPtr doc;
    xmlNodePtr node, n;
    NSString *id;

    if (!parse_load([NSString stringWithCString: path], "openbox_session", &doc, &node))
        return;

    if (!parse_attr_string("id", node, &id))
        return;

    free(sm_id);
    sm_id = g_strdup([id cString]);

    node = parse_find_node("window", node->children);
    while (node) {
        ObSessionState *state;

        state = calloc(sizeof(ObSessionState), 1);

	NSString *_id;
        if (!parse_attr_string("id", node, &_id)) {
            goto session_load_bail;
	} else {
	  if (state->id) {
	    [state->id release];
	    state->id = NULL;
	  }
	  state->id = [_id copy];
	}
        if (!(n = parse_find_node("name", node->children)))
            goto session_load_bail;
	if (state->name) {
	  [state->name release];
	  state->name = NULL;
	}
        state->name = [parse_string(doc, n) copy];
        if (!(n = parse_find_node("class", node->children)))
            goto session_load_bail;
	if (state->class) {
	  [state->class release];
	  state->class = NULL;
	}
        state->class = [parse_string(doc, n) copy];
        if (!(n = parse_find_node("role", node->children)))
            goto session_load_bail;
	if (state->role) {
	  [state->role release];
	  state->role = NULL;
	}
        state->role = [parse_string(doc, n) copy];
        if (!(n = parse_find_node("stacking", node->children)))
            goto session_load_bail;
        state->stacking = parse_int(doc, n);
        if (!(n = parse_find_node("desktop", node->children)))
            goto session_load_bail;
        state->desktop = parse_int(doc, n);
        if (!(n = parse_find_node("x", node->children)))
            goto session_load_bail;
        state->x = parse_int(doc, n);
        if (!(n = parse_find_node("y", node->children)))
            goto session_load_bail;
        state->y = parse_int(doc, n);
        if (!(n = parse_find_node("width", node->children)))
            goto session_load_bail;
        state->w = parse_int(doc, n);
        if (!(n = parse_find_node("height", node->children)))
            goto session_load_bail;
        state->h = parse_int(doc, n);

        state->shaded =
            parse_find_node("shaded", node->children) != NULL;
        state->iconic =
            parse_find_node("iconic", node->children) != NULL;
        state->skip_pager =
            parse_find_node("skip_pager", node->children) != NULL;
        state->skip_taskbar =
            parse_find_node("skip_taskbar", node->children) != NULL;
        state->fullscreen =
            parse_find_node("fullscreen", node->children) != NULL;
        state->above =
            parse_find_node("above", node->children) != NULL;
        state->below =
            parse_find_node("below", node->children) != NULL;
        state->max_horz =
            parse_find_node("max_horz", node->children) != NULL;
        state->max_vert =
            parse_find_node("max_vert", node->children) != NULL;
        
        /* save this */
        session_saved_state = g_list_prepend(session_saved_state, state);
        goto session_load_ok;

    session_load_bail:
        session_state_free(state);

    session_load_ok:

        node = parse_find_node("window", node->next);
    }

    /* sort them by their stacking order */
    session_saved_state = g_list_sort(session_saved_state,
                                      (GCompareFunc)stack_sort);

    xmlFreeDoc(doc);
}

#endif
