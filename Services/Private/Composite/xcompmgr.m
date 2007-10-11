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
#include "constants.h"
#include "IgnoreEvents.h"
#import "CompositeWindow.h"
#import "CompositeDisplay.h"
#import "Shadow.h"

NSSet * unshadowedApps;



#if 0
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
#endif


NSMutableArray * windows;
//fade           *fades;
//FIXME: This should no longer be used.
Display        *dpy;
CompositeDisplay * display;
int		scr;
Window		root;
Picture		blackPicture;
Picture		transBlackPicture;

Bool		hasNamePixmap;

ignore         *ignore_head, **ignore_tail = &ignore_head;
int		xfixes_event, xfixes_error;
int		damage_event, damage_error;
int		composite_event, composite_error;
int		render_event, render_error;
Bool		synchronize;
int		composite_opcode;


/* opacity property name; sometime soon I'll write up an EWMH spec for it */


CompositeWindow * foregroundWindow = nil;

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

int
get_time_in_milliseconds()
{
	struct timeval	tv;

	gettimeofday(&tv, NULL);
	return tv.tv_sec * 1000 + tv.tv_usec / 1000;
}

//We're not using fades for now.  Add it back in later, when we are.
#if 0
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
#endif


//TODO: Delete this.
static char    *backgroundProps[] = {
	"_XROOTPMAP_ID",
	"_XSETROOT_ID",
	0,
};



static void
circulate_win(Display * dpy, XCirculateEvent * ce)
{
	[display circulateWindowWithEvent:ce];
}

static void
destroy_win(Display * dpy, Window id, Bool gone, Bool fade)
{
	[display unmapWindowWithID:id];
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
	CompositeWindow * w = [display windowForID:de->drawable];
	[w repair];
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
	[display addDamage:region];
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
	while ((o = getopt(argc, argv, "D:I:O:d:r:o:l:t:cnfFCS")) != -1)
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
			case 'C':
				excludeDockShadows = True;
				break;
			case 'f':
				fadeWindows = True;
				break;
			case 'F':
				fadeTrans = True;
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
	if (composite_major > 0 || composite_minor >= 2)
		hasNamePixmap = True;

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



	Gaussian * defaultGaussianMap = [[Gaussian alloc] initWithRadius:shadowRadius];
	Gaussian * foregroundGaussianMap = [[Gaussian alloc] initWithRadius:forgroundShadowRadius];
	
	clipChanged = True;
	XGrabServer(dpy);
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
	XUngrabServer(dpy);
	ufd.fd = ConnectionNumber(dpy);
	ufd.events = POLLIN;
		paint_all(dpy, None);
	for (;;)
	{
		/* dump_wins (); */
		do
		{
			id pool = [[NSAutoreleasePool alloc] init];
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
								/*
								if (fadeTrans)
									set_fade(dpy, w, w->opacity * 1.0 / OPAQUE, get_opacity_percent(dpy, w, 1.0),
										 fade_out_step, 0, False, True, False);
								else*/
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
		if (allDamage)
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
