#import "CompositeWindow.h"
#import "CompositeDisplay.h"
#include "IgnoreEvents.h"

//FIXME: Make this less of an hack
extern Display * dpy;
extern Window root;
extern NSSet * unshadowedApps;

/* find these once and be done with it */
Atom		opacityAtom;
Atom		winTypeAtom;
Atom		winDesktopAtom;
Atom		winDockAtom;
Atom		winToolbarAtom;
Atom		winMenuAtom;
Atom		winUtilAtom;
Atom		winSplashAtom;
Atom		winDialogAtom;
Atom		winNormalAtom;
Atom		winActiveAtom;

#define FREE_PICTURE(pict) do { if(pict != None) { XRenderFreePicture(dpy, pict); pict = None; } }  while(0)

//Black picture used for painting shadows
Picture		blackPicture;

Picture
solid_picture(Display * dpy, Bool argb, double a, double r, double g, double b)
{
	Pixmap		pixmap;
	Picture		picture;
	XRenderPictureAttributes pa;
	XRenderColor	c;

	pixmap = XCreatePixmap(dpy, root, 1, 1, argb ? 32 : 8);
	if (!pixmap)
		return None;

	pa.repeat = True;
	picture = XRenderCreatePicture(dpy, pixmap,
				       XRenderFindStandardFormat(dpy, argb ? PictStandardARGB32 : PictStandardA8),
				       CPRepeat,
				       &pa);
	if (!picture)
	{
		XFreePixmap(dpy, pixmap);
		return None;
	}
	c.alpha = a * 0xffff;
	c.red = r * 0xffff;
	c.green = g * 0xffff;
	c.blue = b * 0xffff;
	XRenderFillRectangle(dpy, PictOpSrc, picture, &c, 0, 0, 1, 1);
	XFreePixmap(dpy, pixmap);
	return picture;
}

@implementation CompositeWindow 
+ (void) initialize
{
	/* get atoms */

	opacityAtom = XInternAtom(dpy, "_NET_WM_WINDOW_OPACITY", False);
	winTypeAtom = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE", False);
	winDesktopAtom = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_DESKTOP", False);
	winDockAtom = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_DOCK", False);
	winToolbarAtom = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_TOOLBAR", False);
	winMenuAtom = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_MENU", False);
	winUtilAtom = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_UTILITY", False);
	winSplashAtom = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_SPLASH", False);
	winDialogAtom = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_DIALOG", False);
	winNormalAtom = XInternAtom(dpy, "_NET_WM_WINDOW_TYPE_NORMAL", False);
	winActiveAtom = XInternAtom(dpy, "_NET_ACTIVE_WINDOW", False);
#if DEBUG_LOG_ATOM_VALUES
#define LOG_ATOM_VALUE(x) NSLog(@"%s = %d", #x, x);
	LOG_ATOM_VALUE(winDesktopAtom);
	LOG_ATOM_VALUE(winDockAtom);
	LOG_ATOM_VALUE(winToolbarAtom);
	LOG_ATOM_VALUE(winMenuAtom);
	LOG_ATOM_VALUE(winUtilAtom);
	LOG_ATOM_VALUE(winSplashAtom);
	LOG_ATOM_VALUE(winDockAtom);
	LOG_ATOM_VALUE(winNormalAtom);
	LOG_ATOM_VALUE(winActiveAtom);
#undef LOG_ATOM_VALUE
#endif
	blackPicture = solid_picture(dpy, True, 1, 0, 0, 0);
	[super initialize];
}
- (id) initWithWindow:(Window) aWindow forDisplay:(CompositeDisplay*)aDisplay
{
	if(nil == (self = [self init]))
	{
		return nil;
	}

	ASSIGN(display, aDisplay);
	windowID = aWindow;
	set_ignore(dpy, NextRequest(dpy));

	if (!XGetWindowAttributes(dpy, windowID, &a))
	{
		[self release];
		return nil;
	}
	if (a.class != InputOnly)
	{
		damage_sequence = NextRequest(dpy);
		damage = XDamageCreate(dpy, windowID, XDamageReportNonEmpty);
	}
	opacity = OPAQUE;

	/* moved mode setting to one place */
	[self setOpacityFromProperty];
	[self determineType];
	//determine_mode(dpy, new);

	if (a.map_state == IsViewable)
	{
		[self map];
	}
	return self;
}
/**
 * Handle mapping events.
 */
