#import "CompositeDisplay.h"
#import "CompositeWindow.h"

static char    *backgroundProps[] = {
	"_XROOTPMAP_ID",
	"_XSETROOT_ID",
	0,
};

static		Picture
root_tile(Display * dpy, int scr, Window root)
{
	Picture		picture;
	Atom		actual_type;
	Pixmap		pixmap;
	int		actual_format;
	unsigned long	nitems;
	unsigned long	bytes_after;
	unsigned char  *prop;
	Bool		fill;
	XRenderPictureAttributes pa;
	int		p;

	pixmap = None;
	for (p = 0; backgroundProps[p]; p++)
	{
		if (XGetWindowProperty(dpy, root, XInternAtom(dpy, backgroundProps[p], False),
				       0, 4, False, AnyPropertyType,
				       &actual_type, &actual_format, &nitems, &bytes_after, &prop) == Success &&
		    actual_type == XInternAtom(dpy, "PIXMAP", False) && actual_format == 32 && nitems == 1)
		{
			memcpy(&pixmap, prop, 4);
			XFree(prop);
			fill = False;
			break;
		}
	}
	if (!pixmap)
	{
		pixmap = XCreatePixmap(dpy, root, 1, 1, DefaultDepth(dpy, scr));
		fill = True;
	}
	pa.repeat = True;
	picture = XRenderCreatePicture(dpy, pixmap,
				       XRenderFindVisualFormat(dpy,
						   DefaultVisual(dpy, scr)),
				       CPRepeat, &pa);
	if (fill)
	{
		XRenderColor	c;

		c.red = c.green = c.blue = 0x8080;
		c.alpha = 0xffff;
		XRenderFillRectangle(dpy, PictOpSrc, picture, &c,
				     0, 0, 1, 1);
	}
	return picture;
}
@implementation CompositeDisplay
- (id) init
{
	if(nil == (self = [super init]))
	{
		return nil;
	}
	//References to windows
	windows = [[NSMutableArray alloc] init];
	windowsByID = NSCreateMapTable(NSIntMapKeyCallBacks, NSObjectMapValueCallBacks, 100);
	//Set up the display size
	root_width = DisplayWidth(dpy, scr);
	root_height = DisplayHeight(dpy, scr);

	//Get the root picture
	XRenderPictureAttributes pa;
	pa.subwindow_mode = IncludeInferiors;

	rootPicture = XRenderCreatePicture(dpy, root,
					   XRenderFindVisualFormat(dpy,
						   DefaultVisual(dpy, scr)),
					   CPSubwindowMode,
					   &pa);
	allDamage = None;
	return self;
}
- (id) initForDisplay:(char*)display
{
	if(nil == (self = [self init]))
	{
		return nil;
	}
	dpy = XOpenDisplay(display);
	return self;
}
- (CompositeWindow*) windowForID:(Window)aWindow
{
	return NSMapGet(windowsByID, (void*)aWindow);
}
- (void) addWindow:(CompositeWindow*)aWindow
{
	[windows addObject:aWindow];
	NSMapInsert(windowsByID, (void*)[aWindow windowID], aWindow);
}
- (void) moveWindow:(CompositeWindow*)aWindow above:(CompositeWindow*)otherWindow
{
	[windows removeObjectIdenticalTo:aWindow];
	int index = [windows indexOfObjectIdenticalTo:otherWindow];
	[windows insertObject:aWindow atIndex:index];
}
- (void) paintAllInRegion:(XserverRegion)region
{
	if (!region)
	{
		XRectangle	r;

		r.x = 0;
		r.y = 0;
		r.width = root_width;
		r.height = root_height;
		region = XFixesCreateRegion(dpy, &r, 1);
	}
	//Set up the root window background image
	if (!rootBuffer)
	{
		Pixmap		rootPixmap = XCreatePixmap(dpy, root, root_width, root_height,
						   DefaultDepth(dpy, scr));

		rootBuffer = XRenderCreatePicture(dpy, rootPixmap,
						XRenderFindVisualFormat(dpy,
						   DefaultVisual(dpy, scr)),
						  0, 0);
		XFreePixmap(dpy, rootPixmap);
	}
	XFixesSetPictureClipRegion(dpy, rootPicture, 0, 0, region);

	NSEnumerator * enumerator = [windows objectEnumerator];
	CompositeWindow * win;
	while((win = [enumerator nextObject]))
	{
		/* never painted, ignore it */
		/*
		 * TODO: Only add windows to the windows array if they are visible
		if (!w->damaged)
			continue;
		*/
		/* if invisible, ignore it */
		/*
		if (
			!w->isIconified &&
			(w->a.x + w->a.width < 1 || w->a.y + w->a.height < 1
		    || w->a.x >= root_width || w->a.y >= root_height)
			)
			continue;
		*/
		//Create the picture, if we haven't already
		[win updatePictureIfNeeded];
		[win paintSolidToPicture:rootPicture inRegion:region];
		//If a window has been resized or moved, this window's clipping regions
		//might be wrong.
		if (clipChanged)
		{
			[win updateBorders];
		}
	}
	XFixesSetPictureClipRegion(dpy, rootBuffer, 0, 0, region);
	if (!rootTile)
		rootTile = root_tile(dpy, scr, root);

	XRenderComposite(dpy, PictOpSrc,
			 rootTile, None, rootBuffer,
			 0, 0, 0, 0, 0, 0, root_width, root_height);

	enumerator = [windows reverseObjectEnumerator];
	while((win = [enumerator nextObject]))
	{
		XFixesSetPictureClipRegion(dpy, rootBuffer, 0, 0, win->borderClip);
		[win paintShadowToPicture:rootBuffer];
		[win paintTranslucentToPicture:rootBuffer];
		XFixesDestroyRegion(dpy, win->borderClip);
		win->borderClip = None;
	}
	XFixesDestroyRegion(dpy, region);
	if (rootBuffer != rootPicture)
	{
		XFixesSetPictureClipRegion(dpy, rootBuffer, 0, 0, None);
		XRenderComposite(dpy, PictOpSrc, rootBuffer, None, rootPicture,
				 0, 0, 0, 0, 0, 0, root_width, root_height);
	}
}

- (void) circulateWindowWithEvent:(XCirculateEvent*)ce
{
	CompositeWindow * w = [[self windowForID:ce->window] retain];
	[windows removeObjectIdenticalTo:w];
	if (ce->place == PlaceOnTop)
	{
		[windows addObject:w];
	}
	else
	{
		[windows insertObject:w atIndex:0];
	}
	[w release];
	clipChanged = True;
}

- (void) unmapWindowWithID:(Window)aWindow
{
	CompositeWindow * w = [self windowForID:aWindow];

	//Do we need this?  We're about to throw the window in the bin...
	//w->a.map_state = IsUnmapped;
	[windows removeObjectIdenticalTo:w];
	//TODO: Fade windows that need fading, instead of unmapping them completely
	NSMapRemove(windowsByID, (void*)aWindow);
	clipChanged = True;
}
- (void) addDamage:(XserverRegion) damage
{
	if (allDamage)
	{
		XFixesUnionRegion(dpy, allDamage, allDamage, damage);
		XFixesDestroyRegion(dpy, damage);
	}
	else
		allDamage = damage;
}
@end
