#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/extensions/Xcomposite.h>
#include <X11/extensions/Xdamage.h>
#include <X11/extensions/Xrender.h>
#import <Foundation/Foundation.h>
#include "constants.h"
#import "Shadow.h"

extern Atom	opacityAtom;
extern Atom	winTypeAtom;
extern Atom	winDesktopAtom;
extern Atom	winDockAtom;
extern Atom	winToolbarAtom;
extern Atom	winMenuAtom;
extern Atom	winUtilAtom;
extern Atom	winSplashAtom;
extern Atom	winDialogAtom;
extern Atom	winNormalAtom;
extern Atom	winActiveAtom;

@class CompositeDisplay;

@interface CompositeWindow : NSObject {
	struct _win    *next;
	Window		windowID;
#if HAS_NAME_WINDOW_PIXMAP
	Pixmap		pixmap;
#endif
	XWindowAttributes a;
	int		mode;
	int		damaged;
	Damage		damage;
	Picture		picture;
	Picture		alphaPict;
	Picture		shadowPict;
	XserverRegion	borderSize;
	XserverRegion	extents;
	Shadow * shadow;
	Picture shadowPicture;
	uint32_t	opacity;
	Atom		windowType;
	NSString * owner;
	id Display;

	BOOL isIconified;
	int realX, realY;

	CompositeDisplay * display;

	unsigned long	damage_sequence;	/* sequence when damage was
						 * created */

@public
	/* for drawing translucent windows */
	XserverRegion	borderClip;
}
- (id) initWithWindow:(Window)aWindow forDisplay:(CompositeDisplay*) aDisplay;
- (void) paintSolidToPicture:(Picture)aPicture inRegion:(XserverRegion)region;
- (void) paintTranslucentToPicture:(Picture)aPicture;
- (void) paintShadowToPicture:(Picture)aPicture;
- (void) setIconified:(BOOL)aFlag;
- (void) setOpacityFromProperty;
- (void) updateBorders;
- (void) updatePictureIfNeeded;
- (void) determineType;
- (void) map;
- (Window) windowID;
- (void) repair;
@end
