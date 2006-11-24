#import "Controller.h"
#import "CETextView.h"
#import "CEWindow.h"
#import "GNUstep.h"
#import "FontPreferencePane.h"
#import "ViewPreferencePane.h"

@implementation Controller
/* Private */
- (CEWindow *) createNewWindow
{
  NSRect rect = NSMakeRect(200, 200, 400, 400);
  if ([NSApp mainWindow]) {
    rect = [[NSApp mainWindow] frame];
    rect.origin.x += 20;
    rect.origin.y -= 40; /* There is a title bar. So it is 40, not 20 */
  }
  CEWindow *window = [[CEWindow alloc] initWithContentRect: rect
             styleMask: NSTitledWindowMask |
                        NSClosableWindowMask |
                        NSResizableWindowMask
             backing: NSBackingStoreBuffered
             defer: YES];

  [window setReleasedWhenClosed: YES];
  [windows addObject: window];
  return window;
}

/* Find the text view with path */
- (CETextView *) textViewWithPath: (NSString *) p
{
  NSEnumerator *e2, *e1 = [windows objectEnumerator];
  CEWindow *window;
  CETextView *view;
  while ((window = [e1 nextObject])) {
    e2 = [[window textViews] objectEnumerator];
    while ((view = [e2 nextObject])) {
      if ([[view path] isEqualToString: p]) {
        return view;
      }
    }
  }
  return nil;
}
/* End of private */

/* Menu action */
- (void) openInWindow: (id) sender
{
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  [panel setAllowsMultipleSelection: YES];
  int result = [panel runModalForTypes: nil];
  if (result == NSOKButton) {
    NSEnumerator *e = [[panel filenames] objectEnumerator];
    NSString *p;
    CETextView *view;
    CEWindow *window;
    while ((p = [e nextObject])) {
      view = [self textViewWithPath: p];
      if (view == nil) {
        window = [self createNewWindow];
        view = [[window textViews] objectAtIndex: 0];
      }
      if ([view isEdited] == YES) {
        int result = NSRunAlertPanel(@"Open File", @"This document is edited. Are you sure to reload this file ?", @"Cancel", @"Load Anyway", nil, nil);
        if (result == NSAlertDefaultReturn) {
          continue; /* Cancel */
        }
      }
      [view loadFileAtPath: p];
      [(CEWindow *)[view window] setTitleWithPath: p];
      [[view window] makeKeyAndOrderFront: self];
    }
  }
}

- (void) openInTab: (id) sender
{
  CEWindow *window;
  CETextView *view;
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  [panel setAllowsMultipleSelection: YES];
  int result = [panel runModalForTypes: nil];
  if (result == NSOKButton) {
    NSEnumerator *e = [[panel filenames] objectEnumerator];
    NSString *p;
    while ((p = [e nextObject])) {
      if ([windows count] == 0) {
        /* No window yet. create one */
        window = [self createNewWindow];
        view = [[window textViews] objectAtIndex: 0];
        [view loadFileAtPath: p];
        [window makeKeyAndOrderFront: self];
      } else { 
        window = (CEWindow *)[NSApp mainWindow];
        view = [window createNewTextViewWithFileAtPath: p];
      }
    }
    [[view window] makeKeyAndOrderFront: self];
  }
}

- (void) newInWindow: (id) sender
{
  CEWindow *window = [self createNewWindow];
  /* make sure title is displayed */
  [window setTitle: [[[window textViews] objectAtIndex: 0] displayName]];
  [window makeKeyAndOrderFront: self];
}

- (void) newInTab: (id) sender
{
  if ([windows count] == 0) {
    [self newInWindow: sender];
  } else {
    /* Find the most front window */
    CEWindow *mainWindow = (CEWindow *)[NSApp mainWindow];
    CETextView *view = [mainWindow createNewTextViewWithFileAtPath: nil];
  }
}

- (void) closeWindow: (id) sender
{
  CEWindow *window = (CEWindow *)[NSApp mainWindow];
  if (window) {
    [window performClose: self];
  }
}

- (void) closeTab: (id) sender
{
  CEWindow *window = (CEWindow *)[NSApp mainWindow];
  if (window) {
    CETextView *view = [window mainTextView];
    if ([view isEdited]) {
      /* Ask about closing */
      int result = NSRunAlertPanel(@"Tab will be closed", @"This document is edited. Are you sure to close this tab?", @"Cancel", @"Close Anyway", nil, nil);
      if (result == NSAlertDefaultReturn) {
        return; /* Cancel */
      }
    }
    [window removeTextView: view];
  }
}

- (void) showPreferences: (id) sender
{
  if (preferencesController == nil) { 
    /* Initialize here */
    /* Automatically register into PKPreferencePaneRegistry */
    AUTORELEASE([[ViewPreferencePane alloc] init]);
    AUTORELEASE([[FontPreferencePane alloc] init]);
    ASSIGN(preferencesController, [PKPreferencesController sharedPreferencesController]);
    [preferencesController setPresentationMode: PKMatrixPresentationMode];
  }
  [(NSWindow *)[preferencesController owner] setTitle: @"Preferences"];
//  [(NSWindow *)[preferencesController owner] makeKeyAndOrderFront: self];
  [NSApp runModalForWindow: (NSPanel *)[preferencesController owner]];
}

- (id) init
{
  self = [super init];

  windows = [[NSMutableArray alloc] init];

  /* Listen to window close */
  [[NSNotificationCenter defaultCenter]
                       addObserver: self
                       selector: @selector(windowWillClose:)
                       name: NSWindowWillCloseNotification
                       object: nil];

  return self;
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];
  DESTROY(windows);
  [super dealloc];
}

- (void)applicationWillFinishLaunching: (NSNotification *) not
{
  /* Make sure some user defaults are set */
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  id object = [defaults objectForKey: CodeEditorShowLineNumberDefaults];
  if (object == nil) {
    [defaults setBool: YES forKey: CodeEditorShowLineNumberDefaults];
  }
}

- (BOOL) applicationShouldTerminate: (NSNotification *) not
{
  /* We close all window so that users can review each window */
  NSEnumerator *e = [windows objectEnumerator];
  CEWindow *win;
  int count;
  while ([windows count]) {
    count = [windows count];
    win = [windows lastObject];
    [win performClose: self];
    if (count == [windows count]) {
      /* Some window refuse to close */
      break;
    }
  }
  if ([windows count] > 0) {
    /* Some windows refuse to close */
    return NO;
  } else {
    return YES;
  }
}

/* Notification */
- (void) windowWillClose: (NSNotification *) not
{
  /* Remove from cache */
  /* Be careful: this listen to all windows, not only CEWindow. */
  [windows removeObject: [not object]];
}

@end

