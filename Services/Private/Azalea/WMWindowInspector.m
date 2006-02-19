#include "WMWindowInspector.h"
#include "WMApplication.h"
#include "WMDefaults.h"
#include "WMDialogController.h"
#include "screen.h"
#include "framewin.h"
#include "appicon.h"
#include "dock.h"
#include "workspace.h"
#include "WindowMaker.h"
#include <X11/Xlib.h>
#include <X11/cursorfont.h>

extern WPreferences wPreferences;
extern Cursor wCursor[WCUR_LAST];
extern Display *dpy;

static WMWindowInspector *sharedInspector;

static NSString *WMWindowSpecificationItem = @"WMWindowSpecificationItem";
static NSString *WMAttributesItem = @"WMAttributesItem";
static NSString *WMAdvancedOptionsItem = @"WMAdvancedOptionsItem";
static NSString *WMIconAndInitialWorkspaceItem = @"WMIconAndInitialWorkspaceItem";
static NSString *WMApplicationSpecificItem = @"WMApplicationSpecificItem";

#define USE_TEXT_FIELD		1
#define UPDATE_TEXT_FIELD	2
#define REVERT_TO_DEFAULT	4

#define UPDATE_DEFAULTS		1
#define IS_BOOLEAN		2

@interface WMWindowInspector (WMPrivate)

- (void) removeIconForApplication: (WApplication *) wapp;
- (void) makeIconForApplication: (WApplication *) wapp;
- (int) showIconForInstance: (char *) wm_instance class: (char *) wm_class
		     screen: (WScreen *) scr flag: (int) flags;
- (int) insertAttribute: (NSString *) attr
		  value: (id) value
		   into: (NSMutableDictionary *) window
		   flag: (int) flags;

/* Interface */
- (void) createInterface;
- (NSTabViewItem *) createItem1;
- (NSTabViewItem *) createItem2;
- (NSTabViewItem *) createItem3;
- (NSTabViewItem *) createItem4;
- (NSTabViewItem *) createItem5;

- (void) readAttributesFromWindow: (WWindow *) wwin;
- (void) updateInterfaceForWindow: (WWindow *) wwin;

/* tabitem 1 */
- (void) selectWindow: (id) sender;
- (void) targetButtonsAction: (id) sender;

/* tabitem 2 */
- (void) attrButtonsAction: (id) sender;

/* tabitem 3 */
- (void) advanButtonsAction: (id) sender;

/* tabitem 4 */
- (void) iconFieldAction: (id) sender;
- (void) browseButtonAction: (id) sender;
- (void) ignoreIconButtonAction: (id) sender;
- (void) workspaceButtonAction: (id) sender;

/* tabitem 5 */
- (void) appButtonsAdction: (id) sender;

@end

@implementation WMWindowInspector

+ (WMWindowInspector *) sharedWindowInspector
{
  if (sharedInspector == nil)
  {
    sharedInspector = [[WMWindowInspector alloc] init];
  }
  return sharedInspector;
}

- (id) init
{
  self = [super init];

  [self createInterface];

  return self;
}

- (void) dealloc
{
  inspectedWin = NULL;
  DESTROY(tabView);
  DESTROY(reloadButton);
  DESTROY(applyButton);
  DESTROY(saveButton);
  DESTROY(targetButtons);
  DESTROY(attrButtons);
  DESTROY(advanButtons);
  DESTROY(appButtons);
  DESTROY(wsButtons);
  [super dealloc];
}

- (void) setWindow: (WWindow *) wwin
{
  inspectedWin = wwin;
 
  if (wwin)
  {
    [self readAttributesFromWindow: wwin];
    [self updateInterfaceForWindow: wwin];

    /* disable save if noupdates */
    if (wPreferences.flags.noupdates || !(wwin->wm_class || wwin->wm_instance))
    {
      [saveButton setEnabled: NO];
    }
  }
}

- (WWindow *) window
{
  return inspectedWin;
}

/* Action */

