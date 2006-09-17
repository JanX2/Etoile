/*
 * Copyright (C) 2004  Stefan Kleine Stegemann
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#import <Foundation/NSSet.h>
#import <AppKit/NSView.h>

extern const float kDefaulToolViewSpacing;

/**
 * A helper to put items on a view in a simple, toolbar
 * like manner from left to right.
 */
@interface ToolViewBuilder : NSObject
{
   float          spacing;
   float          yBorder;
   NSView*        view;
   float          runningX;
   float          requiredWidth;
   BOOL           isFirstSubview;
   NSMutableSet*  verticallyCenteredViews;
}

- (id) initWithView: (NSView*)aView;
- (id) initWithView: (NSView*)aView yBorder: (float)points;

+ (ToolViewBuilder*) builderWithView: (NSView*)aView;
+ (ToolViewBuilder*) builderWithView: (NSView*)aView yBorder: (float)points;

/** Get the target view */
- (NSView*) view;

/** Spacing between two elements (subviews) on the ToolView.
    Defaults to kDefaulToolViewSpacing. Changing this property
    has only effect on subviews which are added subsequently.  */
- (ToolViewBuilder*) setSpacing: (float)aSpacing;
- (float) spacing;

/** The guaranteed border (free space) above and below the subviews
    in points.  */
- (float) yBorder;

/** Advance the current position on the X axis by n points.  */
- (ToolViewBuilder*) advance: (float)points;

/** Get the current position on the X axis.  */
- (float) xPos;

/** Get the minimum width that is required for the builder's'
    target view to show all subviews.  */
- (float) requiredWidth;

/* Adding subviews. */
- (ToolViewBuilder*) addView: (NSView*)aView;
- (ToolViewBuilder*) addViewVerticallyCentered: (NSView*)aView;

/** Ensure that all subviews, which have been added vertically centered
    are centered properly. This method is usefull if you change the height
    of the builder's target view.  */
- (ToolViewBuilder*) recenterViewsVertically;

@end
