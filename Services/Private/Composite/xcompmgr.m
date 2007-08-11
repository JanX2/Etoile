/*
 * $Id: xcompmgr.c,v 1.40 2005/10/07 00:08:02 anholt Exp $
 * 
 * Copyright © 2003 Keith Packard
 * 
 * Permission to use, copy, modify, distribute, and sell this software and its
 * documentation for any purpose is hereby granted without fee, provided that
 * the above copyright notice appear in all copies and that both that
 * copyright notice and this permission notice appear in supporting
 * documentation, and that the name of Keith Packard not be used in
 * advertising or publicity pertaining to distribution of the software
 * without specific, written prior permission.  Keith Packard makes no
 * representations about the suitability of this software for any purpose. It
 * is provided "as is" without express or implied warranty.
 * 
 * KEITH PACKARD DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE,
 * INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO
 * EVENT SHALL KEITH PACKARD BE LIABLE FOR ANY SPECIAL, INDIRECT OR
 * CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF
 * USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
 * OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */

/*
 * Modified by Matthew Hawn. I don't know what to say here so follow what it
 * says above. Not that I can really do anything about it
 */


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <sys/poll.h>
#include <sys/time.h>
#include <time.h>
#include <unistd.h>
#include <getopt.h> // for getopt and optarg on Ubuntu/Linux
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/extensions/Xcomposite.h>
#include <X11/extensions/Xdamage.h>
#include <X11/extensions/Xrender.h>
#import <Foundation/Foundation.h>

#if COMPOSITE_MAJOR > 0 || COMPOSITE_MINOR >= 2
#define HAS_NAME_WINDOW_PIXMAP 1
#endif

#ifndef M_PI
#define  M_PI 3.14159265358979323846  /* glibc is a waste of space */
#endif

NSSet * unshadowedApps;

typedef struct _ignore
{
	struct _ignore *next;
	unsigned long	sequence;
}		ignore;

typedef struct _win
{
	struct _win    *next;
	Window		id;
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
	Picture		shadow;
	int		shadow_dx;
	int		shadow_dy;
	int		shadow_width;
	int		shadow_height;
	unsigned int	opacity;
	Atom		windowType;

	BOOL isIconified;
	int realX, realY;

	unsigned long	damage_sequence;	/* sequence when damage was
						 * created */

	/* for drawing translucent windows */
	XserverRegion	borderClip;
	struct _win    *prev_trans;
}		win;

typedef struct _conv
{
	int		size;
	double         *data;
}		conv;

typedef struct _fade
{
	struct _fade   *next;
	win            *w;
	double		cur;
	double		finish;
	double		step;
	void            (*callback) (Display * dpy, win * w, Bool gone);
	Display        *dpy;
	Bool		gone;
}		fade;



win            *list;
fade           *fades;
Display        *dpy;
int		scr;
Window		root;
Picture		rootPicture;
Picture		rootBuffer;
Picture		blackPicture;
Picture		transBlackPicture;
Picture		rootTile;
XserverRegion	allDamage;
Bool		clipChanged;

#if HAS_NAME_WINDOW_PIXMAP
Bool		hasNamePixmap;

#endif
int		root_height, root_width;
ignore         *ignore_head, **ignore_tail = &ignore_head;
int		xfixes_event, xfixes_error;
int		damage_event, damage_error;
int		composite_event, composite_error;
int		render_event, render_error;
Bool		synchronize;
int		composite_opcode;

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

/* opacity property name; sometime soon I'll write up an EWMH spec for it */
#define OPACITY_PROP	"_NET_WM_WINDOW_OPACITY"

#define TRANSLUCENT	0xe0000000
#define OPAQUE		0xffffffff

#define ICON_SIZE	64

conv           *defaultGaussianMap;
conv           *foregroundGaussianMap;

win * foregroundWindow = NULL;

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

typedef enum _compMode
{
	CompSimple,		/* looks like a regular X server */
	CompClientShadows,	/* use window extents for shadow, blurred */
}		CompMode;

static void
		determine_mode(Display * dpy, win * w);

static double
		get_opacity_percent(Display * dpy, win * w, double def);

static		XserverRegion
		win_extents   (Display * dpy, win * w);

CompMode	compMode = CompClientShadows;

int		shadowRadius = 3;
int		shadowOffsetX = -4;
int		shadowOffsetY = -4;
int		forgroundShadowRadius = 12;
int		foregroundShadowOffsetX = -15;
int		foregroundShadowOffsetY = -15;
double		foregroundShadowOpacity = .9;
double		shadowOpacity = .75;

double		fade_in_step = 0.028;
double		fade_out_step = 0.03;
int		fade_delta = 10;
int		fade_time = 0;
Bool		fadeWindows = False;
Bool		excludeDockShadows = True;
Bool		fadeTrans = False;

Bool		autoRedirect = False;

/* For shadow precomputation */
int		Gsize = -1;
unsigned char  *shadowCorner = NULL;
unsigned char  *shadowTop = NULL;

int
get_time_in_milliseconds()
{
	struct timeval	tv;

	gettimeofday(&tv, NULL);
	return tv.tv_sec * 1000 + tv.tv_usec / 1000;
}

fade           *
find_fade(win * w)
{
	fade           *f;

	for (f = fades; f; f = f->next)
	{
		if (f->w == w)
			return f;
	}
	return 0;
}

void
dequeue_fade(Display * dpy, fade * f)
{
	fade          **prev;

	for (prev = &fades; *prev; prev = &(*prev)->next)
		if (*prev == f)
		{
			*prev = f->next;
			if (f->callback)
				(*f->callback) (dpy, f->w, f->gone);
			free(f);
			break;
		}
}

void
cleanup_fade(Display * dpy, win * w)
{
	fade           *f = find_fade(w);

	if (f)
		dequeue_fade(dpy, f);
}

void
enqueue_fade(Display * dpy, fade * f)
{
	if (!fades)
		fade_time = get_time_in_milliseconds() + fade_delta;
	f->next = fades;
	fades = f;
}

static void
set_fade(Display * dpy, win * w, double start, double finish, double step,
	 void (*callback) (Display * dpy, win * w, Bool gone),
	 Bool gone, Bool exec_callback, Bool override)
{
	fade           *f;

	f = find_fade(w);
	if (!f)
	{
		f = malloc(sizeof(fade));
		f->next = 0;
		f->w = w;
		f->cur = start;
		enqueue_fade(dpy, f);
	}
	else if (!override)
		return;
	else
	{
		if (exec_callback)
			if (f->callback)
				(*f->callback) (dpy, f->w, f->gone);
	}

	if (finish < 0)
		finish = 0;
	if (finish > 1)
		finish = 1;
	f->finish = finish;
	if (f->cur < finish)
		f->step = step;
	else if (f->cur > finish)
		f->step = -step;
	f->callback = callback;
	f->gone = gone;
	w->opacity = f->cur * OPAQUE;
#if 0
	printf("set_fade start %g step %g\n", f->cur, f->step);
#endif
	determine_mode(dpy, w);
	if (w->shadow)
	{
		XRenderFreePicture(dpy, w->shadow);
		w->shadow = None;
		w->extents = win_extents(dpy, w);
	}
}

int
fade_timeout(void)
{
	int		now;
	int		delta;

	if (!fades)
		return -1;
	now = get_time_in_milliseconds();
	delta = fade_time - now;
	if (delta < 0)
		delta = 0;
	/* printf ("timeout %d\n", delta); */
	return delta;
}

