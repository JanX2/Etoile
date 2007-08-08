/* Modified from Imlib2. See COPYING.imlib2 */
#ifndef __GRAB
#define __GRAB 1

#include <X11/Xlib.h>
#include <X11/Xutil.h>

#define DATABIG unsigned long long
#define DATA64  unsigned long long
#define DATA32  unsigned int
#define DATA16  unsigned short
#define DATA8   unsigned char

char __imlib_GrabDrawableToRGBA(DATA32 *data, int ox, int oy, int ow, int oh,
			   Display *d, Drawable p, Pixmap m, Visual *v,
			   Colormap cm, int depth, int x, int y,
			   int w, int h, char *domask, char grab);
void __imlib_GrabXImageToRGBA(DATA32 *data, int ox, int oy, int ow, int oh, 
			 Display *d, XImage *xim, XImage *mxim, Visual *v,
			 int depth, int x, int y,
			 int w, int h, char grab);
#endif

