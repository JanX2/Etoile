#ifndef __CLIMAGE_H__
#define __CLIMAGE_H__

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>
#include "GSDrawFunctions.h"
#include "GraphicToolbox.h"
#include "ImageProvider.h"
#include "Camaelon.h"

@interface CLImage : NSImage {}
+ (void) setNSImageClass: (Class) aClass;
@end

#endif // __CLIMAGE_H__