void
run_fades(Display * dpy)
{
	int		now = get_time_in_milliseconds();
	fade           *f, *next;
	int		steps;
	Bool		need_dequeue;

#if 0
	printf("run fades\n");
#endif
	if (fade_time - now > 0)
		return;
	steps = 1 + (now - fade_time) / fade_delta;
	for (next = fades; (f = next);)
	{
		win            *w = f->w;

		next = f->next;
		f->cur += f->step * steps;
		if (f->cur >= 1)
			f->cur = 1;
		else if (f->cur < 0)
			f->cur = 0;
#if 0
		printf("opacity now %g\n", f->cur);
#endif
		w->opacity = f->cur * OPAQUE;
		need_dequeue = False;
		if (f->step > 0)
		{
			if (f->cur >= f->finish)
			{
				w->opacity = f->finish * OPAQUE;
				need_dequeue = True;
			}
		}
		else
		{
			if (f->cur <= f->finish)
			{
				w->opacity = f->finish * OPAQUE;
				need_dequeue = True;
			}
		}
		determine_mode(dpy, w);
		if (w->shadow)
		{
			XRenderFreePicture(dpy, w->shadow);
			w->shadow = None;
			w->extents = win_extents(dpy, w);
		}
		/* Must do this last as it might destroy f->w in callbacks */
		if (need_dequeue)
			dequeue_fade(dpy, f);
	}
	fade_time = now + fade_delta;
}

static double
gaussian(double r, double x, double y)
{
	return ((1 / (sqrt(2 * M_PI * r))) *
		exp((-(x * x + y * y)) / (2 * r * r)));
}


static conv    *
make_gaussian_map(Display * dpy, double r)
{
	conv           *c;
	int		size = ((int)ceil((r * 3)) + 1) & ~1;
	int		center = size / 2;
	int		x         , y;
	double		t;
	double		g;

	c = malloc(sizeof(conv) + size * size * sizeof(double));
	c->size = size;
	c->data = (double *)(c + 1);
	t = 0.0;
	for (y = 0; y < size; y++)
		for (x = 0; x < size; x++)
		{
			g = gaussian(r, (double)(x - center), (double)(y - center));
			t += g;
			c->data[y * size + x] = g;
		}
	/* printf ("gaussian total %f\n", t); */
	for (y = 0; y < size; y++)
		for (x = 0; x < size; x++)
		{
			c->data[y * size + x] /= t;
		}
	return c;
}

/*
 * A picture will help
 * 
 * -center   0                width  width+center -center
 * +-----+-------------------+-----+ |     |                   |     | | |
 * |     | 0 +-----+-------------------+-----+ |     | |     | |     |
 * |     | |     |                   | | height
 * +-----+-------------------+-----+ |     |                   | | height+  |
 * |                   |     | center +-----+-------------------+-----+
 */

static unsigned char
sum_gaussian(conv * map, double opacity, int x, int y, int width, int height)
{
	int		fx        , fy;
	double         *g_data;
	double         *g_line = map->data;
	int		g_size = map->size;
	int		center = g_size / 2;
	int		fx_start  , fx_end;
	int		fy_start  , fy_end;
	double		v;

	/*
	 * Compute set of filter values which are "in range", that's the set
	 * with: 0 <= x + (fx-center) && x + (fx-center) < width && 0 <= y +
	 * (fy-center) && y + (fy-center) < height
	 * 
	 * 0 <= x + (fx - center)	x + fx - center < width center - x <= fx fx <
	 * width + center - x
	 */

	fx_start = center - x;
	if (fx_start < 0)
		fx_start = 0;
	fx_end = width + center - x;
	if (fx_end > g_size)
		fx_end = g_size;

	fy_start = center - y;
	if (fy_start < 0)
		fy_start = 0;
	fy_end = height + center - y;
	if (fy_end > g_size)
		fy_end = g_size;

	g_line = g_line + fy_start * g_size + fx_start;

	v = 0;
	for (fy = fy_start; fy < fy_end; fy++)
	{
		g_data = g_line;
		g_line += g_size;

		for (fx = fx_start; fx < fx_end; fx++)
			v += *g_data++;
	}
	if (v > 1)
		v = 1;

	return ((unsigned char)(v * opacity * 255.0));
}

/* precompute shadow corners and sides to save time for large windows */
static void
presum_gaussian(conv * map)
{
	int		center = map->size / 2;
	int		opacity   , x, y;

	Gsize = map->size;

	if (shadowCorner)
		free((void *)shadowCorner);
	if (shadowTop)
		free((void *)shadowTop);

	shadowCorner = (unsigned char *)(malloc((Gsize + 1) * (Gsize + 1) * 26));
	shadowTop = (unsigned char *)(malloc((Gsize + 1) * 26));

	for (x = 0; x <= Gsize; x++)
	{
		shadowTop[25 * (Gsize + 1) + x] = sum_gaussian(map, 1, x - center, center, Gsize * 2, Gsize * 2);
		for (opacity = 0; opacity < 25; opacity++)
			shadowTop[opacity * (Gsize + 1) + x] = shadowTop[25 * (Gsize + 1) + x] * opacity / 25;
		for (y = 0; y <= x; y++)
		{
			shadowCorner[25 * (Gsize + 1) * (Gsize + 1) + y * (Gsize + 1) + x]
				= sum_gaussian(map, 1, x - center, y - center, Gsize * 2, Gsize * 2);
			shadowCorner[25 * (Gsize + 1) * (Gsize + 1) + x * (Gsize + 1) + y]
				= shadowCorner[25 * (Gsize + 1) * (Gsize + 1) + y * (Gsize + 1) + x];
			for (opacity = 0; opacity < 25; opacity++)
				shadowCorner[opacity * (Gsize + 1) * (Gsize + 1) + y * (Gsize + 1) + x]
					= shadowCorner[opacity * (Gsize + 1) * (Gsize + 1) + x * (Gsize + 1) + y]
					= shadowCorner[25 * (Gsize + 1) * (Gsize + 1) + y * (Gsize + 1) + x] * opacity / 25;
		}
	}
}

static XImage  *
make_shadow(Display * dpy, double opacity, int width, int height, Atom type)
{
	XImage         *ximage;
	unsigned char  *data;
	conv * gaussianMap = defaultGaussianMap;
	if(type == winActiveAtom)
	{
		gaussianMap = foregroundGaussianMap;
	}
	int		gsize = gaussianMap->size;
	int		ylimit    , xlimit;
	int		swidth = width + gsize;
	int		sheight = height + gsize;
	int		center = gsize / 2;
	int		x         , y;
	unsigned char	d;
	int		x_diff;
	int		opacity_int = (int)(opacity * 25);

	data = malloc(swidth * sheight * sizeof(unsigned char));
	if (!data)
		return 0;
	ximage = XCreateImage(dpy,
			      DefaultVisual(dpy, DefaultScreen(dpy)),
			      8,
			      ZPixmap,
			      0,
			      (char *)data,
			swidth, sheight, 8, swidth * sizeof(unsigned char));
	if (!ximage)
	{
		free(data);
		return 0;
	}
	/*
	 * Build the gaussian in sections
	 */

	/*
	 * center (fill the complete data array)
	 */
	if (Gsize > 0)
		d = shadowTop[opacity_int * (Gsize + 1) + Gsize];
	else
		d = sum_gaussian(gaussianMap, opacity, center, center, width, height);
	memset(data, d, sheight * swidth);

	/*
	 * corners
	 */
	ylimit = gsize;
	if (ylimit > sheight / 2)
		ylimit = (sheight + 1) / 2;
	xlimit = gsize;
	if (xlimit > swidth / 2)
		xlimit = (swidth + 1) / 2;

	for (y = 0; y < ylimit; y++)
		for (x = 0; x < xlimit; x++)
		{
			if (xlimit == Gsize && ylimit == Gsize)
				d = shadowCorner[opacity_int * (Gsize + 1) * (Gsize + 1) + y * (Gsize + 1) + x];
			else
				d = sum_gaussian(gaussianMap, opacity, x - center, y - center, width, height);
			data[y * swidth + x] = d;
			data[(sheight - y - 1) * swidth + x] = d;
			data[(sheight - y - 1) * swidth + (swidth - x - 1)] = d;
			data[y * swidth + (swidth - x - 1)] = d;
		}

	/*
	 * top/bottom
	 */
	x_diff = swidth - (gsize * 2);
	if (x_diff > 0 && ylimit > 0)
	{
		for (y = 0; y < ylimit; y++)
		{
			if (ylimit == Gsize)
				d = shadowTop[opacity_int * (Gsize + 1) + y];
			else
				d = sum_gaussian(gaussianMap, opacity, center, y - center, width, height);
			memset(&data[y * swidth + gsize], d, x_diff);
			memset(&data[(sheight - y - 1) * swidth + gsize], d, x_diff);
		}
	}
	/*
	 * sides
	 */

	for (x = 0; x < xlimit; x++)
	{
		if (xlimit == Gsize)
			d = shadowTop[opacity_int * (Gsize + 1) + x];
		else
			d = sum_gaussian(gaussianMap, opacity, x - center, center, width, height);
		for (y = gsize; y < sheight - gsize; y++)
		{
			data[y * swidth + x] = d;
			data[y * swidth + (swidth - x - 1)] = d;
		}
	}

	return ximage;
}

