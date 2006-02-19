
#if 0
#include "WINGsP.h"
#include "wconfig.h"

#include <X11/Xlocale.h>
#include "WindowMaker.h"
extern WPreferences wPreferences;

_WINGsConfiguration WINGsConfiguration;
#endif
void
W_ReadConfigurations(void)
{
#if 0
    memset(&WINGsConfiguration, 0, sizeof(_WINGsConfiguration));

    if (WINGsConfiguration.doubleClickDelay == 0) {
        WINGsConfiguration.doubleClickDelay = 250;
    }
    if (WINGsConfiguration.mouseWheelUp == 0) {
        WINGsConfiguration.mouseWheelUp = Button4;
    }
    wPreferences.mouseWheelUp = Button4;
    if (WINGsConfiguration.mouseWheelDown == 0) {
        WINGsConfiguration.mouseWheelDown = Button5;
    }
#endif
}

