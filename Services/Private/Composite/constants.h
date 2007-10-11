#define TRANSLUCENT	0xe0000000
#define OPAQUE		0xffffffff

#define ICON_SIZE	64

#define WINDOW_SOLID	0
#define WINDOW_TRANS	1
#define WINDOW_ARGB	2

#define TRANS_OPACITY	0.75

#define DEBUG_REPAINT 0
#define DEBUG_EVENTS 0
#define MONITOR_REPAINT 0
#define DEBUG_LOG_ATOM_VALUES 0
#define DEBUG_ICONIFY 0

#define SHADOWS		1
#define SHARP_SHADOW	0

#if COMPOSITE_MAJOR > 0 || COMPOSITE_MINOR >= 2
#define HAS_NAME_WINDOW_PIXMAP 1
#endif

#ifndef M_PI
#define  M_PI 3.14159265358979323846  /* glibc is a waste of space */
#endif