static		Picture
shadow_picture_for_type(Display * dpy, double opacity, Picture alpha_pict, int width, int height, int *wp, int *hp, Atom type)
{
	XImage         *shadowImage;
	Pixmap		shadowPixmap;
	Pixmap		finalPixmap;
	Picture		shadowPicture;
	Picture		finalPicture;
	GC		gc;

	shadowImage = make_shadow(dpy, opacity, width, height, type);
	if (!shadowImage)
		return None;
	shadowPixmap = XCreatePixmap(dpy, root,
				     shadowImage->width,
				     shadowImage->height,
				     8);
	if (!shadowPixmap)
	{
		XDestroyImage(shadowImage);
		return None;
	}
	shadowPicture = XRenderCreatePicture(dpy, shadowPixmap,
			     XRenderFindStandardFormat(dpy, PictStandardA8),
					     0, 0);
	if (!shadowPicture)
	{
		XDestroyImage(shadowImage);
		XFreePixmap(dpy, shadowPixmap);
		return None;
	}
	gc = XCreateGC(dpy, shadowPixmap, 0, 0);
	if (!gc)
	{
		XDestroyImage(shadowImage);
		XFreePixmap(dpy, shadowPixmap);
		XRenderFreePicture(dpy, shadowPicture);
		return None;
	}
	XPutImage(dpy, shadowPixmap, gc, shadowImage, 0, 0, 0, 0,
		  shadowImage->width,
		  shadowImage->height);
	*wp = shadowImage->width;
	*hp = shadowImage->height;
	XFreeGC(dpy, gc);
	XDestroyImage(shadowImage);
	XFreePixmap(dpy, shadowPixmap);
	return shadowPicture;
}
static		Picture
shadow_picture(Display * dpy, double opacity, Picture alpha_pict, int width, int height, int *wp, int *hp)
{
	return shadow_picture_for_type(dpy, opacity, alpha_pict, width, height, wp, hp, winNormalAtom);
}

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

void
discard_ignore(Display * dpy, unsigned long sequence)
{
	while (ignore_head)
	{
		if ((long)(sequence - ignore_head->sequence) > 0)
		{
			ignore         *next = ignore_head->next;

			free(ignore_head);
			ignore_head = next;
			if (!ignore_head)
				ignore_tail = &ignore_head;
		}
		else
			break;
	}
}

void
set_ignore(Display * dpy, unsigned long sequence)
{
	ignore         *i = malloc(sizeof(ignore));

	if (!i)
		return;
	i->sequence = sequence;
	i->next = 0;
	*ignore_tail = i;
	ignore_tail = &i->next;
}

int
should_ignore(Display * dpy, unsigned long sequence)
{
	discard_ignore(dpy, sequence);
	return ignore_head && ignore_head->sequence == sequence;
}

static win     *
find_win(Display * dpy, Window id)
{
	win            *w;

	for (w = list; w; w = w->next)
	{
		if (w->id == id)
		{
			return w;
		}
	}
	return 0;
}

static char    *backgroundProps[] = {
	"_XROOTPMAP_ID",
	"_XSETROOT_ID",
	0,
};

static		Picture
root_tile(Display * dpy)
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

static void
paint_root(Display * dpy)
{
	if (!rootTile)
		rootTile = root_tile(dpy);

	XRenderComposite(dpy, PictOpSrc,
			 rootTile, None, rootBuffer,
			 0, 0, 0, 0, 0, 0, root_width, root_height);
}

static		XserverRegion
win_extents(Display * dpy, win * w)
{
	XRectangle	r;

	r.x = w->a.x;
	r.y = w->a.y;
	r.width = w->a.width + w->a.border_width * 2;
	r.height = w->a.height + w->a.border_width * 2;
	if (compMode != CompSimple && !(w->windowType == winDockAtom && excludeDockShadows))
	{
		if (w->mode != WINDOW_ARGB)
		{
			XRectangle	sr;

			if(w == foregroundWindow)
			{
				w->shadow_dx = foregroundShadowOffsetX;
				w->shadow_dy = foregroundShadowOffsetY;
			}
			else
			{
				w->shadow_dx = shadowOffsetX;
				w->shadow_dy = shadowOffsetY;
			}
			if (!w->shadow)
			{
				double		opacity = shadowOpacity;
				if(w == foregroundWindow)
				{
					opacity = foregroundShadowOpacity;
				}

				if (w->mode == WINDOW_TRANS)
					opacity = opacity * ((double)w->opacity) / ((double)OPAQUE);
				if(w == foregroundWindow)
				{
					w->shadow = shadow_picture_for_type(dpy, opacity, w->alphaPict,
					 w->a.width + w->a.border_width * 2,
					w->a.height + w->a.border_width * 2,
					&w->shadow_width, &w->shadow_height, winActiveAtom);
				}
				else
				{
					w->shadow = shadow_picture(dpy, opacity, w->alphaPict,
					 w->a.width + w->a.border_width * 2,
					w->a.height + w->a.border_width * 2,
					&w->shadow_width, &w->shadow_height);
				}
			}
			sr.x = w->a.x + w->shadow_dx;
			sr.y = w->a.y + w->shadow_dy;
			sr.width = w->shadow_width;
			sr.height = w->shadow_height;
			if (sr.x < r.x)
			{
				r.width = (r.x + r.width) - sr.x;
				r.x = sr.x;
			}
			if (sr.y < r.y)
			{
				r.height = (r.y + r.height) - sr.y;
				r.y = sr.y;
			}
			if (sr.x + sr.width > r.x + r.width)
				r.width = sr.x + sr.width - r.x;
			if (sr.y + sr.height > r.y + r.height)
				r.height = sr.y + sr.height - r.y;
		}
	}
	if(w->isIconified)
	{
		//Calculate the clipping rectangle
		if(w->a.width > w->a.height)
		{
			r.height =(int) (((double)w->a.height/(double)w->a.width) * (double)ICON_SIZE);
			r.width = ICON_SIZE;
		}
		else
		{
			r.width =(int)(((double)w->a.width/(double)w->a.height) * (double)ICON_SIZE);
			r.height = ICON_SIZE;
		}
	}
	return XFixesCreateRegion(dpy, &r, 1);
}

static		XserverRegion
border_size(Display * dpy, win * w)
{
	XserverRegion	border;

	/*
	 * if window doesn't exist anymore,  this will generate an error as
	 * well as not generate a region.  Perhaps a better XFixes
	 * architecture would be to have a request that copies instead of
	 * creates, that way you'd just end up with an empty region instead
	 * of an invalid XID.
	 */
	set_ignore(dpy, NextRequest(dpy));
	border = XFixesCreateRegionFromWindow(dpy, w->id, WindowRegionBounding);
	/* translate this */
	set_ignore(dpy, NextRequest(dpy));
	XFixesTranslateRegion(dpy, border,
			      w->a.x + w->a.border_width,
			      w->a.y + w->a.border_width);
	return border;
}


