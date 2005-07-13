#include <AppKit/AppKit.h>
#include <Foundation/Foundation.h>
#include "GNUstepGUI/GSDrawFunctions.h"
#include "NSBezierPath+round.h"
#include "GraphicToolbox.h"
#include "CLCache.h"
#include "CLCompositor.h"
#include "CLHBoxCompositor.h"
#include "CLVBoxCompositor.h"
#include "CLBoxCompositor.h"
#include "NSColor.h"

#ifndef __GSDRAWFUNCTIONS_H__
#define __GSDRAWFUNCTIONS_H__

@interface GSDrawFunctions (theme)
+ (NSRect) drawGrayBezelRound: (NSRect)border : (NSRect)clip;
+ (NSRect) drawGrayBezel: (NSRect)border : (NSRect)clip;
+ (NSRect) drawGroove: (NSRect)border : (NSRect)clip;
+ (NSColor*) browserHeaderTextColor;
+ (void) drawBrowserHeaderInRect: (NSRect) frame;
+ (float) ListHeaderHeight;
+ (void) drawTableHeaderCornerInRect: (NSRect) frame;
+ (void) drawTableHeaderInRect: (NSRect) frame;
+ (void) drawTableHeaderCellInRect: (NSRect) frame highlighted: (BOOL) highlighted;
+ (void) drawGradient: (NSData*) gradient withSize: (NSArray*) size border: (NSRect) border;
+ (void) drawHorizontalGradient: (NSColor*) start to: (NSColor*) end frame: (NSRect) frame;
+ (void) drawVerticalGradient: (NSColor*) start to: (NSColor*) end frame: (NSRect) frame;
+ (void) drawDiagonalGradient: (NSColor*) start to: (NSColor*) end frame: (NSRect) frame direction: (int) direction;
+ (void) drawRadioButton: (NSRect) border inView: (NSView*) view highlighted: (BOOL) highlighted;
+ (void) drawMenu: (NSRect) border inView: (NSView*) view;
+ (void) drawTextField: (NSRect) border focus: (BOOL) focus flipped: (BOOL) flipped;
+ (void) drawButton: (NSRect) border inView: (NSView*) view style: (NSBezelStyle) bezelStyle highlighted: (BOOL) highlighted;
+ (void) drawProgressIndicatorBackgroundOn: (NSView*) view;
+ (void) drawProgressIndicatorForegroundInRect: (NSRect) rect;
+ (void) drawTitleBox: (NSRect) rect on: (id) box;
+ (void) drawBox: (NSRect) rect on: (id) box;
+ (void) drawWindowBackground: (NSRect) rect on: (id) window;
+ (void) drawPopupButton: (NSRect) border inView: (NSView*) view;
+ (void) drawHorizontalScrollerKnob: (NSRect) knob on: (NSView*) view;
+ (void) drawVerticalScrollerKnob: (NSRect) knob on: (NSView*) view;
+ (void) drawHorizontalScrollerSlot: (NSRect) slot knobPresent: (BOOL) knob 
	   buttonPressed: (int) buttonPressed on: (NSView*) view;
+ (void) drawVerticalScrollerSlot: (NSRect) slot knobPresent: (BOOL) knob 
	   buttonPressed: (int) buttonPressed on: (NSView*) view;
+ (void) drawTopTabFill: (NSRect) rect selected: (BOOL) selected on: (NSView*) view;
+ (void) drawTabFrame: (NSRect) rect on: (NSView*) view;
+ (void) drawScrollViewFrame: (NSRect) rect on: (NSView*) view;
+ (void) drawFocusFrame: (NSRect) cellFrame;
@end

#endif // __GSDRAWFUNCTIONS_H__
