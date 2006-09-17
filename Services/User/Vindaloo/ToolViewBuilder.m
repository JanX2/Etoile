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

#include <ToolViewBuilder.h>
#include <Foundation/NSException.h>

const float kDefaulToolViewSpacing = 5.0;

/**
 * Non-Public methods.
 */
@interface ToolViewBuilder (Private)
- (void) myCenterViewVertically: (NSView*)aView;
- (void) myEnsureViewFitsInTargetView: (NSView*)aView;
@end


@implementation ToolViewBuilder

- (id) initWithView: (NSView*)aView yBorder: (float)points
{
   self = [super init];
   if (self)
   {
      [self setSpacing: kDefaulToolViewSpacing];
      yBorder = points;
      view = aView;
      runningX = 0.0;
      requiredWidth = 0.0;
      isFirstSubview = YES;
      verticallyCenteredViews = [[NSMutableSet alloc] init];
   }

   return self;
}

- (id) initWithView: (NSView*)aView
{
   return [self initWithView: aView yBorder: 0.0];
}

- (void) dealloc
{
   [verticallyCenteredViews release];
   [super dealloc];
}

+ (ToolViewBuilder*) builderWithView: (NSView*)aView
{
   return [self builderWithView: aView yBorder: 0.0];
}

+ (ToolViewBuilder*) builderWithView: (NSView*)aView yBorder: (float)points
{
   return [[[self alloc] initWithView: aView yBorder: points] autorelease];
}

- (NSView*) view
{
   return view;
}

- (ToolViewBuilder*) setSpacing: (float)aSpacing
{
   NSAssert(aSpacing >= 0, @"negative spacing");
   spacing = aSpacing;
   return self;
}

- (float) spacing
{
   return spacing;
}

- (float) yBorder
{
   return yBorder;
}

- (ToolViewBuilder*) advance: (float)points
{
   runningX = runningX + points;
   requiredWidth = requiredWidth + points;
   return self;
}

- (float) xPos
{
   return runningX;
}

- (float) requiredWidth
{
   return requiredWidth;
}

- (ToolViewBuilder*) addView: (NSView*)aView
{
   if (!isFirstSubview)
   {
      [self advance: [self spacing]];
   }
   else
   {
      isFirstSubview = NO;
   }

   [aView setFrameOrigin: NSMakePoint([self xPos], NSMinY([aView frame]))];
   [[self view] addSubview: aView];
   
   runningX = runningX + NSWidth([aView frame]);
   requiredWidth = requiredWidth + NSWidth([aView frame]);
   
   [self myEnsureViewFitsInTargetView: aView];
   
   return self;
}

- (ToolViewBuilder*) addViewVerticallyCentered: (NSView*)aView
{
   [self myCenterViewVertically: aView];
   [verticallyCenteredViews addObject: aView];

   return [self addView: aView];
}

- (ToolViewBuilder*) recenterViewsVertically
{
   NSEnumerator* e = [verticallyCenteredViews objectEnumerator];

   NSView* aView;
   while ((aView = [e nextObject]))
   {
      [self myCenterViewVertically: aView];
   }

   return self;
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation ToolViewBuilder (Private)

- (void) myCenterViewVertically: (NSView*)aView
{
   NSRect viewFrame = [aView frame];

   [aView setFrameOrigin:
      NSMakePoint(NSMinX(viewFrame),
                 (NSHeight([[self view] frame]) / 2) - (NSHeight(viewFrame) / 2))];
}

- (void) myEnsureViewFitsInTargetView: (NSView*)aView
{
   BOOL needsRecenter = NO;
   
   NSRect actualFrame = [[self view] frame];
   NSSize newSize = actualFrame.size;

   if ([self requiredWidth] > NSWidth(actualFrame))
   {
      newSize.width = [self requiredWidth];
   }

   float minRequiredHeight = NSHeight([aView frame]) + ([self yBorder] * 2);
   if (minRequiredHeight > NSHeight(actualFrame))
   {
      newSize.height = minRequiredHeight;
      needsRecenter = YES;
   }
   
   if (!NSEqualSizes(actualFrame.size, newSize))
   {
      [[self view] setFrameSize: newSize];
      if (needsRecenter)
      {
         [self recenterViewsVertically];
      }
   }
}

@end
