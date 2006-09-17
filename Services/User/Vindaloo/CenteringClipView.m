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

#import "CenteringClipView.h"


@implementation CenteringClipView

- (id) initWithFrame: (NSRect)aFrame
{
   return [super initWithFrame: aFrame];
}

- (void) centerDocumentView
{
   NSRect docRect = [[self documentView] frame];
   NSRect clipRect = [self bounds];

   if(docRect.size.width < clipRect.size.width)
   {
      clipRect.origin.x = (docRect.size.width - clipRect.size.width) / 2.0;
   }

   if(docRect.size.height < clipRect.size.height)
   {
      clipRect.origin.y = (docRect.size.height - clipRect.size.height) / 2.0;
   }

   // Probably the most efficient way to move the bounds origin.
   [self scrollToPoint: clipRect.origin];

   // We could use this instead since it allows a scroll view to
   // coordinate scrolling between multiple clip views.
   //[[self superview] scrollClipView:self toPoint:clipRect.origin];
}

// We need to override this so that the superclass doesn't override our new
// origin point.
- (NSPoint) constrainScrollPoint: (NSPoint)proposedNewOrigin
{
   NSRect docRect = [[self documentView] frame];
   NSRect clipRect = [self bounds];
   NSPoint newScrollPoint = proposedNewOrigin;

   float maxX = docRect.size.width - clipRect.size.width;
   float maxY = docRect.size.height - clipRect.size.height;

   // If the clip view is wider than the doc, we can't scroll horizontally
   if(docRect.size.width < clipRect.size.width)
   {
      newScrollPoint.x = maxX / 2.0;
   }
   else
   {
      newScrollPoint.x = MAX(0, MIN(newScrollPoint.x,maxX));
   }

   // If the clip view is taller than the doc, we can't scroll vertically
   if(docRect.size.height < clipRect.size.height)
   {
      newScrollPoint.y = maxY / 2.0;
   }
   else
   {
      newScrollPoint.y = MAX(0, MIN(newScrollPoint.y,maxY));
   }

   return newScrollPoint;
}

- (void) viewBoundsChanged: (NSNotification*)aNotification
{
   [super viewBoundsChanged: aNotification];
   [self centerDocumentView];
}

- (void) viewFrameChanged: (NSNotification*)aNotification
{
   [super viewFrameChanged: aNotification];
   [self centerDocumentView];
}

- (void) setFrame: (NSRect)aFrame
{
   [super setFrame: aFrame];
   [self centerDocumentView];
}

- (void) setFrameOrigin: (NSPoint)aPoint
{
   [super setFrameOrigin: aPoint];
   [self centerDocumentView];
}

- (void) setFrameSize: (NSSize)aSize
{
   [super setFrameSize: aSize];
   [self centerDocumentView];
}

- (void) setFrameRotation: (float)anAngle
{
   [super setFrameRotation: anAngle];
   [self centerDocumentView];
}

@end
