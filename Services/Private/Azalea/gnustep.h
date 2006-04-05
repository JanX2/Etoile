/* Take from XGServerWindow.h */

#define _GNUSTEP_WM_ATTR "_GNUSTEP_WM_ATTR"

typedef struct {
    unsigned long flags;
    unsigned long window_style;
    unsigned long window_level;
    unsigned long reserved;
    Pixmap miniaturize_pixmap;          // pixmap for miniaturize button
    Pixmap close_pixmap;                // pixmap for close button
    Pixmap miniaturize_mask;            // miniaturize pixmap mask
    Pixmap close_mask;                  // close pixmap mask
    unsigned long extra_flags;
} GNUstepWMAttributes;

#define GSWindowStyleAttr       (1<<0)
#define GSWindowLevelAttr       (1<<1)
#define GSMiniaturizePixmapAttr (1<<3)
#define GSClosePixmapAttr       (1<<4)
#define GSMiniaturizeMaskAttr   (1<<5)
#define GSCloseMaskAttr         (1<<6)
#define GSExtraFlagsAttr        (1<<7)

#define GSDocumentEditedFlag                    (1<<0)
#define GSWindowWillResizeNotificationsFlag     (1<<1)
#define GSWindowWillMoveNotificationsFlag       (1<<2)
#define GSNoApplicationIconFlag                 (1<<5)
#define WMFHideOtherApplications                10
#define WMFHideApplication                      12