static inline XTransform scale_for_window(win * w)
{
	int size = MAX(w->a.width, w->a.height);
	return (XTransform){{
		{ XDoubleToFixed( 1 ), XDoubleToFixed( 0 ), XDoubleToFixed(     0 ) },
		{ XDoubleToFixed( 0 ), XDoubleToFixed( 1 ), XDoubleToFixed(     0 ) },
		{ XDoubleToFixed( 0 ), XDoubleToFixed( 0 ), XDoubleToFixed(   (double)ICON_SIZE/ (double)size) }
	}};
}

static void
paint_all(Display * dpy, XserverRegion region)
{
	win            *w;
	win            *t = 0;

	if (!region)
	{
		XRectangle	r;

		r.x = 0;
		r.y = 0;
		r.width = root_width;
		r.height = root_height;
		region = XFixesCreateRegion(dpy, &r, 1);
	}
#if MONITOR_REPAINT
	rootBuffer = rootPicture;
#else
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
#endif
	XFixesSetPictureClipRegion(dpy, rootPicture, 0, 0, region);
#if MONITOR_REPAINT
	XRenderComposite(dpy, PictOpSrc, blackPicture, None, rootPicture,
			 0, 0, 0, 0, 0, 0, root_width, root_height);
#endif
#if DEBUG_REPAINT
	printf("paint:");
#endif
	for (w = list; w; w = w->next)
	{
		/* never painted, ignore it */
		if (!w->damaged)
			continue;
		/* if invisible, ignore it */
		if (
			!w->isIconified &&
			(w->a.x + w->a.width < 1 || w->a.y + w->a.height < 1
		    || w->a.x >= root_width || w->a.y >= root_height)
			)
			continue;
		if (!w->picture)
		{
			XRenderPictureAttributes pa;
			XRenderPictFormat *format;
			Drawable	draw = w->id;

#if HAS_NAME_WINDOW_PIXMAP
			if (hasNamePixmap && !w->pixmap)
				w->pixmap = XCompositeNameWindowPixmap(dpy, w->id);
			if (w->pixmap)
				draw = w->pixmap;
#endif
			format = XRenderFindVisualFormat(dpy, w->a.visual);
			pa.subwindow_mode = IncludeInferiors;
			w->picture = XRenderCreatePicture(dpy, draw,
							  format,
							  CPSubwindowMode,
							  &pa);
		}
#if DEBUG_REPAINT
		printf(" 0x%x", w->id);
#endif
		if (clipChanged)
		{
			if (w->borderSize)
			{
				set_ignore(dpy, NextRequest(dpy));
				XFixesDestroyRegion(dpy, w->borderSize);
				w->borderSize = None;
			}
			if (w->extents)
			{
				XFixesDestroyRegion(dpy, w->extents);
				w->extents = None;
			}
			if (w->borderClip)
			{
				XFixesDestroyRegion(dpy, w->borderClip);
				w->borderClip = None;
			}
		}
		if (!w->borderSize)
			w->borderSize = border_size(dpy, w);
		//if (!w->extents)
			w->extents = win_extents(dpy, w);
		if (w->mode == WINDOW_SOLID)
		{
			int		x         , y, wid, hei;

#if HAS_NAME_WINDOW_PIXMAP
			x = w->a.x;
			y = w->a.y;
			wid = w->a.width + w->a.border_width * 2;
			hei = w->a.height + w->a.border_width * 2;
#else
			x = w->a.x + w->a.border_width;
			y = w->a.y + w->a.border_width;
			wid = w->a.width;
			hei = w->a.height;
#endif
			XFixesSetPictureClipRegion(dpy, rootBuffer, 0, 0, region);
			set_ignore(dpy, NextRequest(dpy));
			//Scale miniwindows down to ICON_SIZE
			if(w->isIconified)
			{
				
				//Apply the scaling transform
				XTransform shrink = scale_for_window(w);
				XRenderSetPictureTransform(dpy, w->picture, &shrink);
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
				x = w->realX;
				y = w->realY;
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
				XFixesSubtractRegion(dpy, region, region, w->borderSize);
			}
			set_ignore(dpy, NextRequest(dpy));
			XRenderComposite(dpy, PictOpSrc, w->picture, None, rootBuffer,
					 0, 0, 0, 0,
					 x, y, wid, hei);
		}
		if (!w->borderClip)
		{
			w->borderClip = XFixesCreateRegion(dpy, 0, 0);
			XFixesCopyRegion(dpy, w->borderClip, region);
		}
		w->prev_trans = t;
		t = w;
	}
#if DEBUG_REPAINT
	printf("\n");
	fflush(stdout);
#endif
	XFixesSetPictureClipRegion(dpy, rootBuffer, 0, 0, region);
	paint_root(dpy);
	for (w = t; w; w = w->prev_trans)
	{
		XFixesSetPictureClipRegion(dpy, rootBuffer, 0, 0, w->borderClip);
		switch (compMode)
		{
			case CompSimple:
				break;
			case CompClientShadows:
				/*
				 * don't bother drawing shadows on desktop
				 * windows or iconfified windows.
				 */
				if (w->shadow && w->windowType != winDesktopAtom && !w->isIconified)
				{
					if(w == 0)
					{
						NSLog(@"Drawing shadow for window %x of type %d", w->id, w->windowType);
						XRenderComposite(dpy, PictOpOver, blackPicture, w->shadow, rootBuffer,
								 0, 0, 0, 0,
								  w->a.x + foregroundShadowOffsetX,
								  w->a.y + foregroundShadowOffsetY,
						 w->shadow_width, w->shadow_height);
					}
					else
					{
						XRenderComposite(dpy, PictOpOver, blackPicture, w->shadow, rootBuffer,
								 0, 0, 0, 0,
								  w->a.x + w->shadow_dx,
								  w->a.y + w->shadow_dy,
						 w->shadow_width, w->shadow_height);
					}
				}
				break;
		}
		if (w->opacity != OPAQUE && !w->alphaPict)
			w->alphaPict = solid_picture(dpy, False,
				      (double)w->opacity / OPAQUE, 0, 0, 0);
		if (w->mode == WINDOW_TRANS)
		{
			int		x         , y, wid, hei;

#if HAS_NAME_WINDOW_PIXMAP
			x = w->a.x;
			y = w->a.y;
			wid = w->a.width + w->a.border_width * 2;
			hei = w->a.height + w->a.border_width * 2;
#else
			x = w->a.x + w->a.border_width;
			y = w->a.y + w->a.border_width;
			wid = w->a.width;
			hei = w->a.height;
#endif
			set_ignore(dpy, NextRequest(dpy));
			XRenderComposite(dpy, PictOpOver, w->picture, w->alphaPict, rootBuffer,
					 0, 0, 0, 0,
					 x, y, wid, hei);
		}
		else if (w->mode == WINDOW_ARGB)
		{
			int		x         , y, wid, hei;

#if HAS_NAME_WINDOW_PIXMAP
			x = w->a.x;
			y = w->a.y;
			wid = w->a.width + w->a.border_width * 2;
			hei = w->a.height + w->a.border_width * 2;
#else
			x = w->a.x + w->a.border_width;
			y = w->a.y + w->a.border_width;
			wid = w->a.width;
			hei = w->a.height;
#endif
			set_ignore(dpy, NextRequest(dpy));
			XRenderComposite(dpy, PictOpOver, w->picture, w->alphaPict, rootBuffer,
					 0, 0, 0, 0,
					 x, y, wid, hei);
		}
		XFixesDestroyRegion(dpy, w->borderClip);
		w->borderClip = None;
	}
	XFixesDestroyRegion(dpy, region);
	if (rootBuffer != rootPicture)
	{
		XFixesSetPictureClipRegion(dpy, rootBuffer, 0, 0, None);
		XRenderComposite(dpy, PictOpSrc, rootBuffer, None, rootPicture,
				 0, 0, 0, 0, 0, 0, root_width, root_height);
	}
}

