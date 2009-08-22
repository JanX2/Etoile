/** <title>ETBezierHandle</title>
	
	<abstract>ETHandle related classes for manipulating a NSBezierPath</abstract>

	Copyright (C) 2009 Eric Wasylishen

	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date: August 2009
	License:  Modified BSD (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/ETHandle.h>
#import <EtoileUI/ETLayoutItem.h>
#import <EtoileUI/ETLayoutItemGroup.h>
#import <EtoileUI/ETActionHandler.h>
#import <EtoileUI/ETStyle.h>

@class ETInstrument; 


@interface ETBezierHandleGroup : ETHandleGroup
{

}

- (id) initWithManipulatedObject: (id)aTarget;


- (void) render: (NSMutableDictionary *)inputValues 
	  dirtyRect: (NSRect)dirtyRect
      inContext: (id)ctxt;
- (void) drawOutlineInRect: (NSRect)rect;

@end

/* Action and Style Aspects */

@interface ETBezierPointActionHandler : ETHandleActionHandler
- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta;
@end

@interface ETBezierControlPointActionHandler : ETHandleActionHandler
- (void) handleTranslateItem: (ETHandle *)handle byDelta: (NSSize)delta;
@end

@interface ETBezierPointStyle : ETBasicHandleStyle
+ (id) sharedInstance;
- (void) drawHandleInRect: (NSRect)rect;
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect;
@end

@interface ETBezierControlPointStyle : ETBasicHandleStyle
+ (id) sharedInstance;
- (void) drawHandleInRect: (NSRect)rect;
- (void) drawSelectionIndicatorInRect: (NSRect)indicatorRect;
@end

