#include "WMWindowInspector.h"
#include "WMApplication.h"
#include "WMDefaults.h"
#include "screen.h"
#include "window.h"
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

@interface WMWindowInspector (WMPrivate)
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
  [self createInterface];

  return self;
}

- (void) dealloc
{
  DESTROY(tabView);
  DESTROY(reloadButton);
  DESTROY(applyButton);
  DESTROY(saveButton);
  DESTROY(targetButtons);
  DESTROY(attrButtons);
  DESTROY(advanButtons);
  DESTROY(appButtons);
  [super dealloc];
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

      NSLog(@"iwin %d", iwin);
      [self readAttributesFromWindow: iwin];
      [self updateInterfaceForWindow: iwin];
#if 0
    iwin->flags.inspector_open = 1;
    iwin->inspector = createInspectorForWindow(iwin,
                                               panel->frame->frame_x,
                                               panel->frame->frame_y,
                                               True);
    wCloseInspectorForWindow(wwin);
#endif
    } 
#if 0 // FIXME: doesn't work
    else
    {
      WMSetLabelText(panel->specLbl, spec_text);
    }
#endif
  }
  else
  {
    NSLog(@"Error: No screen for %d", screen);
  }
}

- (void) reloadButtonAction: (id) sender
{
}

- (void) applyButtonAction: (id) sender
{
}

- (void) saveButtonAction: (id) sender
{
}

/* Private */