/* selectWindow() from winspector.c */
- (void) selectWindow: (id) sender
{
  int screen = WMCurrentScreen();
  WScreen *scr = wScreenWithScreenNumber(screen);
  if (scr)
  {
    WWindow *iwin;
    XEvent event;

    if (XGrabPointer(dpy, scr->root_win, True,
                   ButtonPressMask, GrabModeAsync, GrabModeAsync, None,
                   wCursor[WCUR_SELECT], CurrentTime)!=GrabSuccess) 
    {
      NSLog(@"could not grab mouse pointer");
      return;
    }

    //WMSetLabelText(panel->specLbl, ("Click in the window you wish to inspect."));

    WMMaskEvent(dpy, ButtonPressMask, &event);

    XUngrabPointer(dpy, CurrentTime);

    iwin = wWindowFor(event.xbutton.subwindow);

    if (iwin && !iwin->flags.internal_window /* && iwin != wwin */
        /*&& !iwin->flags.inspector_open*/) 
    {
      [self setWindow: iwin];
    } 
    else
    {
      [self setWindow: NULL];
#if 0 // FIXME: doesn't work
      WMSetLabelText(panel->specLbl, spec_text);
#endif
    }
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}

/** from revertSettings() in winspector.c */
- (void) reloadButtonAction: (id) sender
{
  WWindow *wwin = inspectedWin;
  WApplication *wapp = wApplicationOf(wwin->main_window);
  int i, n, flag = 0;
  char *wm_instance = NULL;
  char *wm_class = NULL;
  int workspace, level;

  if ([[targetButtons objectAtIndex: 2] state] == NSOnState)
    wm_instance = wwin->wm_instance;
  else if ([[targetButtons objectAtIndex: 1] state] == NSOnState)
    wm_class = wwin->wm_class;
  else if ([[targetButtons objectAtIndex: 0] state] == NSOnState) {
    wm_instance = wwin->wm_instance;
    wm_class = wwin->wm_class;
  }

  memset(&wwin->defined_user_flags, 0, sizeof(WWindowAttributes));
  memset(&wwin->user_flags, 0, sizeof(WWindowAttributes));
  memset(&wwin->client_flags, 0, sizeof(WWindowAttributes));

  wWindowSetupInitialAttributes(wwin, &level, &workspace);

  for (i=0; i < [attrButtons count]; i++) {
    flag = 0;
    switch (i) {
      case 0:
        flag = WFLAGP(wwin, no_titlebar);
        break;
      case 1:
        flag = WFLAGP(wwin, no_resizebar);
        break;
      case 2:
        flag = WFLAGP(wwin, no_close_button);
        break;
      case 3:
        flag = WFLAGP(wwin, no_miniaturize_button);
        break;
      case 4:
        flag = WFLAGP(wwin, no_border);
        break;
      case 5:
        flag = WFLAGP(wwin, floating);
        break;
      case 6:
        flag = WFLAGP(wwin, sunken);
        break;
      case 7:
        flag = WFLAGP(wwin, omnipresent);
        break;
      case 8:
        flag = WFLAGP(wwin, start_miniaturized);
        break;
      case 9:
        flag = WFLAGP(wwin, start_maximized!=0);
        break;
      case 10:
        flag = WFLAGP(wwin, full_maximize);
        break;
      }
    [[attrButtons objectAtIndex: i] setState: (flag ? NSOnState : NSOffState)];
  }

  for (i=0; i < [advanButtons count]; i++) {
    flag = 0;
    switch (i) {
      case 0:
        flag = WFLAGP(wwin, no_bind_keys);
        break;
      case 1:
        flag = WFLAGP(wwin, no_bind_mouse);
        break;
      case 2:
        flag = WFLAGP(wwin, skip_window_list);
        break;
      case 3:
        flag = WFLAGP(wwin, no_focusable);
        break;
      case 4:
        flag = WFLAGP(wwin, dont_move_off);
        break;
      case 5:
        flag = WFLAGP(wwin, no_hide_others);
        break;
      case 6:
        flag = WFLAGP(wwin, dont_save_session);
        break;
      case 7:
        flag = WFLAGP(wwin, emulate_appicon);
        break;
#ifdef XKB_BUTTON_HINT
      case 8:
        flag = WFLAGP(wwin, no_language_button);
        break;
#endif
    }
    [[advanButtons objectAtIndex: i] setState: (flag ? NSOnState: NSOffState)];
  }

  if (wapp) {
    for (i=0; i < [appButtons count]; i++) {
      flag = 0;

      switch (i) {
        case 0:
          flag = WFLAGP(wapp->main_window_desc, start_hidden);
          break;
        case 1:
          flag = WFLAGP(wapp->main_window_desc, no_appicon);
          break;
        case 2:
          flag = WFLAGP(wapp->main_window_desc, shared_appicon);
          break;
      }
    [[appButtons objectAtIndex: i] setState: (flag ? NSOnState : NSOffState)];
    }
  }

  flag = WFLAGP(wwin, always_user_icon);
  [ignoreIconButton setState: (flag ? NSOnState : NSOffState)];

  [self showIconForInstance: wm_instance class: wm_class
			screen: wwin->screen_ptr flag: REVERT_TO_DEFAULT];
#if 0 //FIXME
  showIconFor(WMWidgetScreen(panel->alwChk), panel, wm_instance, wm_class,
		                REVERT_TO_DEFAULT);
#endif

  n = wDefaultGetStartWorkspace(wwin->screen_ptr, wm_instance, wm_class);

  if (n >= 0 && n < wwin->screen_ptr->workspace_count) {
    if (n == wwin->screen_ptr->current_workspace) {
      [self workspaceButtonAction: [wsButtons objectAtIndex: 1]];
    }
    [self workspaceButtonAction: [wsButtons objectAtIndex: 2]];
    /* store workspace as tag */
    [[wsButtons objectAtIndex: 2] setTag: n];
  } else {
    [self workspaceButtonAction: [wsButtons objectAtIndex: 0]];
  }

  /* must auto apply, so that there wno't be internal
   * inconsistencies between the state in the flags and
   * the actual state of the window */
  [self applyButtonAction: self];
}

- (void) applyButtonAction: (id) sender
{
  WWindow *wwin = inspectedWin;
  WApplication *wapp = wApplicationOf(wwin->main_window);
  int floating, sunken, skip_window_list;
  int old_omnipresent;
  int old_no_bind_keys;
  int old_no_bind_mouse;

  old_omnipresent = WFLAGP(wwin, omnipresent);
  old_no_bind_keys = WFLAGP(wwin, no_bind_keys);
  old_no_bind_mouse = WFLAGP(wwin, no_bind_mouse);

  [self showIconForInstance: NULL class: NULL 
			screen: wwin->screen_ptr flag: USE_TEXT_FIELD];
#if 0 // FIXME: not used
  showIconFor(WMWidgetScreen(button), panel, NULL, NULL, USE_TEXT_FIELD);
#endif

  WSETUFLAG(wwin, no_titlebar, [[attrButtons objectAtIndex: 0] state]);
  WSETUFLAG(wwin, no_resizebar, [[attrButtons objectAtIndex: 1] state]);
  WSETUFLAG(wwin, no_close_button, [[attrButtons objectAtIndex: 2] state]);
  WSETUFLAG(wwin, no_miniaturize_button, [[attrButtons objectAtIndex: 3] state]);
  WSETUFLAG(wwin, no_border, [[attrButtons objectAtIndex: 4] state]);
  floating = [[attrButtons objectAtIndex: 5] state];
  sunken   = [[attrButtons objectAtIndex: 6] state];
  WSETUFLAG(wwin, omnipresent, [[attrButtons objectAtIndex: 7] state]);
  WSETUFLAG(wwin, start_miniaturized, [[attrButtons objectAtIndex: 8] state]);  
  WSETUFLAG(wwin, start_maximized, [[attrButtons objectAtIndex: 9] state]);
  WSETUFLAG(wwin, full_maximize, [[attrButtons objectAtIndex: 10] state]);

  WSETUFLAG(wwin, no_bind_keys, [[advanButtons objectAtIndex: 0] state]);
  WSETUFLAG(wwin, no_bind_mouse, [[advanButtons objectAtIndex: 1] state]);
  skip_window_list = [[advanButtons objectAtIndex: 2] state];
  WSETUFLAG(wwin, no_focusable, [[advanButtons objectAtIndex: 3] state]);
  WSETUFLAG(wwin, dont_move_off, [[advanButtons objectAtIndex: 4] state]);
  WSETUFLAG(wwin, no_hide_others, [[advanButtons objectAtIndex: 5] state]);
  WSETUFLAG(wwin, dont_save_session, [[advanButtons objectAtIndex: 6] state]);
  WSETUFLAG(wwin, emulate_appicon, [[advanButtons objectAtIndex: 7] state]);
#ifdef XKB_BUTTON_HINT
  WSETUFLAG(wwin, no_language_button, [[advanButtons objectAtIndex: 8] state]);
#endif

  WSETUFLAG(wwin, always_user_icon, [ignoreIconButton state]);

  if (WFLAGP(wwin, no_titlebar) && wwin->flags.shaded)
    wUnshadeWindow(wwin);
  WSETUFLAG(wwin, no_shadeable, WFLAGP(wwin, no_titlebar));

  if (floating) {
    if (!WFLAGP(wwin, floating))
      ChangeStackingLevel(wwin->frame->core, WMFloatingLevel);
  } else if (sunken) {
    if (!WFLAGP(wwin, sunken))
      ChangeStackingLevel(wwin->frame->core, WMSunkenLevel);
  } else {
    if (WFLAGP(wwin, floating) || WFLAGP(wwin, sunken))
      ChangeStackingLevel(wwin->frame->core, WMNormalLevel);
  }

  WSETUFLAG(wwin, sunken, sunken);
  WSETUFLAG(wwin, floating, floating);
  wwin->flags.omnipresent = 0;

  if (WFLAGP(wwin, skip_window_list) != skip_window_list) {
    WSETUFLAG(wwin, skip_window_list, skip_window_list);
    UpdateSwitchMenu(wwin->screen_ptr, wwin,
                     skip_window_list ? ACTION_REMOVE : ACTION_ADD);
  } else {
    if (WFLAGP(wwin, omnipresent) != old_omnipresent) {
      WMPostNotificationName(WMNChangedState, wwin, "omnipresent");
    }
  }

  if (WFLAGP(wwin, no_bind_keys) != old_no_bind_keys) {
    if (WFLAGP(wwin, no_bind_keys)) {
      XUngrabKey(dpy, AnyKey, AnyModifier, wwin->frame->core->window);
    } else {
      wWindowSetKeyGrabs(wwin);
    }
  }

  if (WFLAGP(wwin, no_bind_mouse) != old_no_bind_mouse) {
    wWindowResetMouseGrabs(wwin);
  }

  wwin->frame->flags.need_texture_change = 1;
  wWindowConfigureBorders(wwin);
  wFrameWindowPaint(wwin->frame);
#ifdef NETWM_HINTS
  wNETWMUpdateActions(wwin, False);
#endif

  /*
   * Can't apply emulate_appicon because it will probably cause problems.
   */

  if (wapp) {
    /* do application wide stuff */
    WSETUFLAG(wapp->main_window_desc, start_hidden,
              [[appButtons objectAtIndex: 0] state]);

    WSETUFLAG(wapp->main_window_desc, no_appicon,
              [[appButtons objectAtIndex: 1] state]);

    WSETUFLAG(wapp->main_window_desc, shared_appicon,
              [[appButtons objectAtIndex: 2] state]);

    if (WFLAGP(wapp->main_window_desc, no_appicon))
      [self removeIconForApplication: wapp];
    else
      [self makeIconForApplication: wapp];

#if 0 // FIXME
    if (wapp->app_icon && wapp->main_window == wwin->client_win) {
      char *file = WMGetTextFieldText(panel->fileText);

      if (file[0] == 0) {
        wfree(file);
        file = NULL;
      }

      wIconChangeImageFile(wapp->app_icon->icon, file);
      if (file)
        wfree(file);
      wAppIconPaint(wapp->app_icon);
    }
#endif
  }
}

- (void) saveButtonAction: (id) sender
{
  WWindow *wwin = inspectedWin;
  NSString *icon_file = nil;
  int flags = 0;
  int different = 0, different2 = 0;

  NSString *name = nil;
  NSMutableDictionary *winDic, *appDic;
  id value;
  WMDefaults *defaults = [WMDefaults sharedDefaults];

  /* Save will apply the changes and save them */
  [self applyButtonAction: applyButton];

  if ([[targetButtons objectAtIndex: 2] state] == NSOnState)
  {
    name = [NSString stringWithCString: wwin->wm_instance];
  }
  else if ([[targetButtons objectAtIndex: 1] state] == NSOnState)
  {
    name = [NSString stringWithCString: wwin->wm_class];
  }
  else if ([[targetButtons objectAtIndex: 0] state] == NSOnState)
  {
    name = [NSString stringWithFormat: @"%s.%s",
                     wwin->wm_instance, wwin->wm_class];
  } 
  else if ([[targetButtons objectAtIndex: 3] state] == NSOnState)
  {
    name = AUTORELEASE([[NSString alloc] initWithString: WAAnyWindow]);
    flags = UPDATE_DEFAULTS;
  } 
  else 
  {
    name = nil;
  }

  if (!name)
    return;

  if ([self showIconForInstance: NULL class: NULL screen: wwin->screen_ptr
		  flag: USE_TEXT_FIELD] < 0)
    return;

  winDic = AUTORELEASE([[NSMutableDictionary alloc] init]);
  appDic = AUTORELEASE([[NSMutableDictionary alloc] init]);

  /* Update icon for window */
  icon_file = [iconField stringValue];
  if (icon_file) {
    if ([icon_file length] != 0) {
      different |= [self insertAttribute: WAIcon value: icon_file into: winDic flag: flags];
      different2 |= [self insertAttribute: WAIcon value: icon_file into: appDic flag: flags];
    }
  }

  {
    if ([[wsButtons objectAtIndex: 2] state] == NSOnState)
    {
      /* Tag is workspace number */
      int tag = [[wsButtons objectAtIndex: 2] tag];
      if (tag >= 0 && tag < wwin->screen_ptr->workspace_count) {
        value = [NSString stringWithCString: wwin->screen_ptr->workspaces[tag]->name];
        different |= [self insertAttribute: WAStartWorkspace value: value into: winDic flag: flags];
      }
    }
    else if ([[wsButtons objectAtIndex: 1] state] == NSOnState)
    {
      value = [NSString stringWithCString: wwin->screen_ptr->workspaces[wwin->screen_ptr->current_workspace]->name];
      different |= [self insertAttribute: WAStartWorkspace value: value into: winDic flag: flags];
    }
    else if ([[wsButtons objectAtIndex: 0] state] == NSOnState)
    {
      /* Nowhere in particular */
    }
  }

  flags |= IS_BOOLEAN;

  value = ([ignoreIconButton state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WAAlwaysUserIcon value: value into: winDic flag: flags];

  value = ([[attrButtons objectAtIndex: 0] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WANoTitlebar value: value into: winDic flag: flags];

  value = ([[attrButtons objectAtIndex: 1] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WANoResizebar value: value into: winDic flag: flags];

  value = ([[attrButtons objectAtIndex: 2] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WANoCloseButton value: value into: winDic flag: flags];

  value = ([[attrButtons objectAtIndex: 3] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WANoMiniaturizeButton value: value into: winDic flag: flags];

  value = ([[attrButtons objectAtIndex: 4] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WANoBorder value: value into: winDic flag: flags];

  value = ([[attrButtons objectAtIndex: 5] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WAKeepOnTop value: value into: winDic flag: flags];

  value = ([[attrButtons objectAtIndex: 6] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WAKeepOnBottom value: value into: winDic flag: flags];

  value = ([[attrButtons objectAtIndex: 7] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WAOmnipresent value: value into: winDic flag: flags];

  value = ([[attrButtons objectAtIndex: 8] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WAStartMiniaturized value: value into: winDic flag: flags];

  value = ([[attrButtons objectAtIndex: 9] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WAStartMaximized value: value into: winDic flag: flags];

  value = ([[attrButtons objectAtIndex: 10] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WAFullMaximize value: value into: winDic flag: flags];

  value = ([[advanButtons objectAtIndex: 0] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WANoKeyBindings value: value into: winDic flag: flags];

  value = ([[advanButtons objectAtIndex: 1] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WANoMouseBindings value: value into: winDic flag: flags];

  value = ([[advanButtons objectAtIndex: 2] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WASkipWindowList value: value into: winDic flag: flags];

  value = ([[advanButtons objectAtIndex: 3] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WAUnfocusable value: value into: winDic flag: flags];

  value = ([[advanButtons objectAtIndex: 4] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WAKeepInsideScreen value: value into: winDic flag: flags];

  value = ([[advanButtons objectAtIndex: 5] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WANoHideOthers value: value into: winDic flag: flags];

  value = ([[advanButtons objectAtIndex: 6] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WADontSaveSession value: value into: winDic flag: flags];

  value = ([[advanButtons objectAtIndex: 7] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WAEmulateAppIcon value: value into: winDic flag: flags];

#ifdef XKB_BUTTON_HINT
  value = ([[advanButtons objectAtIndex: 8] state] == NSOnState) ? WAYes : WANo;
  different |= [self insertAttribute: WANoLanguageButton value: value into: winDic flag: flags];
#endif

  if (wwin->main_window!=None && wApplicationOf(wwin->main_window)!=NULL) {
    value = ([[appButtons objectAtIndex: 0] state] == NSOnState) ? WAYes : WANo;
    different2 |= [self insertAttribute: WAStartHidden value: value into: appDic flag: flags];

    value = ([[appButtons objectAtIndex: 1] state] == NSOnState) ? WAYes : WANo;
    different2 |= [self insertAttribute: WANoAppIcon value: value into: appDic flag: flags];

    value = ([[appButtons objectAtIndex: 2] state] == NSOnState) ? WAYes : WANo;
    different2 |= [self insertAttribute: WASharedAppIcon value: value into: appDic flag: flags];
  }

  if (wwin->fake_group) {
    NSString *key2 = [NSString stringWithCString: wwin->fake_group->identifier];
    if ([key2 isEqualToString: name]) {
      [winDic addEntriesFromDictionary: appDic];
      different |= different2;
    } else {
      [defaults removeWindow: key2];
      if (different2) {
        [defaults setAttributes: appDic window: key2];
      }
    }
  } else if (wwin->main_window != wwin->client_win) {
    WApplication *wapp = wApplicationOf(wwin->main_window);

    if (wapp) {
      char *instance = wapp->main_window_desc->wm_instance;
      char *class = wapp->main_window_desc->wm_class;
      NSString *key2 = [NSString stringWithFormat: @"%s.%s", instance, class];

      if ([key2 isEqualToString: name]) {
        [winDic addEntriesFromDictionary: appDic];
        different |= different2;
      } else {
        [defaults removeWindow: key2];
        if (different2) {
          [defaults setAttributes: appDic window: key2];
        }
      }
    }
  } else {
    [winDic addEntriesFromDictionary: appDic];
    different |= different2;
  }
  [defaults removeWindow: name];
  if (different) {
    [defaults setAttributes: winDic window: name];
  }

  [defaults synchronize];
}

/* Private */

- (void) readAttributesFromWindow: (WWindow *) wwin
{
  int i, flag;

  if (wPreferences.flags.noupdates || !(wwin->wm_class || wwin->wm_instance))
    [saveButton setEnabled: NO];

  if (wwin->wm_class && wwin->wm_instance) {
    NSLog(@"wm_class %s", wwin->wm_class);
    NSLog(@"wm_instance %s", wwin->wm_instance);
    /* FIXME: change interface to reflect the combination of 
     * wm_class && wm_instance, wm_class, and wm_instance.
     */
  }

  for (i = 0; i < 11; i++)
  {
    flag = 0;

    switch(i) {
      case 0:
	/** Remove the titlebar of this window.
	 * To access the window commands menu of a window
	 * without it's titlebar, press Control+Esc (or the
	 * equivalent shortcut, if you changed the default
	 * settings).
	 */
	flag = WFLAGP(wwin, no_titlebar);
	break;
      case 1:
	/** Remove the resizebar of this window. */
	flag = WFLAGP(wwin, no_resizebar);
	break;
      case 2:
	/** Remove the `close window' button of this window. */
	flag = WFLAGP(wwin, no_close_button);
	break;
      case 3:
	/** Remove the `miniaturize window' button of the window. */
	flag = WFLAGP(wwin, no_miniaturize_button);
	break;
      case 4:
	/** Remove the 1 pixel black border around the window. */
	flag = WFLAGP(wwin, no_border);
	break;
      case 5:
	/** Keep the window over other windows, not allowing
	 * them to cover it. */
	flag = WFLAGP(wwin, floating);
	break;
      case 6:
	/** Keep the window under all other windows */
	flag = WFLAGP(wwin, sunken);
	break;
      case 7:
	/** Make window present in all workspaces */
	flag = WFLAGP(wwin, omnipresent);
	break;
      case 8:
	/** Make the window be automatically minaturized when it's
	 * first shown. */
	flag = WFLAGP(wwin, start_miniaturized);
	break;
      case 9:
	/** Make the window be automatically maximized when it's
	 * first shown. */
	flag = WFLAGP(wwin, start_maximized!=0);
	break;
      case 10:
	/** Make the window use the whole screen space when it's
	 * maximized. The titlebar and resizebar will be moved
	 * to outside the screen. */
	flag = WFLAGP(wwin, full_maximize);
	break;
    }
    [[attrButtons objectAtIndex: i] setState: (flag ? NSOnState: NSOffState)];
    /* FIXME: unable to set balloon */
  }

  /* More attributes */
  for (i = 0;
#ifdef XKB_BUTTON_HINT
       i < 9;
#else
       i < 8;
#endif
       i++)
  {
    flag = 0;
    switch(i) {
      case 0:
	/** Do not bind keyboard shortcuts from Window Maker
	 * when this window is focused. This will allow the
	 * window to receive all key combinations regardless
	 * of your shortcut configuration. */
	flag = WFLAGP(wwin, no_bind_keys);
	break;
      case 1:
	/** Do not bind mouse actions, such as `Alt'+drag
	 * in the window (when alt is the modifier you have
	 * configured. */
	flag = WFLAGP(wwin, no_bind_mouse);
	break;
      case 2:
	/** Do not list the window in the window list menu. */
	flag = WFLAGP(wwin, skip_window_list);
	break;
      case 3:
	/** Do not let the window take keyboard focus when you
	 * click on it. */
	flag = WFLAGP(wwin, no_focusable);
	break;
      case 4:
	/** Do not allow the window to move itself completely
	 * outside the screen. For bug compatibility. */
	flag = WFLAGP(wwin, dont_move_off);
	break;
      case 5:
	/** Do not hide the window when issuing the
	 * `HideOthers' command */
	flag = WFLAGP(wwin, no_hide_others);
	break;
      case 6:
	/** Do not save the associated application in the
	 * session's state, so that it won't be restarted
	 * together with other applications when Window Maker
	 * starts */
	flag = WFLAGP(wwin, dont_save_session);
	break;
      case 7:
	/** Make this window act as an application that provides
	 * enough information to Window Maker for a dockable
	 * application icon to be created. */
	flag = WFLAGP(wwin, emulate_appicon);
	break;
#ifdef XKB_BUTTON_HINT
      case 8:
	/** Remove the `toggle language' button of the window */
	flag = WFLAGP(wwin, no_language_button);
	break;
#endif
    }
    [[advanButtons objectAtIndex: i] setState: (flag ? NSOnState: NSOffState)];
    /* FIXME: unable to set balloon */
  }

  /* miniwindows/workspace */
  flag = WFLAGP(wwin, always_user_icon);
  [ignoreIconButton setState: (flag ? NSOnState : NSOffState)];

  flag = wDefaultGetStartWorkspace(wwin->screen_ptr, wwin->wm_instance,
		  wwin->wm_class);
  if (flag >= 0 && flag <= wwin->screen_ptr->workspace_count) {
    if (flag == wwin->screen_ptr->current_workspace)
    {
      [self workspaceButtonAction: [wsButtons objectAtIndex: 1]];
    }
    else
    {
      [self workspaceButtonAction: [wsButtons objectAtIndex: 2]];
      /* store workspace number as tag */
      [[wsButtons objectAtIndex: 2] setTag: flag];
    }
  } else {
    [self workspaceButtonAction: [wsButtons objectAtIndex: 0]];
  }

  /* application specific */
  if (wwin->main_window != None)
  {
    WApplication *wapp = wApplicationOf(wwin->main_window);

    for (i = 0; i < 3; i++)
    {
      flag = 0;

      switch(i) {
        case 0:
	  /** Automatically hide application when it's started */
	  flag = WFLAGP(wapp->main_window_desc, start_hidden);
	  break;
	case 1:
	  /** Disable the application icon for the application.
	   * Note that you won't be able to dock it anymore,
	   * and any icons that are already docked will stop
	   * working correctly. */
	  flag = WFLAGP(wapp->main_window_desc, no_appicon);
	  break;
	case 2:
	  /** Use a single shared application icon for all of
	   * the instances of this application. */
	  flag = WFLAGP(wapp->main_window_desc, shared_appicon);
	  break;
      }
      [[appButtons objectAtIndex: i] setState: (flag ? NSOnState: NSOffState)];
    }

    if (WFLAGP(wwin, emulate_appicon)) {
      [[attrButtons objectAtIndex: 1] setEnabled: NO];
      [[advanButtons objectAtIndex: 7] setEnabled: YES];
    } else {
      [[attrButtons objectAtIndex: 1] setEnabled: YES];
      [[advanButtons objectAtIndex: 7] setEnabled: NO];
    }

    flag = YES;
  }
  else
  {
     if ((wwin->transient_for!=None && wwin->transient_for!=wwin->screen_ptr->root_win)
         || !wwin->wm_class || !wwin->wm_instance)
     {
	 [[advanButtons objectAtIndex: 7] setEnabled: NO];
     }
     else
     {
	 [[advanButtons objectAtIndex: 7] setEnabled: YES];
     }

     flag = NO;
  }
  /* FIXME: unable to disable tab item.
   * Disable every button instead
   */
  for (i = 0; i < [appButtons count]; i++) {
    [[appButtons objectAtIndex: i] setEnabled: flag];
  }

  /* if the window is a transient, don't let it have a miniaturize
   * button */
  if (wwin->transient_for!=None && wwin->transient_for!=wwin->screen_ptr->root_win)
  {
    [[attrButtons objectAtIndex: 3] setEnabled: NO];
  }
  else
  {
    [[attrButtons objectAtIndex: 3] setEnabled: YES];
  }

  if (!wwin->wm_class && !wwin->wm_instance) {
    flag = NO;
    /* select default target */
    [self targetButtonsAction: [targetButtons objectAtIndex: 3]];
  }
  else
  {
    flag = YES;
  }
  /* FIXME: unable to disable tab item.
   * Disable all buttons instead
   */
  for (i = 0; i < [targetButtons count]; i++) {
    [[targetButtons objectAtIndex: i] setEnabled: flag];
  }
}

- (void) updateInterfaceForWindow: (WWindow *) wwin
{
  /* update window title */
  [self setTitle: [NSString stringWithFormat: @"Window Inspector: %s.%s", wwin->wm_instance, wwin->wm_class]];

  /* update target */
  NSButton *button = nil;

  button = [targetButtons objectAtIndex: 0];
  [button setStringValue: [NSString stringWithFormat: @"%s.%s", wwin->wm_instance, wwin->wm_class]];

  button = [targetButtons objectAtIndex: 1];
  [button setStringValue: [NSString stringWithCString: wwin->wm_class]];

  button = [targetButtons objectAtIndex: 2];
  [button setStringValue: [NSString stringWithCString: wwin->wm_instance]];

  /* update icon */
  [self showIconForInstance: wwin->wm_instance class: wwin->wm_class
		screen: wwin->screen_ptr flag: UPDATE_TEXT_FIELD];
}

/* tabitem1 */
- (void) targetButtonsAction: (id) sender
{
  /* Make sure only one is selected */
  int i;
  NSButton *b;
  for (i = 0; i < [targetButtons count]; i++)
  {
    b = [targetButtons objectAtIndex: i];
    if (b != sender)
      [b setState: NSOffState];
    else
      [sender setState: NSOnState]; // always on
  }

  if (([[targetButtons objectAtIndex: 3] state] == NSOnState)
	&& (inspectedWin->wm_instance || inspectedWin->wm_class))
  {
    [applyButton setEnabled: NO];
  }
  else
  {
    [applyButton setEnabled: YES];
  }
}

- (NSTabViewItem *) createItem1
{
  // Window Specification
  item1 = [(NSTabViewItem *)[NSTabViewItem alloc] initWithIdentifier: WMWindowSpecificationItem];
  [item1 setLabel: @"Specification"];

  NSButton *button;
  NSRect rect = [tabView contentRect];
  NSView *view = [[NSView alloc] initWithFrame: rect];

  rect = NSMakeRect(rect.origin.x+5, rect.origin.y+5, 
		    rect.size.width/2, rect.size.height-5*2);
  NSBox *box = [[NSBox alloc] initWithFrame: rect];
  [box setTitle: @"Window Specification"];
  [box setTitlePosition: NSAtTop];
  [box setBorderType: NSGrooveBorder];
  [view addSubview: box];

  targetButtons = [[NSMutableArray alloc] init];
  button = [[NSButton alloc] initWithFrame: 
	  NSMakeRect(5, rect.size.height-60, rect.size.width-10, 25)];
  [button setButtonType: NSRadioButton];
  [button setStringValue: @"Both"];
  [button setState: NSOnState]; // select this one by default 
  [button setTarget: self];
  [button setAction: @selector(targetButtonsAction:)];
  [box addSubview: button];
  [targetButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame: 
	  NSMakeRect(5, rect.size.height-90, rect.size.width-10, 25)];
  [button setButtonType: NSRadioButton];
  [button setStringValue: @"Class"];
  [button setTarget: self];
  [button setAction: @selector(targetButtonsAction:)];
  [box addSubview: button];
  [targetButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame: 
	  NSMakeRect(5, rect.size.height-120, rect.size.width-10, 25)];
  [button setButtonType: NSRadioButton];
  [button setStringValue: @"Instance"];
  [button setTarget: self];
  [button setAction: @selector(targetButtonsAction:)];
  [box addSubview: button];
  [targetButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame: 
	  NSMakeRect(5, rect.size.height-150, rect.size.width-10, 25)];
  [button setButtonType: NSRadioButton];
  [button setStringValue: @"Defaults for All Windows"];
  [button setTarget: self];
  [button setAction: @selector(targetButtonsAction:)];
  [box addSubview: button];
  [targetButtons addObject: button];
  DESTROY(button);

  DESTROY(box);

  NSString *specText = [NSString stringWithCString: 
	  "The configuration will apply to all\n" \
	  "windows that have their WM_CLASS\n" \
	  "property set to the left selected\n" \
	  "name, when saved\n\n" \
	  "Click the button below,\n" \
	  "then click in the window you with to inspect.\n"
	  ];

  rect = NSMakeRect(NSMaxX(rect)+10, rect.origin.y+button_height+10,
		    rect.size.width-5-10, rect.size.height-button_height-10);
  NSTextField *specField = [[NSTextField alloc] initWithFrame: rect];
  [specField setStringValue: specText];
  [specField setEditable: NO];
  [specField setSelectable: NO];
  [specField setBezeled: NO];
  [specField setDrawsBackground: NO];
  [view addSubview: specField];
  DESTROY(specField);

  rect = NSMakeRect(rect.origin.x, rect.origin.y-button_height-10,
		    rect.size.width-5, button_height);
  button = [[NSButton alloc] initWithFrame: rect];
  [button setStringValue: @"Select Window"];
  [button setTarget: self];
  [button setAction: @selector(selectWindow:)];
  [view addSubview: button];
  [self makeFirstResponder: button];
  DESTROY(button);

  [item1 setView: view];
  DESTROY(view);

  return AUTORELEASE(item1);
}

/* tabitem2 */

- (void) attrButtonsAction: (id) sender
{
}

- (NSTabViewItem *) createItem2
{
  // Attributes
  item2 = [(NSTabViewItem *)[NSTabViewItem alloc] initWithIdentifier: WMAttributesItem];
  [item2 setLabel: @"Attributes"];

  attrButtons = [[NSMutableArray alloc] init];
  
  NSButton *button;
  NSRect rect = [tabView contentRect];
  NSView *view = [[NSView alloc] initWithFrame: rect];

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-30, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Disable titlebar"];
  [button setTarget: self];
  [button setAction: @selector(attrButtonsAction:)];
  [view addSubview: button];
  [attrButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-58, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Disable resizebar"];
  [button setTarget: self];
  [button setAction: @selector(attrButtonsAction:)];
  [view addSubview: button];
  [attrButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-86, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Disable close button"];
  [button setTarget: self];
  [button setAction: @selector(attrButtonsAction:)];
  [view addSubview: button];
  [attrButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-114, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Disable miniaturize button"];
  [button setTarget: self];
  [button setAction: @selector(attrButtonsAction:)];
  [view addSubview: button];
  [attrButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-142, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Disable border"];
  [button setTarget: self];
  [button setAction: @selector(attrButtonsAction:)];
  [view addSubview: button];
  [attrButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-170, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Keep on top (floating)"];
  [button setTarget: self];
  [button setAction: @selector(attrButtonsAction:)];
  [view addSubview: button];
  [attrButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(rect.size.width/2, rect.size.height-30, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Keep at bottom (sunken)"];
  [button setTarget: self];
  [button setAction: @selector(attrButtonsAction:)];
  [view addSubview: button];
  [attrButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(rect.size.width/2, rect.size.height-58, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Omnipresent"];
  [button setTarget: self];
  [button setAction: @selector(attrButtonsAction:)];
  [view addSubview: button];
  [attrButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(rect.size.width/2, rect.size.height-86, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Start miniaturized"];
  [button setTarget: self];
  [button setAction: @selector(attrButtonsAction:)];
  [view addSubview: button];
  [attrButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(rect.size.width/2, rect.size.height-114, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Start maximized"];
  [button setTarget: self];
  [button setAction: @selector(attrButtonsAction:)];
  [view addSubview: button];
  [attrButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(rect.size.width/2, rect.size.height-142, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Full screen maximization"];
  [button setTarget: self];
  [button setAction: @selector(attrButtonsAction:)];
  [view addSubview: button];
  [attrButtons addObject: button];
  DESTROY(button);

  [item2 setView: view];
  DESTROY(view);

  return AUTORELEASE(item2);
}

/* tabitem3 */
- (void) advanButtonsAction: (id) sender
{
}

- (NSTabViewItem *) createItem3
{
  // Advanced Options
  item3 = [(NSTabViewItem *)[NSTabViewItem alloc] initWithIdentifier: WMAdvancedOptionsItem];
  [item3 setLabel: @"Advanced"];

  advanButtons = [[NSMutableArray alloc] init];
  
  NSButton *button;
  NSRect rect = [tabView contentRect];
  NSView *view = [[NSView alloc] initWithFrame: rect];

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-30, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Do not bind keyboard shortcuts"];
  [button setTarget: self];
  [button setAction: @selector(advanButtonsAction:)];
  [view addSubview: button];
  [advanButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-58, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Do not bind mouse clicks"];
  [button setTarget: self];
  [button setAction: @selector(advanButtonsAction:)];
  [view addSubview: button];
  [advanButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-86, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Do not show in the window list"];
  [button setTarget: self];
  [button setAction: @selector(advanButtonsAction:)];
  [view addSubview: button];
  [advanButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-114, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Do not let it take focus"];
  [button setTarget: self];
  [button setAction: @selector(advanButtonsAction:)];
  [view addSubview: button];
  [advanButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-142, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Keep inside screen"];
  [button setTarget: self];
  [button setAction: @selector(advanButtonsAction:)];
  [view addSubview: button];
  [advanButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-170, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Ignore 'Hide Others'"];
  [button setTarget: self];
  [button setAction: @selector(advanButtonsAction:)];
  [view addSubview: button];
  [advanButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(rect.size.width/2, rect.size.height-30, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Ignore 'Save Session'"];
  [button setTarget: self];
  [button setAction: @selector(advanButtonsAction:)];
  [view addSubview: button];
  [advanButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(rect.size.width/2, rect.size.height-58, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Emulate application icon"];
  [button setTarget: self];
  [button setAction: @selector(advanButtonsAction:)];
  [view addSubview: button];
  [advanButtons addObject: button];
  DESTROY(button);

  [item3 setView: view];
  DESTROY(view);

  return AUTORELEASE(item3);
}

/* tabitem 4 */

- (void) browseButtonAction: (id) sender
{
  NSString *result = nil;
  [sender setEnabled: NO];
  if (inspectedWin)
  {
    result = [[WMDialogController sharedController]  iconChooserDialogWithInstance: [NSString stringWithCString: inspectedWin->wm_instance]
		class: [NSString stringWithCString: inspectedWin->wm_class]];
  }

  if (result)
  {
    [iconField setStringValue: result];
    [self showIconForInstance: inspectedWin->wm_instance
	    class: inspectedWin->wm_class screen: inspectedWin->screen_ptr
					  flag: USE_TEXT_FIELD];
  }
  [sender setEnabled: YES];
}

- (void) iconFieldAction: (id) sender
{
  [self showIconForInstance: inspectedWin->wm_instance
	    class: inspectedWin->wm_class screen: inspectedWin->screen_ptr
					  flag: USE_TEXT_FIELD];
}

- (void) ignoreIconButtonAction: (id) sender
{
}

- (void) workspaceButtonAction: (id) sender
{
  /* Make sure only one is selected */
  int i;
  NSButton *b;
  for (i = 0; i < [wsButtons count]; i++)
  {
    b = [wsButtons objectAtIndex: i];
    if (b != sender)
      [b setState: NSOffState];
    else
      [sender setState: NSOnState]; // always on
  }
}

- (NSTabViewItem *) createItem4
{
  // Icon and Initial Workspace
  item4 = [(NSTabViewItem *)[NSTabViewItem alloc] initWithIdentifier: WMIconAndInitialWorkspaceItem];
  [item4 setLabel: @"Icon and Workspace"];

  NSButton *button;
  NSRect rect = [tabView contentRect];
  NSView *view = [[NSView alloc] initWithFrame: rect];

  rect = NSMakeRect(rect.origin.x+5, rect.size.height-100, 
		    rect.size.width-10, 100);
  NSBox *box = [[NSBox alloc] initWithFrame: rect];
  [box setTitle: @"Miniwindow Image"];
  [box setTitlePosition: NSAtTop];
  [box setBorderType: NSGrooveBorder];
  [view addSubview: box];

  iconView = [[NSImageView alloc] initWithFrame:
	  NSMakeRect(5, 5, 64, 64)];
  [iconView setImageFrameStyle: NSImageFrameGroove];
  [box addSubview: iconView];
  RELEASE(iconView);

  NSTextField *field = [[NSTextField alloc] initWithFrame:
	  NSMakeRect(75, rect.size.height/2-10, 90, 25)];
  [field setStringValue: @"Icon filename:"];
  [field setEditable: NO];
  [field setSelectable: NO];
  [field setBezeled: NO];
  [field setDrawsBackground: NO];
  [box addSubview: field];
  DESTROY(field);

  iconField = [[NSTextField alloc] initWithFrame:
	  NSMakeRect(75+90+5, rect.size.height/2-10, 
		     rect.size.width-rect.size.height-90-80, 25)];
  [iconField setStringValue: @"icon path"];
  [box addSubview: iconField];
  RELEASE(iconField);

  button = [[NSButton alloc] initWithFrame: 
	  NSMakeRect(rect.size.width-90, rect.size.height/2-10,
			  70, 25)];
  [button setStringValue: @"Browse..."];
  [button setTarget: self];
  [button setAction: @selector(browseButtonAction:)];
  [box addSubview: button];
  DESTROY(button);

  ignoreIconButton = [[NSButton alloc] initWithFrame:
	  NSMakeRect(75, 7, rect.size.width-20, 25)];
  [ignoreIconButton setButtonType: NSSwitchButton];
  [ignoreIconButton setStringValue: @"Ignore client supplied icon"];
  [ignoreIconButton setTarget: self];
  [ignoreIconButton setAction: @selector(ignoreIconButtonAction:)];
  [box addSubview: ignoreIconButton];
  RELEASE(ignoreIconButton);

  DESTROY(box);

  /* workspace box */

  wsButtons = [[NSMutableArray alloc] init];

  rect = NSMakeRect(rect.origin.x, 5, 
		  rect.size.width, rect.origin.y-10);
  box = [[NSBox alloc] initWithFrame: rect];
  [box setTitle: @"Initial Workspace"];
  [box setTitlePosition: NSAtTop];
  [box setBorderType: NSGrooveBorder];
  [view addSubview: box];

  button = [[NSButton alloc] initWithFrame: NSMakeRect(5, 5, 180, 25)];
  [button setButtonType: NSRadioButton];
  [button setStringValue: @"Nowhere in particular"];
  [button setState: NSOnState]; // default
  [button setTarget: self];
  [button setAction: @selector(workspaceButtonAction:)];
  [wsButtons addObject: button];
  [box addSubview: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame: NSMakeRect(190, 5, 180, 25)];
  [button setButtonType: NSRadioButton];
  [button setStringValue: @"Current workspace"];
  [button setTarget: self];
  [button setAction: @selector(workspaceButtonAction:)];
  [wsButtons addObject: button];
  [box addSubview: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame: NSMakeRect(380, 5, 180, 25)];
  [button setButtonType: NSRadioButton];
  [button setStringValue: @"Keep original setting"];
  [button setTarget: self];
  [button setAction: @selector(workspaceButtonAction:)];
  [wsButtons addObject: button];
  [box addSubview: button];
  DESTROY(button);

  DESTROY(box);

  [item4 setView: view];
  DESTROY(view);

  return AUTORELEASE(item4);
}

/* tabitem 5 */

- (void) appButtonsAction: (id) sender
{
}

- (NSTabViewItem *) createItem5
{
  // Application Specific
  item5 = [(NSTabViewItem *)[NSTabViewItem alloc] initWithIdentifier: WMApplicationSpecificItem];
  [item5 setLabel: @"Application"];

  appButtons = [[NSMutableArray alloc] init];
  
  NSButton *button;
  NSRect rect = [tabView contentRect];
  NSView *view = [[NSView alloc] initWithFrame: rect];

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-30, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Start hidden"];
  [button setTarget: self];
  [button setAction: @selector(appButtonsAction:)];
  [view addSubview: button];
  [appButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-58, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"No application icon"];
  [button setTarget: self];
  [button setAction: @selector(appButtonsAction:)];
  [view addSubview: button];
  [appButtons addObject: button];
  DESTROY(button);

  button = [[NSButton alloc] initWithFrame:
  		NSMakeRect(5, rect.size.height-86, rect.size.width/2-10, 25)];
  [button setButtonType: NSSwitchButton];
  [button setStringValue: @"Shared application icon"];
  [button setTarget: self];
  [button setAction: @selector(appButtonsAction:)];
  [view addSubview: button];
  [appButtons addObject: button];
  DESTROY(button);

  [item5 setView: view];
  DESTROY(view);

  return AUTORELEASE(item5);
}

- (void) createInterface
{
  NSRect rect;
//  int x, y, w, h;
  button_height = 25;
  size = NSMakeSize(600, 250);
  rect = NSMakeRect(300, 100, size.width, size.height);

  self = [super initWithContentRect: rect
	                  styleMask: (NSTitledWindowMask | NSClosableWindowMask)
			  backing: NSBackingStoreBuffered
			  defer: YES];
  [self setTitle: @"Window Inspector"];
  [self setHidesOnDeactivate: NO];

  /* tab view*/
  rect = NSMakeRect(10, 10+button_height+10, 
		    size.width-10*2, size.height-button_height-10-10-10);
  tabView = [[NSTabView alloc] initWithFrame: rect];
  [tabView addTabViewItem: [self createItem1]];
  [tabView addTabViewItem: [self createItem2]];
  [tabView addTabViewItem: [self createItem3]];
  [tabView addTabViewItem: [self createItem4]];
  [tabView addTabViewItem: [self createItem5]];

  [[self contentView] addSubview: tabView];

  /* reload button */
  rect = NSMakeRect(size.width-10-60*3-10*2, 10, 60, button_height);
  reloadButton = [[NSButton alloc] initWithFrame: rect];
  [reloadButton setStringValue: @"Reload"];
  [reloadButton setTarget: self];
  [reloadButton setAction: @selector(reloadButtonAction:)];
  [[self contentView] addSubview: reloadButton];

  /* apply button */
  rect = NSMakeRect(NSMaxX(rect)+10, 10, 60, button_height);
  applyButton = [[NSButton alloc] initWithFrame: rect];
  [applyButton setStringValue: @"Apply"];
  [applyButton setTarget: self];
  [applyButton setAction: @selector(applyButtonAction:)];
  [[self contentView] addSubview: applyButton];

  /* save button */
  rect = NSMakeRect(NSMaxX(rect)+10, 10, 60, button_height);
  saveButton = [[NSButton alloc] initWithFrame: rect];
  [saveButton setStringValue: @"Save"];
  [saveButton setTarget: self];
  [saveButton setAction: @selector(saveButtonAction:)];
  [[self contentView] addSubview: saveButton];

  [self setDelegate: self];
}

- (void) removeIconForApplication: (WApplication *) wapp
{
  if (!wapp->app_icon)
    return;

  if (wapp->app_icon->docked && !wapp->app_icon->attracted) {
    wapp->app_icon->running = 0;
    /* since we keep it, we don't care if it was attracted or not */
    wapp->app_icon->attracted = 0;
    wapp->app_icon->icon->shadowed = 0;
    wapp->app_icon->main_window = None;
    wapp->app_icon->pid = 0;
    wapp->app_icon->icon->owner = NULL;
    wapp->app_icon->icon->icon_win = None;
    wapp->app_icon->icon->force_paint = 1;
    wAppIconPaint(wapp->app_icon);
  } else if (wapp->app_icon->docked) {
    wapp->app_icon->running = 0;
    wDockDetach(wapp->app_icon->dock, wapp->app_icon);
  } else {
    wAppIconDestroy(wapp->app_icon);
  }
  wapp->app_icon = NULL;
  if (wPreferences.auto_arrange_icons)
    wArrangeIcons(wapp->main_window_desc->screen_ptr, True);
}

- (void) makeIconForApplication: (WApplication *) wapp
{
  WScreen *scr = wapp->main_window_desc->screen_ptr;

  if (wapp->app_icon)
    return;

  if (!WFLAGP(wapp->main_window_desc, no_appicon))
    wapp->app_icon = wAppIconCreate(wapp->main_window_desc);
  else
    wapp->app_icon = NULL;

  if (wapp->app_icon) {
    WIcon *icon = wapp->app_icon->icon;
    WDock *clip = scr->workspaces[scr->current_workspace]->clip;
    int x=0, y=0;

    wapp->app_icon->main_window = wapp->main_window;

    if (clip && clip->attract_icons && wDockFindFreeSlot(clip, &x, &y)) {
      wapp->app_icon->attracted = 1;
      if (!wapp->app_icon->icon->shadowed) {
        wapp->app_icon->icon->shadowed = 1;
        wapp->app_icon->icon->force_paint = 1;
      }
      wDockAttachIcon(clip, wapp->app_icon, x, y);
    } else {
      PlaceIcon(scr, &x, &y, wGetHeadForWindow(wapp->main_window_desc));
      wAppIconMove(wapp->app_icon, x, y);
    }

    if (!clip || !wapp->app_icon->attracted || !clip->collapsed)
      XMapWindow(dpy, icon->core->window);

    if (wPreferences.auto_arrange_icons && !wapp->app_icon->attracted)
      wArrangeIcons(wapp->main_window_desc->screen_ptr, True);
  }
}

- (int) showIconForInstance: (char *) wm_instance class: (char *) wm_class
		      screen: (WScreen *) scr flag: (int) flags
{
  char *db_icon=NULL;
  char *path = NULL;
  NSString *file = nil;
  NSImage *image = nil;

  if ((flags & USE_TEXT_FIELD) != 0) {
    file = [iconField stringValue];
  } else {
    db_icon = wDefaultGetIconFile(scr, wm_instance, wm_class, False);
    if(db_icon != NULL)
      file = [NSString stringWithCString: db_icon];
  }
  if (db_icon!=NULL && (flags & REVERT_TO_DEFAULT)!=0) {
    if (file)
      file = [NSString stringWithCString: db_icon];
    flags |= UPDATE_TEXT_FIELD;
  }
  if ((flags & UPDATE_TEXT_FIELD) != 0) {
    [iconField setStringValue: file];
  }

  if (file && [file length]) {
    path = FindImage(wPreferences.icon_path, (char*)[file cString]);
    if (!path) {
      NSString *s = [NSString stringWithFormat: @"Could not find icon %@ specified for this window", file];
      NSRunAlertPanel(@"Error", s, @"OK", nil, nil);
      return -1;
    }

    // FIXME: GNUstep doesn't read XPM file
    if ([[file pathExtension] compare: @"XPM" options: NSCaseInsensitiveSearch] == NSOrderedSame)
    {
      return 0;
    }

    image = [[NSImage alloc] initWithContentsOfFile: [NSString stringWithCString: path]];
    wfree(path);

    if (image == nil)
    {
      NSString *s = [NSString stringWithFormat: @"Could not open specified icon %@:%s ", file, RMessageForError(RErrorCode)];
      NSRunAlertPanel(@"Error", s, @"OK", nil, nil);
      return -1;
    }
  }

  [iconView setImage: image];

  return 0;
}

/*
 * Will insert the attribute = value; pair in window's list,
 * if it's different from the defaults.
 * Defaults means either defaults database, or attributes saved
 * for the default window "*". This is to let one revert options that are
 * global because they were saved for all windows ("*").
 *
 */

- (int) insertAttribute: (NSString *) attr
                  value: (id) value
                   into: (NSMutableDictionary *) window
                   flag: (int) flags
{
  WMDefaults *defaults = [WMDefaults sharedDefaults];
  int update = 0;
  int modified = 0;
  id def_value = nil;

  if (!(flags & UPDATE_DEFAULTS)) {
    def_value = [defaults objectForKey: attr window: WAAnyWindow];
  }

  /* If we could not find defaults in database, fall to hardcoded values.
   * Also this is true if we save defaults for all windows
   */
  if (!def_value)
  {
    def_value = ((flags & IS_BOOLEAN) != 0) ? WANo : [NSString string];
  }

  update = ([value isEqualToString: def_value] == NO);

  if (update) {
    [window setObject: value forKey: attr];
    modified = 1;
  }

  return modified;
}

/** delegate */
- (void) windowWillClose: (NSNotification *) not
{
  [self setWindow: NULL];
}

@end