- (void) map
{
	Drawable	back;

	a.map_state = IsViewable;

	/* This needs to be here or else we lose transparency messages */
	XSelectInput(dpy, windowID, PropertyChangeMask);

	damaged = 0;

	/*
	if (fade && fadeWindows)
		set_fade(dpy, w, 0, get_opacity_percent(dpy, w, 1.0), fade_in_step, 0, False, True, True);
	*/
}
- (Window) windowID
{
	return windowID;
}

- (void) setOpacityFromProperty
{
	Atom		actual;
	int		format;
	unsigned long	n, left;

	unsigned char  *data;
	int		result = XGetWindowProperty(dpy, windowID, opacityAtom, 0L, 1L, False,
					 XA_CARDINAL, &actual, &format,
					 &n, &left, &data);

	if (result == Success && data != NULL)
	{
		memcpy(&opacity, data, sizeof(uint32_t));
		XFree((void *)data);
	}
	else
	{
		opacity = OPAQUE;
	}
}
- (XserverRegion) configureWithEvent:(XConfigureEvent*) ce
{
	XserverRegion eventDamage = None;

	eventDamage = XFixesCreateRegion(dpy, 0, 0);
	if (extents != None)
	{
			XFixesCopyRegion(dpy, eventDamage, extents);
	}
	a.x = ce->x;
	a.y = ce->y;
	if (a.width != ce->width || a.height != ce->height)
	{
		if (pixmap)
		{
			XFreePixmap(dpy, pixmap);
			pixmap = None;
			if (picture)
			{
				XRenderFreePicture(dpy, picture);
				picture = None;
			}
		}
		if (shadowPict)
		{
			XRenderFreePicture(dpy, shadowPict);
			shadow = None;
		}
	}
	a.width = ce->width;
	a.height = ce->height;
	a.border_width = ce->border_width;
	a.override_redirect = ce->override_redirect;
	return damage;
}

- (void) generateShadow
{
	//TODO: Set forground shadow outside this class
	shadowPicture = [shadow pictureForOpacity:opacity
									   	width:a.width + a.border_width * 2
									   height:a.height + a.border_width * 2];
}

- (void) computeExtents
{
	XRectangle	r;

	r.x = a.x;
	r.y = a.y;
	r.width = a.width + a.border_width * 2;
	r.height = a.height + a.border_width * 2;

	if(shadow)
	{
		if (mode != WINDOW_ARGB)
		{
			if (!shadowPicture)
			{
				[self generateShadow];
			}
			r = [shadow rectangleForWindowWithRectangle:&r];
		}
	}
	if(isIconified)
	{
		//Calculate the clipping rectangle
		if(a.width > a.height)
		{
			r.height =(int) (((double)a.height/(double)a.width) * (double)ICON_SIZE);
			r.width = ICON_SIZE;
		}
		else
		{
			r.width =(int)(((double)a.width/(double)a.height) * (double)ICON_SIZE);
			r.height = ICON_SIZE;
		}
	}
	extents = XFixesCreateRegion(dpy, &r, 1);
}


/**
 * Set the type of this window based on the type of another window.  Used
 * recursively to set a type based on the type of a child window.
 */
- (void) determineWindowTypeFromWindow:(Window)aWindow
{
	Window		root_return, parent_return;
	Window         *children = NULL;
	unsigned int	nchildren, i;

	windowType = winNormalAtom;

	/*
	 * Hack to hide shadows on menu and dock.
	 */
	XClassHint *class_hint = XAllocClassHint();
	int result =  XGetClassHint(dpy,aWindow,class_hint);
	if((result != 0))
	{
		owner = [NSString stringWithCString:class_hint->res_name];
		XFree(class_hint);
		//NSLog(@"Window %x owned by %@", w, process);
		if([unshadowedApps containsObject:owner])
		{
			windowType = winDockAtom;
			return;
		}
	}

	/*
	 * Check for a special window type property.
	 */
	Atom		actual;
	int		format;
	unsigned long	n, left;
	unsigned char  *data;
	result = XGetWindowProperty(dpy, aWindow, winTypeAtom, 0L, 1L, False, XA_ATOM, &actual, &format,
					 &n, &left, &data);
	if (result == Success && data != None)
	{
		Atom		a;

		memcpy(&windowType, data, sizeof(Atom));
		XFree((void *)data);
		return;
	}
	/*
	 * Check if any of the child windows have anything interesting about them.
	 */

	if (!XQueryTree(dpy, aWindow, &root_return, &parent_return, &children,
			&nchildren))
	{
		/* XQueryTree failed. */
		if (children)
			XFree((void *)children);
		return;
	}
	for (i = 0; i < nchildren; i++)
	{
		[self determineWindowTypeFromWindow:children[i]];
		if (windowType != winNormalAtom)
		{
			//TODO: Check this
			XFree((void *)children);
			return;
		}
	}
	if (children)
		XFree((void *)children);
}
- (void) determineType
{
	[self determineWindowTypeFromWindow:windowID];
}

