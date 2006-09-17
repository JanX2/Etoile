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

#import "NSView+Scrolling.h"


@implementation NSView (Scrolling)

- (void) scrollToTop
{
   if (![self enclosingScrollView])
   {
      return;
   }
   
   NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
   [self scrollPoint: NSMakePoint(NSMinX(visibleRect), NSHeight([self frame]))];
}

- (void) scrollToBottom
{
   if (![self enclosingScrollView])
   {
      return;
   }

   NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
   [self scrollPoint: NSMakePoint(NSMinX(visibleRect), 0)];
}

- (BOOL) scrollPageUp
{
   if (![self enclosingScrollView])
   {
      return NO;
   }
   
   return [self scrollUp: [[self enclosingScrollView] verticalPageScroll]];
}

- (BOOL) scrollPageDown
{
   if (![self enclosingScrollView])
   {
      return NO;
   }
   
   return [self scrollDown: [[self enclosingScrollView] verticalPageScroll]];
}

- (BOOL) scrollLineUp
{
   if (![self enclosingScrollView])
   {
      return NO;
   }
   
   return [self scrollUp: [[self enclosingScrollView] verticalLineScroll]];
}

- (BOOL) scrollLineDown
{
   if (![self enclosingScrollView])
   {
      return NO;
   }
   
   return [self scrollDown: [[self enclosingScrollView] verticalLineScroll]];
}

- (BOOL) scrollUp: (float)amount
{
   if (![self enclosingScrollView])
   {
      return NO;
   }
   
   NSAssert(amount > 0, @"negative amount");
   
   NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
   NSPoint targetPoint = NSMakePoint(NSMinX(visibleRect),
                         NSMinY(visibleRect) + amount);

   float maxY = NSHeight([self frame]) - NSHeight(visibleRect);
   if (targetPoint.y > maxY)
   {
      targetPoint.y = maxY;
   }
   [self scrollPoint: targetPoint];
   
   return !NSEqualRects(visibleRect, [[self enclosingScrollView] documentVisibleRect]);
}

- (BOOL) scrollDown: (float)amount
{
   if (![self enclosingScrollView])
   {
      return NO;
   }
   
   NSAssert(amount > 0, @"negative amount");
   
   NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
   NSPoint targetPoint = NSMakePoint(NSMinX(visibleRect),
                         NSMinY(visibleRect) - amount);

   if (targetPoint.y < 0)
   {
      targetPoint.y = 0;
   }
   [self scrollPoint: targetPoint];
   
   return !NSEqualRects(visibleRect, [[self enclosingScrollView] documentVisibleRect]);
}

- (void) scrollToLeftEdge
{
   if (![self enclosingScrollView])
   {
      return;
   }
   
   NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
   NSPoint targetPoint = NSMakePoint(0, NSMinY(visibleRect));
   
   [self scrollPoint: targetPoint];
}

- (void) scrollToRightEdge
{
   if (![self enclosingScrollView])
   {
      return;
   }

   NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
   NSPoint targetPoint = NSMakePoint(NSWidth([self frame]) - NSWidth(visibleRect),
                                     NSMinY(visibleRect));

   [self scrollPoint: targetPoint];
}

- (BOOL) scrollLineLeft
{
   if (![self enclosingScrollView])
   {
      return NO;
   }
   
   return [self scrollLeft: [[self enclosingScrollView] horizontalLineScroll]];
}

- (BOOL) scrollLineRight
{
   if (![self enclosingScrollView])
   {
      return NO;
   }

   return [self scrollRight: [[self enclosingScrollView] horizontalLineScroll]];
}

- (BOOL) scrollLeft: (float)amount
{
   if (![self enclosingScrollView])
   {
      return NO;
   }

   NSAssert(amount > 0, @"negative amount");

   NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
   NSPoint targetPoint = NSMakePoint(NSMinX(visibleRect) - amount,
                                     NSMinY(visibleRect));

   if (targetPoint.x < 0)
   {
      targetPoint.x = 0;
   }
   [self scrollPoint: targetPoint];

   return !NSEqualRects(visibleRect, [[self enclosingScrollView] documentVisibleRect]);
}

- (BOOL) scrollRight: (float)amount
{
   if (![self enclosingScrollView])
   {
      return NO;
   }

   NSAssert(amount > 0, @"negative amount");

   NSRect visibleRect = [[self enclosingScrollView] documentVisibleRect];
   NSPoint targetPoint = NSMakePoint(NSMinX(visibleRect) + amount,
                                     NSMinY(visibleRect));

   float maxX = NSWidth([self frame]) - NSWidth(visibleRect);
   if (targetPoint.x > maxX)
   {
      targetPoint.x = maxX;
   }
   [self scrollPoint: targetPoint];

   return !NSEqualRects(visibleRect, [[self enclosingScrollView] documentVisibleRect]);
}

@end