static void
add_damage(Display * dpy, XserverRegion damage)
{
	if (allDamage)
	{
		XFixesUnionRegion(dpy, allDamage, allDamage, damage);
		XFixesDestroyRegion(dpy, damage);
	}
	else
		allDamage = damage;
}

static void
repair_win(Display * dpy, win * w)
{
	XserverRegion	parts;

	if (!w->damaged)
	{
		parts = win_extents(dpy, w);
		set_ignore(dpy, NextRequest(dpy));
		XDamageSubtract(dpy, w->damage, None, None);
	}
	else
	{
		XserverRegion	o;

		parts = XFixesCreateRegion(dpy, 0, 0);
		set_ignore(dpy, NextRequest(dpy));
		XDamageSubtract(dpy, w->damage, None, parts);
		XFixesTranslateRegion(dpy, parts,
				      w->a.x + w->a.border_width,
				      w->a.y + w->a.border_width);
	}
	add_damage(dpy, parts);
	w->damaged = 1;
}

static void
map_win(Display * dpy, Window id, unsigned long sequence, Bool fade)
{
	win            *w = find_win(dpy, id);
	Drawable	back;

	if (!w)
		return;

	w->a.map_state = IsViewable;

	/* This needs to be here or else we lose transparency messages */
	XSelectInput(dpy, id, PropertyChangeMask);

	w->damaged = 0;

	if (fade && fadeWindows)
		set_fade(dpy, w, 0, get_opacity_percent(dpy, w, 1.0), fade_in_step, 0, False, True, True);
}

static void
finish_unmap_win(Display * dpy, win * w)
{
	w->damaged = 0;
	if (w->extents != None)
	{
		add_damage(dpy, w->extents);	/* destroys region */
		w->extents = None;
	}
#if HAS_NAME_WINDOW_PIXMAP
	if (w->pixmap)
	{
		XFreePixmap(dpy, w->pixmap);
		w->pixmap = None;
	}
#endif

	if (w->picture)
	{
		set_ignore(dpy, NextRequest(dpy));
		XRenderFreePicture(dpy, w->picture);
		w->picture = None;
	}
	/* don't care about properties anymore */
	set_ignore(dpy, NextRequest(dpy));
	XSelectInput(dpy, w->id, 0);

	if (w->borderSize)
	{
		set_ignore(dpy, NextRequest(dpy));
		XFixesDestroyRegion(dpy, w->borderSize);
		w->borderSize = None;
	}
	if (w->shadow)
	{
		XRenderFreePicture(dpy, w->shadow);
		w->shadow = None;
	}
	if (w->borderClip)
	{
		XFixesDestroyRegion(dpy, w->borderClip);
		w->borderClip = None;
	}
	clipChanged = True;
}

#if HAS_NAME_WINDOW_PIXMAP
static void
unmap_callback(Display * dpy, win * w, Bool gone)
{
	finish_unmap_win(dpy, w);
}

#endif

static void
unmap_win(Display * dpy, Window id, Bool fade)
{
	win            *w = find_win(dpy, id);

	if (!w)
		return;
	w->a.map_state = IsUnmapped;
#if HAS_NAME_WINDOW_PIXMAP
	if (w->pixmap && fade && fadeWindows)
		set_fade(dpy, w, w->opacity * 1.0 / OPAQUE, 0.0, fade_out_step, unmap_callback, False, False, True);
	else
#endif
		finish_unmap_win(dpy, w);
}

/*
 * Get the opacity prop from window not found: default otherwise the value
 */
static unsigned int
get_opacity_prop(Display * dpy, win * w, unsigned int def)
{
	Atom		actual;
	int		format;
	unsigned long	n, left;

	unsigned char  *data;
	int		result = XGetWindowProperty(dpy, w->id, opacityAtom, 0L, 1L, False,
					 XA_CARDINAL, &actual, &format,
					 &n, &left, &data);

	if (result == Success && data != NULL)
	{
		uint32_t	i;

		memcpy(&i, data, sizeof(uint32_t));
		XFree((void *)data);
		return i;
	}
	return def;
}

/*
 * Get the opacity property from the window in a percent format not found:
 * default otherwise: the value
 */
static double
get_opacity_percent(Display * dpy, win * w, double def)
{
	unsigned int	opacity = get_opacity_prop(dpy, w, (unsigned int)(OPAQUE * def));

	return opacity * 1.0 / OPAQUE;
}

/*
 * determine mode for window all in one place. Future might check for menu
 * flag and other cool things
 */

static		Atom
get_wintype_prop(Display * dpy, Window w)
{
	Atom		actual;
	int		format;
	unsigned long	n, left;

	unsigned char  *data;
	int		result = XGetWindowProperty(dpy, w, winTypeAtom, 0L, 1L, False, XA_ATOM, &actual, &format,
					 &n, &left, &data);

	if (result == Success && data != None)
	{
		Atom		a;

		memcpy(&a, data, sizeof(Atom));
		XFree((void *)data);
		return a;
	}
	return winNormalAtom;
}

static void
determine_mode(Display * dpy, win * w)
{
	int		mode;
	XRenderPictFormat *format;
	unsigned int	default_opacity;

	/* if trans prop == -1 fall back on  previous tests */

	if (w->alphaPict)
	{
		XRenderFreePicture(dpy, w->alphaPict);
		w->alphaPict = None;
	}
	if (w->shadowPict)
	{
		XRenderFreePicture(dpy, w->shadowPict);
		w->shadowPict = None;
	}
	if (w->a.class == InputOnly)
	{
		format = 0;
	}
	else
	{
		format = XRenderFindVisualFormat(dpy, w->a.visual);
	}

	if (format && format->type == PictTypeDirect && format->direct.alphaMask)
	{
		mode = WINDOW_ARGB;
	}
	else if (w->opacity != OPAQUE)
	{
		mode = WINDOW_TRANS;
	}
	else
	{
		mode = WINDOW_SOLID;
	}
	w->mode = mode;
	if (w->extents)
	{
		XserverRegion	damage;

		damage = XFixesCreateRegion(dpy, 0, 0);
		XFixesCopyRegion(dpy, damage, w->extents);
		add_damage(dpy, damage);
	}
}

static		Atom
determine_wintype(Display * dpy, Window w)
{
	Window		root_return, parent_return;
	Window         *children = NULL;
	unsigned int	nchildren, i;
	Atom		type;

	/*
	 * Hack to hide shadows on menu and dock.
	 */

	XClassHint *class_hint = XAllocClassHint();
	int result =  XGetClassHint(dpy,w,class_hint);
	if((result != 0))
	{
		NSString * process = [NSString stringWithCString:class_hint->res_name];
		//NSLog(@"Window %x owned by %@", w, process);
		if([unshadowedApps containsObject:process])
		{
			//NSLog(@"No shadow for window %x (%@)", w, process);
			return winDockAtom;
		}
	}
	XFree(class_hint);

	type = get_wintype_prop(dpy, w);
	if (type != winNormalAtom)
		return type;

	if (!XQueryTree(dpy, w, &root_return, &parent_return, &children,
			&nchildren))
	{
		/* XQueryTree failed. */
		if (children)
			XFree((void *)children);
		return winNormalAtom;
	}
	for (i = 0; i < nchildren; i++)
	{
		type = determine_wintype(dpy, children[i]);
		if (type != winNormalAtom)
		{
			return type;
		}
	}

	if (children)
		XFree((void *)children);

	return winNormalAtom;
}

