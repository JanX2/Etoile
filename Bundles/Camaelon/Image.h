#ifndef __IMAGE_H__
#define __IMAGE_H__

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSDrawFunctions.h"
#include "GraphicToolbox.h"
#include "ImageProvider.h"
#include "Camaelon.h"

@interface Image : NSImage {}
+ (void) setNSImageClass: (Class) aClass;
@end

#endif