- (void) readAttributesFromWindow: (WWindow *) wwin
{
  int i;

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
    int flag = 0;

    switch(i) {
      case 0:
	/** Remove the titlebar of this window.
	 * To access the window commands menu of a window
	 * without it's titlebar, press Control+Esc (or the
	 * equivalent shortcut, if you changed the default
	 * settings).
	 */
	flag = WFLAGP(wwin, no_titlebar);
	NSLog(@"Disable titlebar: %d", flag);
	break;
      case 1:
	/** Remove the resizebar of this window. */
	flag = WFLAGP(wwin, no_resizebar);
	NSLog(@"Disable resizebar: %d", flag);
	break;
      case 2:
	/** Remove the `close window' button of this window. */
	flag = WFLAGP(wwin, no_close_button);
	NSLog(@"Disable close button: %d", flag);
	break;
      case 3:
	/** Remove the `miniaturize window' button of the window. */
	flag = WFLAGP(wwin, no_miniaturize_button);
	NSLog(@"Disable miniaturize button: %d", flag);
	break;
      case 4:
	/** Remove the 1 pixel black border around the window. */
	flag = WFLAGP(wwin, no_border);
	NSLog(@"Disable border: %d", flag);
	break;
      case 5:
	/** Keep the window over other windows, not allowing
	 * them to cover it. */
	flag = WFLAGP(wwin, floating);
	NSLog(@"Keep on top (floating): %d", flag);
	break;
      case 6:
	/** Keep the window under all other windows */
	flag = WFLAGP(wwin, sunken);
	NSLog(@"Keep at bottom (sunken): %d", flag);
	break;
      case 7:
	/** Make window present in all workspaces */
	flag = WFLAGP(wwin, omnipresent);
	NSLog(@"Omnipresent: %d", flag);
	break;
      case 8:
	/** Make the window be automatically minaturized when it's
	 * first shown. */
	flag = WFLAGP(wwin, start_miniaturized);
	NSLog(@"Start miniaturized: %d", flag);
	break;
      case 9:
	/** Make the window be automatically maximized when it's
	 * first shown. */
	flag = WFLAGP(wwin, start_maximized!=0);
	NSLog(@"Start miximized: %d", flag);
	break;
      case 10:
	/** Make the window use the whole screen space when it's
	 * maximized. The titlebar and resizebar will be moved
	 * to outside the screen. */
	flag = WFLAGP(wwin, full_maximize);
	NSLog(@"Full screen maximization: %d", flag);
	break;
    }
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
    int flag = 0;
    switch(i) {
      case 0:
	/** Do not bind keyboard shortcuts from Window Maker
	 * when this window is focused. This will allow the
	 * window to receive all key combinations regardless
	 * of your shortcut configuration. */
	flag = WFLAGP(wwin, no_bind_keys);
	NSLog(@"Do not bind keyboard shortcuts: %d", flag);
	break;
      case 1:
	/** Do not bind mouse actions, such as `Alt'+drag
	 * in the window (when alt is the modifier you have
	 * configured. */
	flag = WFLAGP(wwin, no_bind_mouse);
	NSLog(@"Do not bind mouse clicks: %d", flag);
	break;
      case 2:
	/** Do not list the window in the window list menu. */
	flag = WFLAGP(wwin, skip_window_list);
	NSLog(@"Do not show in the window list: %d", flag);
	break;
      case 3:
	/** Do not let the window take keyboard focus when you
	 * click on it. */
	flag = WFLAGP(wwin, no_focusable);
	NSLog(@"Do no let it take focus: %d", flag);
	break;
      case 4:
	/** Do not allow the window to move itself completely
	 * outside the screen. For bug compatibility. */
	flag = WFLAGP(wwin, dont_move_off);
	NSLog(@"Keep inside screen: %d", flag);
	break;
      case 5:
	/** Do not hide the window when issuing the
	 * `HideOthers' command */
	flag = WFLAGP(wwin, no_hide_others);
	NSLog(@"Ignore `Hide Others': %d", flag);
	break;
      case 6:
	/** Do not save the associated application in the
	 * session's state, so that it won't be restarted
	 * together with other applications when Window Maker
	 * starts */
	flag = WFLAGP(wwin, dont_save_session);
	NSLog(@"Ignore `Save Session': %d", flag);
	break;
      case 7:
	/** Make this window act as an application that provides
	 * enough information to Window Maker for a dockable
	 * application icon to be created. */
	flag = WFLAGP(wwin, emulate_appicon);
	NSLog(@"Emulate application icon: %d", flag);
	break;
#ifdef XKB_BUTTON_HINT
      case 8:
	/** Remove the `toggle language' button of the window */
	flag = WFLAGP(wwin, no_language_button);
	NSLog(@"Disable language button %d", flag);
	break;
#endif
    }
  }

  /* miniwindows/workspace */

  /* application specific */
  if (wwin->main_window != None)
  {
    WApplication *wapp = wApplicationOf(wwin->main_window);

    for (i = 0; i < 3; i++)
    {
      int flag = 0;

      switch(i) {
        case 0:
	  /** Automatically hide application when it's started */
	  flag = WFLAGP(wapp->main_window_desc, start_hidden);
	  NSLog(@"Start hidden: %d", flag);
	  break;
	case 1:
	  /** Disable the application icon for the application.
	   * Note that you won't be able to dock it anymore,
	   * and any icons that are already docked will stop
	   * working correctly. */
	  flag = WFLAGP(wapp->main_window_desc, no_appicon);
	  NSLog(@"No application icon: %d", flag);
	  break;
	case 2:
	  /** Use a single shared application icon for all of
	   * the instances of this application. */
	  flag = WFLAGP(wapp->main_window_desc, shared_appicon);
	  NSLog(@"Shared application icon: %d", flag);
	  break;
      }
    }
#if 0 // FIXME
    if (WFLAGP(wwin, emulate_appicon)) {
        WMSetButtonEnabled(panel->appChk[1], False);
        WMSetButtonEnabled(panel->moreChk[7], True);
    } else {
        WMSetButtonEnabled(panel->appChk[1], True);
        WMSetButtonEnabled(panel->moreChk[7], False);
    }
#endif
  }
  else
  {
#if 0 // FIXME
    int tmp;

     if ((wwin->transient_for!=None && wwin->transient_for!=scr->root_win)
         || !wwin->wm_class || !wwin->wm_instance)
         tmp = False;
     else
         tmp = True;
     WMSetButtonEnabled(panel->moreChk[7], tmp);

     WMSetPopUpButtonItemEnabled(panel->pagePopUp, 4, False);
		        panel->appFrm = NULL;
#endif
  }

#if 0
  /* if the window is a transient, don't let it have a miniaturize
   * button */
  if (wwin->transient_for!=None && wwin->transient_for!=scr->root_win)
      WMSetButtonEnabled(panel->attrChk[3], False);
  else
      WMSetButtonEnabled(panel->attrChk[3], True);

  if (!wwin->wm_class && !wwin->wm_instance) {
    WMSetPopUpButtonItemEnabled(panel->pagePopUp, 0, False);
  }
#endif


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
}

- (void) ignoreIconButtonAction: (id) sender
{
}

- (void) workspaceButtonAction: (id) sender
{
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

  rect = NSMakeRect(rect.origin.x, 5, 
		  rect.size.width, rect.origin.y-10);
  box = [[NSBox alloc] initWithFrame: rect];
  [box setTitle: @"Initial Workspace"];
  [box setTitlePosition: NSAtTop];
  [box setBorderType: NSGrooveBorder];
  [view addSubview: box];

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
}

@end
