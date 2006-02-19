#ifndef __WM_DOCKED_APP_PANEL__
#define __WM_DOCKED_APP_PANEL__

#include <AppKit/AppKit.h>
#include "appicon.h"

@interface WMDockedAppPanel: NSPanel
{
  NSImageView *iconView;
  NSTextField *nameField;
  NSButton *startButton;
  NSButton *lockButton;

  NSTextField *pathField;
  NSTextField *commandField;
  NSTextField *dndField;
  NSTextField *dndLabel;
  NSTextField *iconField;

  WAppIcon *aicon;
}

+ (WMDockedAppPanel *) sharedPanel;

- (void) setAppIcon: (WAppIcon *) icon;
- (WAppIcon *) appIcon;

@end

#endif /* __WM_DOCKED_APP_PANEL__ */
