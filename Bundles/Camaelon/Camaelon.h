#ifndef __THEME_H__
#define __THEME_H__

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include "Image.h"

@interface Camaelon : NSObject
{
    NSBundle* bundle;
    NSString* themeName;
    NSString* themePath;
}
- (NSString*) themePath;
+ (Camaelon*) sharedTheme;
@end

#endif
