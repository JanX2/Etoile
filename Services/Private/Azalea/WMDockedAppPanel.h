#ifndef __WM_DOCKED_APP_PANEL__
#define __WM_DOCKED_APP_PANEL__

#include <AppKit/AppKit.h>

@interface WMDockedAppPanel: NSPanel
{
}

+ (WMDockedAppPanel *) sharedPanel;

@end

#endif /* __WM_DOCKED_APP_PANEL__ */
