#include <AppKit/AppKit.h>
#include <Foundation/Foundation.h>
#include "CLCache.h"

#ifndef __IMAGE_PROVIDER_H__
#define __IMAGE_PROVIDER_H__

@interface ImageProvider : NSObject
{
}
+ (NSImage*) leftPartOfImage: (NSImage*) base;
+ (NSImage*) rightPartOfImage: (NSImage*) base;
+ (NSImage*) TabsSelectedLeft;
+ (NSImage*) TabsSelectedRight;
+ (NSImage*) TabsUnselectedLeft;
+ (NSImage*) TabsUnselectedRight;
+ (NSImage*) TabsUnselectedJunction;
+ (NSImage*) TabsUnselectedToSelectedJunction;
+ (NSImage*) TabsSelectedToUnselectedJunction;
@end

#endif // __IMAGE_PROVIDER_H__