- (void) determineMode
{
	XRenderPictFormat *format;

	/* if trans prop == -1 fall back on  previous tests */

	FREE_PICTURE(alphaPict);
	FREE_PICTURE(shadowPict);
	if (a.class == InputOnly)
	{
		format = 0;
	}
	else
	{
		format = XRenderFindVisualFormat(dpy, a.visual);
	}

	if (format && format->type == PictTypeDirect && format->direct.alphaMask)
	{
		mode = WINDOW_ARGB;
	}
	else if (opacity != OPAQUE)
	{
		mode = WINDOW_TRANS;
	}
	else
	{
		mode = WINDOW_SOLID;
	}
	if (extents)
	{
		/*
		XserverRegion	damage;

		damage = XFixesCreateRegion(dpy, 0, 0);
		XFixesCopyRegion(dpy, damage, extents);
		add_damage(dpy, damage);
		*/
	}
}

- (void) setIconified:(BOOL)aFlag
{
	if(aFlag == isIconified)
	{
		return;
	}
	isIconified = aFlag;
	FREE_PICTURE(picture);
	[self computeExtents];
	if(aFlag)
	{
		realX = a.x;
		realY = a.y;
		//Hide iconified windows off the screen
		XMoveWindow(dpy, windowID, -500,-500);
	}
	else
	{
		//Bring it back
		XMoveWindow(dpy, windowID, realX, realY);
	}
}

- (void) paintShadowToPicture:(Picture)aPicture;
{
	if (shadow && windowType != winDesktopAtom && !isIconified)
	{
		XRenderComposite(dpy, PictOpOver, blackPicture, shadowPict, aPicture,
					 0, 0, 0, 0,
					  a.x + shadow->borderSize,
					  a.y + shadow->borderSize,
					  a.width + shadow->borderSize,
					  a.height + shadow->borderSize);
	}
}

