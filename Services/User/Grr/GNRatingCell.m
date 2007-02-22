/*
   Grr RSS Reader
   
   Copyright (C) 2006, 2007 Guenther Noack <guenther@unix-ag.uni-kl.de>
   
   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License version 2 as published by the Free Software Foundation.
   
   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.
   
   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "GNRatingCell.h"

/**
 * This cell shows a rating displayed as 0 to 5 horizontally aligned stars. You can
 * modify the rating by clicking the desired position of the rightmost star. A click
 * left or right beyond the borders of the rectangle that would surround five stars
 * sets the number of stars to the maximum 5 or the minimum 0.
 * 
 * Revision History
 *   Nov 20 2006 - Initial version
 * 
 * FIXME: Why does NSTableView open a *text editing field* when you double click on this
 *        view in a table?!?
 */
@implementation GNRatingCell

// ----------------------------------------------------------------
//    initializers
// ----------------------------------------------------------------

-(id) initTextCell: (NSString*) text
{
    return [self initImageCell: [NSImage imageNamed: @"Star"]];
}

-(id) initImageCell: (NSImage*) image
{
    if ((self = [super initImageCell: image]) != nil) {
        ASSIGN(star, image);
    }
    
    return self;
}

// ----------------------------------------------------------------
//    mouse tracking
// ----------------------------------------------------------------

-(BOOL) trackMouse: (NSEvent*) theEvent
            inRect: (NSRect) cellFrame
            ofView: (NSView*) controlView
      untilMouseUp: (BOOL) flag
{
    // Just remember the rect of the cell, then go on with tracking
    // and wait for the call to stopTracking:at:inView:mouseIsUp:
    _currentTrackingRect = cellFrame;
    
    return [super trackMouse: theEvent
                      inRect: cellFrame
                      ofView: controlView
                untilMouseUp: flag];
}


-(void) stopTracking: (NSPoint)lastPoint
                  at: (NSPoint)stopPoint
              inView: (NSView*)aView
           mouseIsUp: (BOOL)isUpFlag
{
    if (isUpFlag) {
        NSSize size = [star size];
        
        // The field _currentTrackingRect is set by the trackMouse:inRect:ofView:untilMouseUp:
        // method before it calls the stopTracking:at:inView:mouseIsUp: (this) method. At the
        // moment I just trust nobody will call stopTracking:... manually.
        float leftestStarX = NSMidX(_currentTrackingRect) - size.width * 2.5;
        float rightestStarX = leftestStarX + size.width * 5.0;
        
        if (stopPoint.x <= leftestStarX) {
            [self setIntValue: 0];
        } else if (stopPoint.x <= rightestStarX) {
            float res = ((stopPoint.x - leftestStarX) / size.width) + 1.0;
            [self setFloatValue: res];
        } else {
            [self setIntValue: 5];
        }
    }
}


// ----------------------------------------------------------------
//    GNUstep workaround for buggy NSTableView behaviour
// ----------------------------------------------------------------
#ifdef GNUSTEP
/* 
 * According to Matt Rice, switching off editability for a cell
 * lets the mouse tracking still work. As long as the table column
 * is still editable, updating changed table cells works, too.
 * This is undefined behaviour, though, and may not work in future
 * releases of GNUstep.
 * 
 * This doesn't work for me on GNUstep stable in Nov 2006. It's
 * probably different for the SVN version.
 */
-(BOOL) isEditable {
    return NO;
}
#endif

// ----------------------------------------------------------------
//    drawing
// ----------------------------------------------------------------

-(void) drawInteriorWithFrame: (NSRect)cellFrame inView: (NSView*)controlView
{
    if (star == nil) {
        // init didn't take place, let's do something about it fast!
        ASSIGN(star, [NSImage imageNamed: @"Star"]);
    }
    
    NSSize size = [star size];
    NSPoint position;
    
    position.x = MAX(NSMidX(cellFrame) - (size.width * 2.5),  0.0);
    position.y = MAX(NSMidY(cellFrame) - (size.height / 2.0), 0.0);
    
    if ([controlView isFlipped]) {
        position.y += size.height;
    }
    
    int i;
    int num = [self intValue];
    
    for (i=0; i<num; i++) {
        [star compositeToPoint: position
                     operation: NSCompositeSourceOver];
        
        position.x += size.width;
    }
    
    for (;i<5;i++) {
        [star dissolveToPoint: position
                     fraction: 0.2];
        
        position.x += size.width;
    }
}

@end

