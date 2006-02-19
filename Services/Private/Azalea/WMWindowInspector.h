#ifndef __WM_WINDOW_INSPECTOR__
#define __WM_WINDOW_INSPECTOR__

#include <AppKit/AppKit.h>
#include "window.h"

@interface WMWindowInspector: NSPanel
{
  WWindow *inspectedWin;

  /* interface */
  NSSize size; // inspector window size
  int button_height;

  NSTabView *tabView;
  NSTabViewItem *item1; // Window Specification
  NSTabViewItem *item2; // Attributes
  NSTabViewItem *item3; // Advanced Options
  NSTabViewItem *item4; // Icon and workspace
  NSTabViewItem *item5; // Application

  /* tabview item 1 */
  NSMutableArray *targetButtons;

  /* tabview item 2 */
  NSMutableArray *attrButtons;

  /* tabview item 3 */
  NSMutableArray *advanButtons;

  /* tabview item 4 */
  NSTextField *iconField;
  NSImageView *iconView;
  NSButton *ignoreIconButton;
  NSMutableArray *wsButtons;

  /* tabview item 5 */
  NSMutableArray *appButtons;

  NSButton *reloadButton;
  NSButton *applyButton;
  NSButton *saveButton;

  NSString *targetString; // instance.class
}

+ (WMWindowInspector *) sharedWindowInspector;

- (void) reloadButtonAction: (id) sender;
- (void) applyButtonAction: (id) sender;
- (void) saveButtonAction: (id) sender;

- (void) setWindow: (WWindow *) wwin;
- (WWindow *) window;

@end

#endif /* __WM_WINDOW_INSPECTOR__ */
