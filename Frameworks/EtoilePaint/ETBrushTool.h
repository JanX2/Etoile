/** <title>ETBrushTool</title>
 
 <abstract>An tool class which implements the paintbrush tool 
 tool present in many graphics-oriented applications.</abstract>
 
 Copyright (C) 2009 Eric Wasylishen
 
 Author:  Eric Wasylishen <ewasylishen@gmail.com>
 Date:  July 2009
 License:  Modified BSD (see COPYING)
 */

#import <EtoileFoundation/EtoileFoundation.h>
#import <AppKit/AppKit.h>
#import <EtoileUI/EtoileUI.h>
#import "ETDrawingStrokeShape.h"

@interface ETBrushTool : ETTool
{
	ETLayoutItem *_brushStroke;
	ETDrawingStrokeShape *_drawingStrokeShape;
	NSPoint _start;
	NSPoint _startInTargetContainer;
}


@end
