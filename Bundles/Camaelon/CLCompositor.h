#include <AppKit/AppKit.h>
#include <Foundation/Foundation.h>
#include "CLCache.h"
#include "GraphicToolbox.h"

#ifndef __CLCompositor_H__
#define __CLCompositor_H__

typedef enum {
	CLFillColor = 0,
	CLFillScaledImage = 1,
	CLFillTiledImage = 2
} CLFill;

@interface CLCompositor : NSObject
{
	NSString* name;
	NSMutableDictionary* images;
	CLCache* cache;
}
- (void) setName: (NSString*) n;
- (void) error: (NSString*) msg;
- (void) addImage: (NSImage*) image named: (NSString*) name;
- (void) drawOn: (NSView*) view;
- (void) drawInRect: (NSRect) rect;
@end

#endif // __CLCompositor_H__
