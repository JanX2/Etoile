#import <Foundation/Foundation.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/extensions/Xcomposite.h>
#include <X11/extensions/Xdamage.h>
#include <X11/extensions/Xrender.h>

@class CompositeWindow;

@interface CompositeDisplay : NSObject {
	Display * dpy;
	int scr;
	NSMutableArray * windows;
	NSMapTable * windowsByID;
	XserverRegion allDamage;
	Picture		rootPicture;
	Picture		rootBuffer;
	Picture		rootTile;
	int	root_height;
	int root_width;
	Window root;
	BOOL clipChanged;
}
- (id) initForDisplay:(char*)display;
- (void) addDamage:(XserverRegion) damage;
- (CompositeWindow*) windowForID:(Window)aWindow;
- (void) unmapWindowWithID:(Window)aWindow;
- (void) circulateWindowWithEvent:(XCirculateEvent*)ce;
@end
