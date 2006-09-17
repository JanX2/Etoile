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

#import "DocumentWindow.h"
#import "Controller.h"

/**
 * Non-Public methods.
 */
@interface DocumentWindow (Private)
@end


@implementation DocumentWindow

- (id) initWithContentRect: (NSRect)aContentRect
                 styleMask: (unsigned int)aStyleMask
                   backing: (NSBackingStoreType) aBackingType
                     defer: (BOOL)defer
{
   self = [super initWithContentRect: aContentRect
                           styleMask: aStyleMask
                             backing: aBackingType
                               defer: defer];
   if (self)
   {
      // ...
   }
   
   return self;
}

- (void) dealloc
{
   [super dealloc];
}

- (void) keyDown: (NSEvent*)theEvent
{
   NSString* chars = [theEvent characters];
   
   if ([chars length] == 0)
   {
      return;
   }
  
   unichar firstChar = [chars characterAtIndex: 0];
   BOOL shiftKey = ([theEvent modifierFlags] & NSShiftKeyMask) > 0;
   BOOL cmdKey  = ([theEvent modifierFlags] & NSCommandKeyMask) > 0;

   switch (firstChar)
   {
      case NSPageUpFunctionKey:
         [[self delegate] scrollPageUp: self];
         break;
      case NSPageDownFunctionKey:
         [[self delegate] scrollPageDown: self];
         break;
      case 0x20:
         if (shiftKey)
            [[self delegate] scrollPageUp: self];
         else
            [[self delegate] scrollPageDown: self];
         break;
      case NSLeftArrowFunctionKey:
         if (cmdKey)
            [[self delegate] scrollToLeftEdge: self];
         else
            [[self delegate] scrollLineLeft: self];
         break;
      case NSRightArrowFunctionKey:
         if (cmdKey)
            [[self delegate] scrollToRightEdge: self];
         else
            [[self delegate] scrollLineRight: self];
         break;
      case NSUpArrowFunctionKey:
         if (cmdKey)
            [[self delegate] scrollToTop: self];
         else
            [[self delegate] scrollLineUp: self];
         break;
      case NSDownArrowFunctionKey:
         if (cmdKey)
            [[self delegate] scrollToBottom: self];
         else
            [[self delegate] scrollLineDown: self];
         break;
      case 27: 
         [[self delegate] abortCurrentAction: self];
         break;
   }
}

@end


/* ----------------------------------------------------- */
/*  Category Private                                     */
/* ----------------------------------------------------- */

@implementation DocumentWindow (Private)
@end
