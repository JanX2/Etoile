#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/extensions/Xcomposite.h>
#include <X11/extensions/Xdamage.h>
#include <X11/extensions/Xrender.h>
#import <Foundation/Foundation.h>

@interface Gaussian : NSObject {
@public
	int		size;
	double * data;
}
- (Gaussian*) initWithRadius:(float)r;
- (unsigned char) sumForOpacity:(double)opacity
                              x:(int)x
                              y:(int)y
						  width:(int)width
						 height:(int)height;
@end

@interface Shadow : NSObject {
	Gaussian * gaussian;
	uint32_t opacity;
	unsigned char * shadowCorner;
	unsigned char * shadowTop;
@public
	int borderSize;
}
- (Shadow*) initWithGaussian:(Gaussian*)aGaussian;
- (XRectangle) rectangleForWindowWithRectangle:(XRectangle*)r;
- (Picture) pictureForOpacity:(int)anAlpha width:(int)aWidth height:(int)aHeight;
@end
