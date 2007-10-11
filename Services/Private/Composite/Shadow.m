#import "Shadow.h"
#include <math.h>
#include "constants.h"

extern Display * dpy;
extern Window root;
static inline double
gaussian(double r, double x, double y)
{
	return ((1 / (sqrt(2 * M_PI * r))) *
		exp((-(x * x + y * y)) / (2 * r * r)));
}

@implementation Gaussian 
- (Gaussian*) initWithRadius:(float)r
{
	if(nil == (self = [self init]))
	{
		return nil;
	}
	size = ((int)ceil((r * 3)) + 1) & ~1;
	int		center = size / 2;
	double		t;
	double		g;

	if(data)
	{
		free(data);
	}
	data = malloc(size * size * sizeof(double));
	t = 0.0;
	for (int y = 0; y < size; y++)
	{
		for (int x = 0; x < size; x++)
		{
			g = gaussian(r, (double)(x - center), (double)(y - center));
			t += g;
			data[y * size + x] = g;
		}
	}
	for (int y = 0; y < size; y++)
	{
		for (int x = 0; x < size; x++)
		{
			data[y * size + x] /= t;
		}
	}
	return self;
}
- (unsigned char) sumForOpacity:(double)opacity
                              x:(int)x
                              y:(int)y
						  width:(int)width
						 height:(int)height

{
	int		fx        , fy;
	double         *g_data;
	double         *g_line = data;
	int		center = size / 2;
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
	if (fx_end > size)
		fx_end = size;

	fy_start = center - y;
	if (fy_start < 0)
		fy_start = 0;
	fy_end = height + center - y;
	if (fy_end > size)
		fy_end = size;

	g_line = g_line + fy_start * size + fx_start;

	v = 0;
	for (fy = fy_start; fy < fy_end; fy++)
	{
		g_data = g_line;
		g_line += size;

		for (fx = fx_start; fx < fx_end; fx++)
			v += *g_data++;
	}
	if (v > 1)
		v = 1;

	return ((unsigned char)(v * opacity * 255.0));
}
@end

@implementation Shadow
- (Shadow*) initWithGaussian:(Gaussian*)aGaussian
{
	if(nil == (self = [self init]))
	{
		return nil;
	}
	gaussian = aGaussian;
	
	/*
	 * Precompute the corners
	 */
	int center = gaussian->size / 2;
	int x, y;
	int size = gaussian->size;
	int size1 = size1;
	int squareSize = size1 * size1;

	if (shadowCorner)
		free((void *)shadowCorner);
	if (shadowTop)
		free((void *)shadowTop);

	shadowCorner = (unsigned char *)(malloc(squareSize * 26));
	shadowTop = (unsigned char *)(malloc((size1) * 26));

	for (x = 0; x <= size; x++)
	{
		shadowTop[25 * (size1) + x] = [gaussian sumForOpacity:1
															x:x - center
															y:center
													    width:size * 2
													   height:size * 2];

		for (opacity = 0; opacity < 25; opacity++)
		{
			shadowTop[opacity * (size1) + x] = shadowTop[25 * (size1) + x] * opacity / 25;
		}

		for (y = 0; y <= x; y++)
		{
			shadowCorner[25 * squareSize + y * (size1) + x] = 
			shadowCorner[25 * squareSize + x * (size1) + y] = 
				  [gaussian sumForOpacity:1
				                        x:x - center
										y:y - center
									width:size * 2
								   height:size * 2];

			for (opacity = 0; opacity < 25; opacity++)
			{
				shadowCorner[opacity * squareSize + y * (size1) + x] =
				shadowCorner[opacity * squareSize + x * (size1) + y] =
					shadowCorner[25 * squareSize + y * (size1) + x] * opacity / 25;
			}
		}
	}

	return self;
}
- (XImage*) shadowImageForOpacity:(int)anAlpha width:(int)width height:(int) height
{
	XImage         *ximage;
	unsigned char  *data;
	int		Gsize = gaussian->size;
	int		ylimit    , xlimit;
	int		swidth = width + Gsize;
	int		sheight = height + Gsize;
	int		center = Gsize / 2;
	int		x         , y;
	unsigned char	d;
	int		x_diff;
	int		opacity_int = anAlpha * (25 / OPAQUE);

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
	{
		d = shadowTop[opacity_int * (Gsize + 1) + Gsize];
	}
	else
	{
		d = [gaussian sumForOpacity:opacity x:center y:center width:width height:height];
	}
	memset(data, d, sheight * swidth);

	/*
	 * corners
	 */
	ylimit = Gsize;
	if (ylimit > sheight / 2)
		ylimit = (sheight + 1) / 2;
	xlimit = Gsize;
	if (xlimit > swidth / 2)
		xlimit = (swidth + 1) / 2;

	for (y = 0; y < ylimit; y++)
	{
		for (x = 0; x < xlimit; x++)
		{
			if (xlimit == Gsize && ylimit == Gsize)
			{
				d = shadowCorner[opacity_int * (Gsize + 1) * (Gsize + 1) + y * (Gsize + 1) + x];
			}
			else
			{
				d = [gaussian sumForOpacity:opacity x:x - center y:y - center width:width height:height];
			}
			data[y * swidth + x] = d;
			data[(sheight - y - 1) * swidth + x] = d;
			data[(sheight - y - 1) * swidth + (swidth - x - 1)] = d;
			data[y * swidth + (swidth - x - 1)] = d;
		}
	}

	/*
	 * top/bottom
	 */
	x_diff = swidth - (Gsize * 2);
	if (x_diff > 0 && ylimit > 0)
	{
		for (y = 0; y < ylimit; y++)
		{
			if (ylimit == Gsize)
			{
				d = shadowTop[opacity_int * (Gsize + 1) + y];
			}
			else
			{
				d = [gaussian sumForOpacity:opacity x:center y:y - center width:width height:height];
			}
			memset(&data[y * swidth + Gsize], d, x_diff);
			memset(&data[(sheight - y - 1) * swidth + Gsize], d, x_diff);
		}
	}
	/*
	 * sides
	 */

	for (x = 0; x < xlimit; x++)
	{
		if (xlimit == Gsize)
		{
			d = shadowTop[opacity_int * (Gsize + 1) + x];
		}
		else
		{
			d = [gaussian sumForOpacity:opacity x:x - center y:center width:width height:height];
		}
		for (y = Gsize; y < sheight - Gsize; y++)
		{
			data[y * swidth + x] = d;
			data[y * swidth + (swidth - x - 1)] = d;
		}
	}

	return ximage;
}
- (Picture) pictureForOpacity:(int)anAlpha width:(int)aWidth height:(int)aHeight
{
	XImage         *shadowImage;
	Pixmap		shadowPixmap;
	Pixmap		finalPixmap;
	Picture		shadowPicture;
	Picture		finalPicture;
	GC		gc;

	shadowImage = [self shadowImageForOpacity:anAlpha width:aWidth height:aHeight];
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
	/*
	*wp = shadowImage->width;
	*hp = shadowImage->height;
	*/
	XFreeGC(dpy, gc);
	XDestroyImage(shadowImage);
	XFreePixmap(dpy, shadowPixmap);
	return shadowPicture;
}
- (XRectangle) rectangleForWindowWithRectangle:(XRectangle*)r
{
	XRectangle sr;
	sr.x = r->x - gaussian->size;
	sr.y = r->y - gaussian->size;
	sr.width = r->width + 2 * gaussian->size;
	sr.height = r->height + 2 * gaussian->size;
	return sr;
}
@end
