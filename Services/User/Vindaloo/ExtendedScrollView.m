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

#import "ExtendedScrollView.h"

/**
 * Non-Public methods.
 */
@interface ExtendedScrollView (Private)
- (void) _notifyDocumentView;
@end


@implementation ExtendedScrollView

- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
   [super resizeWithOldSuperviewSize: oldBoundsSize];
   if (![self inLiveResize])
   {
      [self _notifyDocumentView];
   }
}

- (void) viewDidEndLiveResize
{
   [self _notifyDocumentView];
}

@end

/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation ExtendedScrollView (Private)

- (void) _notifyDocumentView
{
   if ([[self documentView] respondsToSelector: @selector(scrollViewDidResize:)])
   {
      [[self documentView] scrollViewDidResize: self];
   }
}

@end