static void
add_win(Display * dpy, Window id, Window prev)
{
	win            *new = malloc(sizeof(win));
	win           **p;

	if (!new)
		return;
	if (prev)
	{
		for (p = &list; *p; p = &(*p)->next)
			if ((*p)->id == prev)
				break;
	}
	else
		p = &list;
	new->id = id;
	set_ignore(dpy, NextRequest(dpy));
	if (!XGetWindowAttributes(dpy, id, &new->a))
	{
		free(new);
		return;
	}
	new->damaged = 0;
	new->isIconified = NO;
#if HAS_NAME_WINDOW_PIXMAP
	new->pixmap = None;
#endif
	new->picture = None;
	if (new->a.class == InputOnly)
	{
		new->damage_sequence = 0;
		new->damage = None;
	}
	else
	{
		new->damage_sequence = NextRequest(dpy);
		new->damage = XDamageCreate(dpy, id, XDamageReportNonEmpty);
	}
	new->alphaPict = None;
	new->shadowPict = None;
	new->borderSize = None;
	new->extents = None;
	new->shadow = None;
	new->shadow_dx = 0;
	new->shadow_dy = 0;
	new->shadow_width = 0;
	new->shadow_height = 0;
	new->opacity = OPAQUE;

	new->borderClip = None;
	new->prev_trans = 0;

	/* moved mode setting to one place */
	new->opacity = get_opacity_prop(dpy, new, OPAQUE);
	new->windowType = determine_wintype(dpy, new->id);
	determine_mode(dpy, new);

	new->next = *p;
	*p = new;
	if (new->a.map_state == IsViewable)
		map_win(dpy, id, new->damage_sequence - 1, True);
}

void
restack_win(Display * dpy, win * w, Window new_above)
{
	Window		old_above;

	if (w->next)
		old_above = w->next->id;
	else
		old_above = None;
	if (old_above != new_above)
	{
		win           **prev;

		/* unhook */
		for (prev = &list; *prev; prev = &(*prev)->next)
			if ((*prev) == w)
				break;
		*prev = w->next;

		/* rehook */
		for (prev = &list; *prev; prev = &(*prev)->next)
		{
			if ((*prev)->id == new_above)
				break;
		}
		w->next = *prev;
		*prev = w;
	}
}

static void
configure_win(Display * dpy, XConfigureEvent * ce)
{
	win            *w = find_win(dpy, ce->window);
	Window		above;
	XserverRegion	damage = None;

	if (!w)
	{
		if (ce->window == root)
		{
			if (rootBuffer)
			{
				XRenderFreePicture(dpy, rootBuffer);
				rootBuffer = None;
			}
			root_width = ce->width;
			root_height = ce->height;
		}
		return;
	}
	{
		damage = XFixesCreateRegion(dpy, 0, 0);
		if (w->extents != None)
			XFixesCopyRegion(dpy, damage, w->extents);
	}
	w->a.x = ce->x;
	w->a.y = ce->y;
	if (w->a.width != ce->width || w->a.height != ce->height)
	{
#if HAS_NAME_WINDOW_PIXMAP
		if (w->pixmap)
		{
			XFreePixmap(dpy, w->pixmap);
			w->pixmap = None;
			if (w->picture)
			{
				XRenderFreePicture(dpy, w->picture);
				w->picture = None;
			}
		}
#endif
		if (w->shadow)
		{
			XRenderFreePicture(dpy, w->shadow);
			w->shadow = None;
		}
	}
	w->a.width = ce->width;
	w->a.height = ce->height;
	w->a.border_width = ce->border_width;
	w->a.override_redirect = ce->override_redirect;
	restack_win(dpy, w, ce->above);
	if (damage)
	{
		XserverRegion	extents = win_extents(dpy, w);

		XFixesUnionRegion(dpy, damage, damage, extents);
		XFixesDestroyRegion(dpy, extents);
		add_damage(dpy, damage);
	}
	clipChanged = True;
}

static void
circulate_win(Display * dpy, XCirculateEvent * ce)
{
	win            *w = find_win(dpy, ce->window);
	Window		new_above;

	if (!w)
		return;

	if (ce->place == PlaceOnTop)
		new_above = list->id;
	else
		new_above = None;
	restack_win(dpy, w, new_above);
	clipChanged = True;
}

static void
finish_destroy_win(Display * dpy, Window id, Bool gone)
{
	win           **prev, *w;

	for (prev = &list; (w = *prev); prev = &w->next)
		if (w->id == id)
		{
			if (!gone)
				finish_unmap_win(dpy, w);
			*prev = w->next;
			if (w->picture)
			{
				set_ignore(dpy, NextRequest(dpy));
				XRenderFreePicture(dpy, w->picture);
				w->picture = None;
			}
			if (w->alphaPict)
			{
				XRenderFreePicture(dpy, w->alphaPict);
				w->alphaPict = None;
			}
			if (w->shadowPict)
			{
				XRenderFreePicture(dpy, w->shadowPict);
				w->shadowPict = None;
			}
			if (w->damage != None)
			{
				set_ignore(dpy, NextRequest(dpy));
				XDamageDestroy(dpy, w->damage);
				w->damage = None;
			}
			cleanup_fade(dpy, w);
			free(w);
			break;
		}
}

#if HAS_NAME_WINDOW_PIXMAP
static void
destroy_callback(Display * dpy, win * w, Bool gone)
{
	finish_destroy_win(dpy, w->id, gone);
}

#endif

static void
destroy_win(Display * dpy, Window id, Bool gone, Bool fade)
{
	win            *w = find_win(dpy, id);

#if HAS_NAME_WINDOW_PIXMAP
	if (w && w->pixmap && fade && fadeWindows)
		set_fade(dpy, w, w->opacity * 1.0 / OPAQUE, 0.0, fade_out_step, destroy_callback, gone, False, True);
	else
#endif
	{
		finish_destroy_win(dpy, id, gone);
	}
}

/*
 * static void dump_win (win *w) { printf ("\t%08lx: %d x %d + %d + %d
 * (%d)\n", w->id, w->a.width, w->a.height, w->a.x, w->a.y,
 * w->a.border_width); }
 * 
 * 
 * static void dump_wins (void) { win	*w;
 * 
 * printf ("windows:\n"); for (w = list; w; w = w->next) dump_win (w); }
 */

static void
damage_win(Display * dpy, XDamageNotifyEvent * de)
{
	win            *w = find_win(dpy, de->drawable);

	if (!w)
		return;
	repair_win(dpy, w);
}

static int
error(Display * dpy, XErrorEvent * ev)
{
	int		o;
	char           *name = 0;

	if (should_ignore(dpy, ev->serial))
		return 0;

	if (ev->request_code == composite_opcode &&
	    ev->minor_code == X_CompositeRedirectSubwindows)
	{
		fprintf(stderr, "Another composite manager is already running\n");
		exit(1);
	}
	o = ev->error_code - xfixes_error;
	switch (o)
	{
		case BadRegion:
			name = "BadRegion";
			break;
		default:
			break;
	}
	o = ev->error_code - damage_error;
	switch (o)
	{
		case BadDamage:
			name = "BadDamage";
			break;
		default:
			break;
	}
	o = ev->error_code - render_error;
	switch (o)
	{
		case BadPictFormat:
			name = "BadPictFormat";
			break;
		case BadPicture:
			name = "BadPicture";
			break;
		case BadPictOp:
			name = "BadPictOp";
			break;
		case BadGlyphSet:
			name = "BadGlyphSet";
			break;
		case BadGlyph:
			name = "BadGlyph";
			break;
		default:
			break;
	}

	/*
	printf("error %d request %d minor %d serial %d\n",
	       ev->error_code, ev->request_code, ev->minor_code, (int) ev->serial);
		   */

	/* abort ();	    this is just annoying to most people */
	return 0;
}