- (void) updatePicture
{
	BOOL hasNamePixmap = YES;
	XRenderPictureAttributes pa;
	XRenderPictFormat *format;
	Drawable	draw = windowID;

	if (hasNamePixmap && !pixmap)
	{
		pixmap = XCompositeNameWindowPixmap(dpy, windowID);
	}
	if (pixmap)
	{
		draw = pixmap;
	}
	format = XRenderFindVisualFormat(dpy, a.visual);
	pa.subwindow_mode = IncludeInferiors;
	picture = XRenderCreatePicture(dpy, draw,
					  format,
					  CPSubwindowMode,
					  &pa);
}
- (void) updatePictureIfNeeded
{
	if(!picture)
	{
		[self updatePicture];
	}
}
- (void) updateBorders
{
	if (borderSize)
	{
		set_ignore(dpy, NextRequest(dpy));
		XFixesDestroyRegion(dpy, borderSize);
		borderSize = None;
	}
	if (extents)
	{
		XFixesDestroyRegion(dpy, extents);
		extents = None;
	}
	if (borderClip)
	{
		XFixesDestroyRegion(dpy, borderClip);
		borderClip = None;
	}
}
- (void) paintTranslucentToPicture:(Picture)aPicture 
{
	if (opacity != OPAQUE && !alphaPict)
		alphaPict = solid_picture(dpy, False,
				  (double)opacity / OPAQUE, 0, 0, 0);
	if (mode == WINDOW_TRANS || mode == WINDOW_ARGB)
	{
		int		x, y, wid, hei;

		x = a.x;
		y = a.y;
		wid = a.width + a.border_width * 2;
		hei = a.height + a.border_width * 2;
		set_ignore(dpy, NextRequest(dpy));
		XRenderComposite(dpy, PictOpOver, picture, alphaPict, aPicture,
				 0, 0, 0, 0,
				 x, y, wid, hei);
	}
}
//TODO: Pull the clip region out of this somehow
- (void) paintSolidToPicture:(Picture)aPicture inRegion:(XserverRegion)region
{
	if (!borderSize)
	{
		set_ignore(dpy, NextRequest(dpy));
		borderSize = XFixesCreateRegionFromWindow(dpy, windowID, WindowRegionBounding);
		/* translate this */
		set_ignore(dpy, NextRequest(dpy));
		XFixesTranslateRegion(dpy, borderSize,
					  a.x + a.border_width,
					  a.y + a.border_width);
	}
	if (!extents)
	{
		[self computeExtents];
	}
	if (mode == WINDOW_SOLID)
	{
		int x, y, wid, hei;

		x = a.x;
		y = a.y;
		wid = a.width + a.border_width * 2;
		hei = a.height + a.border_width * 2;
		XFixesSetPictureClipRegion(dpy, aPicture, 0, 0, region);
		set_ignore(dpy, NextRequest(dpy));
		//TODO: Move drawing of miniwindows elsewhere.
		//Scale miniwindows down to ICON_SIZE
		if(isIconified)
		{
			int size = MAX(a.width, a.height);
			XTransform shrink = (XTransform){{
				{ XDoubleToFixed( 1 ), XDoubleToFixed( 0 ), XDoubleToFixed(     0 ) },
				{ XDoubleToFixed( 0 ), XDoubleToFixed( 1 ), XDoubleToFixed(     0 ) },
				{ XDoubleToFixed( 0 ), XDoubleToFixed( 0 ), XDoubleToFixed(   (double)ICON_SIZE/ (double)size) }
			}};
			//Apply the scaling transform
			XRenderSetPictureTransform(dpy, picture, &shrink);
			//Calculate the clipping rectangle
			if(wid > hei)
			{
				hei =(int) (((double)hei/(double)wid) * (double)ICON_SIZE);
				wid = ICON_SIZE;
			}
			else
			{
				wid =(int)(((double)wid/(double)hei) * (double)ICON_SIZE);
				hei = ICON_SIZE;
			}
			x = realX;
			y = realY;
			XRectangle r;
			r.x = x;
			r.y = y;
			r.width = wid;
			r.height = hei;
			XserverRegion clip = XFixesCreateRegion(dpy, &r, 1);
			XFixesSubtractRegion(dpy, region, region, clip);
			XFixesDestroyRegion(dpy, clip);
		}
		else
		{
			XFixesSubtractRegion(dpy, region, region, borderSize);
		}
		set_ignore(dpy, NextRequest(dpy));
		XRenderComposite(dpy, PictOpSrc, picture, None, aPicture,
				 0, 0, 0, 0,
				 x, y, wid, hei);
	}
	if (!borderClip)
	{
		borderClip = XFixesCreateRegion(dpy, 0, 0);
		XFixesCopyRegion(dpy, borderClip, region);
	}

}

- (void) repair
{

	if (!damaged)
	{
		[self computeExtents];
		set_ignore(dpy, NextRequest(dpy));
		XDamageSubtract(dpy, damage, None, None);
		[display addDamage:extents];
	}
	else
	{
		XserverRegion	parts;

		parts = XFixesCreateRegion(dpy, 0, 0);
		set_ignore(dpy, NextRequest(dpy));
		XDamageSubtract(dpy, damage, None, parts);
		XFixesTranslateRegion(dpy, parts,
				      a.x + a.border_width,
				      a.y + a.border_width);
		[display addDamage:parts];
	}
	damaged = 1;
}

- (void) dealloc
{
	if (extents != None)
	{
		[display addDamage:extents];	/* destroys region */
	}
	if (pixmap)
	{
		XFreePixmap(dpy, pixmap);
	}
	if (picture)
	{
		set_ignore(dpy, NextRequest(dpy));
		XRenderFreePicture(dpy, picture);
	}
	set_ignore(dpy, NextRequest(dpy));
	XSelectInput(dpy, windowID, 0);
	if (alphaPict)
	{
		XRenderFreePicture(dpy, alphaPict);
	}
	if (shadowPict)
	{
		XRenderFreePicture(dpy, shadowPict);
	}
	if (damage != None)
	{
		set_ignore(dpy, NextRequest(dpy));
		XDamageDestroy(dpy, damage);
	}
	if (borderClip)
	{
		XFixesDestroyRegion(dpy, borderClip);
	}
	if (borderSize)
	{
		set_ignore(dpy, NextRequest(dpy));
		XFixesDestroyRegion(dpy, borderSize);
		borderSize = None;
	}
	[display release];
	[super dealloc];
}
@end
