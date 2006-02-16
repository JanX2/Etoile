

#include "WINGsP.h"
#include "wconfig.h"

#include <X11/Xlocale.h>


_WINGsConfiguration WINGsConfiguration;

#define SYSTEM_FONT "Trebuchet MS,Luxi Sans"
#define BOLD_SYSTEM_FONT "Trebuchet MS,Luxi Sans:bold"
#define DEFAULT_FONT_SIZE 12

void
W_ReadConfigurations(void)
{
    memset(&WINGsConfiguration, 0, sizeof(_WINGsConfiguration));

    if (!WINGsConfiguration.systemFont) {
        WINGsConfiguration.systemFont = SYSTEM_FONT;
    }
    if (!WINGsConfiguration.boldSystemFont) {
        WINGsConfiguration.boldSystemFont = BOLD_SYSTEM_FONT;
    }
    if (WINGsConfiguration.defaultFontSize == 0) {
        WINGsConfiguration.defaultFontSize = DEFAULT_FONT_SIZE;
    }
    if (WINGsConfiguration.doubleClickDelay == 0) {
        WINGsConfiguration.doubleClickDelay = 250;
    }
    if (WINGsConfiguration.mouseWheelUp == 0) {
        WINGsConfiguration.mouseWheelUp = Button4;
    }
    if (WINGsConfiguration.mouseWheelDown == 0) {
        WINGsConfiguration.mouseWheelDown = Button5;
    }

}