static void
expose_root(Display * dpy, Window root, XRectangle * rects, int nrects)
{
	XserverRegion	region = XFixesCreateRegion(dpy, rects, nrects);

	add_damage(dpy, region);
}


static int
ev_serial(XEvent * ev)
{
	if ((ev->type & 0x7f) != KeymapNotify)
		return ev->xany.serial;
	return NextRequest(ev->xany.display);
}


static char    *
ev_name(XEvent * ev)
{
	static char	buf [128];

	switch (ev->type & 0x7f)
	{
		case Expose:
			return "Expose";
		case MapNotify:
			return "Map";
		case UnmapNotify:
			return "Unmap";
		case ReparentNotify:
			return "Reparent";
		case CirculateNotify:
			return "Circulate";
		default:
			if (ev->type == damage_event + XDamageNotify)
				return "Damage";
			sprintf(buf, "Event %d", ev->type);
			return buf;
	}
}

static		Window
ev_window(XEvent * ev)
{
	switch (ev->type)
	{
			case Expose:
			return ev->xexpose.window;
		case MapNotify:
			return ev->xmap.window;
		case UnmapNotify:
			return ev->xunmap.window;
		case ReparentNotify:
			return ev->xreparent.window;
		case CirculateNotify:
			return ev->xcirculate.window;
		default:
			if (ev->type == damage_event + XDamageNotify)
				return ((XDamageNotifyEvent *) ev)->drawable;
			return 0;
	}
}

void
usage(char *program)
{
	fprintf(stderr, "%s v1.1.2\n", program);
	fprintf(stderr, "usage: %s [options]\n", program);
	fprintf(stderr, "Options\n");
	fprintf(stderr, "   -d display\n      Specifies which display should be managed.\n");
	fprintf(stderr, "   -r radius\n      Specifies the blur radius for client-side shadows. (default 12)\n");
	fprintf(stderr, "   -o opacity\n      Specifies the translucency for client-side shadows. (default .75)\n");
	fprintf(stderr, "   -l left-offset\n      Specifies the left offset for client-side shadows. (default -15)\n");
	fprintf(stderr, "   -t top-offset\n      Specifies the top offset for clinet-side shadows. (default -15)\n");
	fprintf(stderr, "   -I fade-in-step\n      Specifies the opacity change between steps while fading in. (default 0.028)\n");
	fprintf(stderr, "   -O fade-out-step\n      Specifies the opacity change between steps while fading out. (default 0.03)\n");
	fprintf(stderr, "   -D fade-delta-time\n      Specifies the time between steps in a fade in milliseconds. (default 10)\n");
	fprintf(stderr, "   -a\n      Use automatic server-side compositing. Faster, but no special effects.\n");
	fprintf(stderr, "   -c\n      Draw client-side shadows with fuzzy edges.\n");
	fprintf(stderr, "   -C\n      Avoid drawing shadows on dock/panel windows.\n");
	fprintf(stderr, "   -f\n      Fade windows in/out when opening/closing.\n");
	fprintf(stderr, "   -F\n      Fade windows during opacity changes.\n");
	fprintf(stderr, "   -n\n      Normal client-side compositing with transparency support\n");
	fprintf(stderr, "   -S\n      Enable synchronous operation (for debugging).\n");
	exit(1);
}

static void
give_me_a_name(void)
{
	Window		w;

	w = XCreateSimpleWindow(dpy, RootWindow(dpy, 0), 0, 0, 1, 1, 0, None,
				None);

	Xutf8SetWMProperties(dpy, w, "xcompmgr", "xcompmgr", NULL, 0, NULL, NULL,
			     NULL);
}

static inline void uniconify_win(win * w)
{
	w->isIconified = NO;
	XRenderFreePicture(dpy, w->picture);
	w->picture = None;
	w->extents = win_extents(dpy, w);
	//Bring it back
	XMoveWindow(dpy, w->id, w->realX, w->realY);
}

static inline void iconify_win(win * w)
{
	w->isIconified = YES;
	
	static int i=0;
	w->realX = w->a.x;
	w->realY = w->a.y;
	//Hide iconified windows off the screen
	XMoveWindow(dpy, w->id, -500,-500);

	XRenderFreePicture(dpy, w->picture);
	w->picture = None;
	w->extents = win_extents(dpy, w);
}


int
main(int argc, char **argv)
{
	XEvent		ev;
	Window		root_return, parent_return;
	Window         *children;
	Pixmap		transPixmap;
	Pixmap		blackPixmap;
	unsigned int	nchildren;
	int		i;
	XRenderPictureAttributes pa;
	XRenderColor	c;
	XRectangle     *expose_rects = 0;
	int		size_expose = 0;
	int		n_expose = 0;
	struct pollfd	ufd;
	int		n;
	int		last_update;
	int		now;
	int		p;
	int		composite_major, composite_minor;
	char           *display = 0;
	int		o;

	[[NSAutoreleasePool alloc] init];
	unshadowedApps = [[NSSet alloc] initWithObjects:
	//	@"EtoileMenuServer",
		@"AZDock",
		@"AZSwitch",
		nil];
	//TODO: We don't want most of these to be use-tweakable, so remove them
	while ((o = getopt(argc, argv, "D:I:O:d:r:o:l:t:cnfFCaS")) != -1)
	{
		switch (o)
		{
			case 'd':
				display = optarg;
				break;
			case 'D':
				fade_delta = atoi(optarg);
				if (fade_delta < 1)
					fade_delta = 10;
				break;
			case 'I':
				fade_in_step = atof(optarg);
				if (fade_in_step <= 0)
					fade_in_step = 0.01;
				break;
			case 'O':
				fade_out_step = atof(optarg);
				if (fade_out_step <= 0)
					fade_out_step = 0.01;
				break;
			case 'c':
				compMode = CompClientShadows;
				break;
			case 'C':
				excludeDockShadows = True;
				break;
			case 'n':
				compMode = CompSimple;
				break;
			case 'f':
				fadeWindows = True;
				break;
			case 'F':
				fadeTrans = True;
				break;
			case 'a':
				autoRedirect = True;
				break;
			case 'S':
				synchronize = True;
				break;
			case 'r':
				shadowRadius = atoi(optarg);
				break;
			case 'o':
				shadowOpacity = atof(optarg);
				break;
			case 'l':
				shadowOffsetX = atoi(optarg);
				break;
			case 't':
				shadowOffsetY = atoi(optarg);
				break;
			default:
				usage(argv[0]);
				break;
		}
	}

	dpy = XOpenDisplay(display);
	if (!dpy)
	{
		fprintf(stderr, "Can't open display\n");
		exit(1);
	}
	XSetErrorHandler(error);
	if (synchronize)
		XSynchronize(dpy, 1);
	scr = DefaultScreen(dpy);
	root = RootWindow(dpy, scr);

	if (!XRenderQueryExtension(dpy, &render_event, &render_error))
	{
		fprintf(stderr, "No render extension\n");
		exit(1);
	}
	if (!XQueryExtension(dpy, COMPOSITE_NAME, &composite_opcode,
			     &composite_event, &composite_error))
	{
		fprintf(stderr, "No composite extension\n");
		exit(1);
	}
	XCompositeQueryVersion(dpy, &composite_major, &composite_minor);
#if HAS_NAME_WINDOW_PIXMAP
	if (composite_major > 0 || composite_minor >= 2)
		hasNamePixmap = True;
#endif

	if (!XDamageQueryExtension(dpy, &damage_event, &damage_error))
	{
		fprintf(stderr, "No damage extension\n");
		exit(1);
	}
	if (!XFixesQueryExtension(dpy, &xfixes_event, &xfixes_error))
	{
		fprintf(stderr, "No XFixes extension\n");
		exit(1);
	}
	give_me_a_name();

	/* get atoms */
	opacityAtom = XInternAtom(dpy, OPACITY_PROP, False);
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

	pa.subwindow_mode = IncludeInferiors;

	if (compMode == CompClientShadows)
	{
		defaultGaussianMap = make_gaussian_map(dpy, shadowRadius);
		presum_gaussian(defaultGaussianMap);
		foregroundGaussianMap = make_gaussian_map(dpy, forgroundShadowRadius);
		presum_gaussian(foregroundGaussianMap);
	}
	root_width = DisplayWidth(dpy, scr);
	root_height = DisplayHeight(dpy, scr);

	rootPicture = XRenderCreatePicture(dpy, root,
					   XRenderFindVisualFormat(dpy,
						   DefaultVisual(dpy, scr)),
					   CPSubwindowMode,
					   &pa);
	blackPicture = solid_picture(dpy, True, 1, 0, 0, 0);
	allDamage = None;
	clipChanged = True;
	XGrabServer(dpy);
	if (autoRedirect)
		XCompositeRedirectSubwindows(dpy, root, CompositeRedirectAutomatic);
	else
	{
		XCompositeRedirectSubwindows(dpy, root, CompositeRedirectManual);
		XSelectInput(dpy, root,
			     SubstructureNotifyMask |
			     ExposureMask |
			     StructureNotifyMask |
			     PropertyChangeMask);
		XQueryTree(dpy, root, &root_return, &parent_return, &children, &nchildren);
		for (i = 0; i < nchildren; i++)
		{
			add_win(dpy, children[i], i ? children[i - 1] : None);
		}
		XFree(children);
	}
	XUngrabServer(dpy);
	ufd.fd = ConnectionNumber(dpy);
	ufd.events = POLLIN;
	if (!autoRedirect)
		paint_all(dpy, None);
	for (;;)
	{
		/* dump_wins (); */
		do
		{
			id pool = [[NSAutoreleasePool alloc] init];
			if (autoRedirect)
				XFlush(dpy);
			if (!QLength(dpy))
			{
				if (poll(&ufd, 1, fade_timeout()) == 0)
				{
					run_fades(dpy);
					break;
				}
			}
			XNextEvent(dpy, &ev);
			if ((ev.type & 0x7f) != KeymapNotify)
				discard_ignore(dpy, ev.xany.serial);
#if DEBUG_EVENTS
			printf("event %10.10s serial 0x%08x window 0x%08x\n",
			       ev_name(&ev), ev_serial(&ev), ev_window(&ev));
#endif
			if (!autoRedirect)
				switch (ev.type)
				{
					case CreateNotify:
						add_win(dpy, ev.xcreatewindow.window, 0);
						break;
					case ConfigureNotify:
						configure_win(dpy, &ev.xconfigure);
						break;
					case DestroyNotify:
						destroy_win(dpy, ev.xdestroywindow.window, True, True);
						break;
					case MapNotify:
						map_win(dpy, ev.xmap.window, ev.xmap.serial, True);
						break;
					case UnmapNotify:
						unmap_win(dpy, ev.xunmap.window, True);
						break;
					case ReparentNotify:
						if (ev.xreparent.parent == root)
							add_win(dpy, ev.xreparent.window, 0);
						else
							destroy_win(dpy, ev.xreparent.window, False, True);
						break;
					case CirculateNotify:
						circulate_win(dpy, &ev.xcirculate);
						break;
					case Expose:
						if (ev.xexpose.window == root)
						{
							int		more = ev.xexpose.count + 1;

							if (n_expose == size_expose)
							{
								if (expose_rects)
								{
									expose_rects = realloc(expose_rects,
											       (size_expose + more) *
											       sizeof(XRectangle));
									size_expose += more;
								}
								else
								{
									expose_rects = malloc(more * sizeof(XRectangle));
									size_expose = more;
								}
							}
							expose_rects[n_expose].x = ev.xexpose.x;
							expose_rects[n_expose].y = ev.xexpose.y;
							expose_rects[n_expose].width = ev.xexpose.width;
							expose_rects[n_expose].height = ev.xexpose.height;
							n_expose++;
							if (ev.xexpose.count == 0)
							{
								expose_root(dpy, root, expose_rects, n_expose);
								n_expose = 0;
							}
						}
						break;
					case PropertyNotify:
						for (p = 0; backgroundProps[p]; p++)
						{
							if (ev.xproperty.atom == XInternAtom(dpy, backgroundProps[p], False))
							{
								if (rootTile)
								{
									XClearArea(dpy, root, 0, 0, 0, 0, True);
									XRenderFreePicture(dpy, rootTile);
									rootTile = None;
									break;
								}
							}
						}
						/*
						 * If the active window has changed.
						 */
						if (ev.xproperty.atom == winActiveAtom)
						{
							/*
							 * Get the new active window.
							 */
							Window window = None;
							Window parent = None;
							unsigned long num;
							Window *data = NULL;
							Atom type_ret;
							int format_ret;
							unsigned long after_ret;
							int result = XGetWindowProperty(dpy, root, winActiveAtom,
									0, 0x7FFFFFFF, False, XA_WINDOW,
									&type_ret, &format_ret, &num,
									&after_ret, (unsigned char **)&data);
							if ((result != Success) || (num == 0))
							{
								NSLog(@"Error: cannot get active window.");
							}
							else
							{
								win *w = foregroundWindow;
								foregroundWindow = NULL;
								if (w && w->shadow)
								{
									w->opacity = get_opacity_prop(dpy, w, OPAQUE);
									determine_mode(dpy, w);
									XRenderFreePicture(dpy, w->shadow);
									w->shadow = None;
									w->extents = win_extents(dpy, w);

#if DEBUG_ICONIFY
									uniconify_win(w);
#endif
								}
								window = data[0];
								XFree(data);
								data = NULL;
								//Find the real parent.
								w = find_win(dpy, window);
								while(w == NULL && window != 0)
								{
									if (XQueryTree(dpy, window, (Window*)&format_ret, &parent, &data, (unsigned int*)&num) == False)
									{
										// Failed
										break;
									}
									if (data)
									{
										XFree(data);
										data = NULL;
									}
									window = parent;
									w = find_win(dpy, window);
								}
								if(w != NULL && window != 0)
								{
									foregroundWindow = w;
									w->extents = win_extents(dpy, w);
									XRenderFreePicture(dpy, w->shadow);
									w->shadow = None;

#if DEBUG_ICONIFY
									iconify_win(w);
#endif
								}
							}
						}
						/*
						 * check if Trans property
						 * was changed
						 */
						if (ev.xproperty.atom == opacityAtom)
						{
							/*
							 * reset mode and
							 * redraw window
							 */
							win            *w = find_win(dpy, ev.xproperty.window);

							if (w)
							{
								if (fadeTrans)
									set_fade(dpy, w, w->opacity * 1.0 / OPAQUE, get_opacity_percent(dpy, w, 1.0),
										 fade_out_step, 0, False, True, False);
								else
								{
									w->opacity = get_opacity_prop(dpy, w, OPAQUE);
									determine_mode(dpy, w);
									if (w->shadow)
									{
										XRenderFreePicture(dpy, w->shadow);
										w->shadow = None;
										w->extents = win_extents(dpy, w);
									}
								}
							}
						}
						break;
					default:
						if (ev.type == damage_event + XDamageNotify)
							damage_win(dpy, (XDamageNotifyEvent *) & ev);
						break;
				}
			[pool release];
		} while (QLength(dpy));
		if (allDamage && !autoRedirect)
		{
			static int	paint;

			paint_all(dpy, allDamage);
			paint++;
			XSync(dpy, False);
			allDamage = None;
			clipChanged = False;
		}
	}
}
