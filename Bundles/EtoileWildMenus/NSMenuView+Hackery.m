/*
   Copyright (C) 2004 Michael Hanni.

   Author: Michael Hanni <mhanni@yahoo.com>
   Date: 2004

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#import <AppKit/NSApplication.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSMenuItemCell.h>
#import <AppKit/NSWindow.h>
#import <AppKit/PSOperators.h>
#import "NSMenuView+Hackery.h"
#import "EtoileMenuTitleView.h"
#import "MenuBarHeight.h"
#import "MHMenuItemCell.h"

enum {
  BottomBorderOffset = 1
};


@implementation NSMenuView (Hackery)
- (NSRect) rectOfItemAtIndex: (int)index
{
  NSRect theRect;
      
  if (_needsSizing == YES)
    {
      [self sizeToFit];
    }
      
  /* Fiddle with the origin so that the item rect is shifted 1 pixel over
   */
  theRect.size = _cellSize;

  if (_horizontal == NO)
    { 
      if (![_attachedMenu _ownedByPopUp])
        {
          theRect.origin.y = 1 + (_cellSize.height * ([_itemCells count] - 
						  index - 1));
          theRect.origin.x = 1;
          theRect.size.width -= 1;
        }
      else
        {
          theRect.origin.y = _cellSize.height * ([_itemCells count] - index - 1);
      	  theRect.origin.x = _leftBorderOffset;
        }
    }
  else
    {
      // FIXME: or remove?
      theRect.origin.x = _cellSize.width * (index + 1);
      theRect.origin.y = 0;
    }
      
  /* NOTE: This returns the correct NSRect for drawing cells, but nothing
   * else (unless we are a popup). This rect will have to be modified for
   * event calculation, etc..
   */ 
  return theRect;
}

- (NSPoint) locationForSubmenu: (NSMenu *)aSubmenu
{
  NSRect frame = [_window frame];
  NSRect submenuFrame;  
     
  if (_needsSizing)
    [self sizeToFit];

  if (aSubmenu)
    submenuFrame = [[[aSubmenu menuRepresentation] window] frame];
  else
    submenuFrame = NSZeroRect;
            
  if (_horizontal == YES)
    {
      NSRect aRect = [self rectOfItemAtIndex:
                       [_attachedMenu indexOfItemWithSubmenu: aSubmenu]];
      NSPoint subOrigin = [_window convertBaseToScreen:
                                    NSMakePoint(NSMinX(aRect),
                                    NSMinY(aRect))];
          
      return NSMakePoint(subOrigin.x, subOrigin.y - NSHeight(submenuFrame));
    }
  else
    {
      NSRect aRect = [self rectOfItemAtIndex:
            [_attachedMenu indexOfItemWithSubmenu: aSubmenu]];
      NSPoint subOrigin = [_window convertBaseToScreen:
            NSMakePoint(aRect.origin.x, aRect.origin.y)];

      return NSMakePoint (NSMaxX(frame),
        subOrigin.y - NSHeight(submenuFrame) + aRect.size.height +
        [EtoileMenuTitleView height]);
    }
}

- (void) sizeToFit
{
  unsigned i;
  unsigned howMany = [_itemCells count];
  unsigned wideTitleView = 1;
  float    neededImageAndTitleWidth = 0.0;
  float    neededKeyEquivalentWidth = 0.0;
  float    neededStateImageWidth = 0.0;
  float    accumulatedOffset = 0.0;
  float    popupImageWidth = 0.0;

  // Popup menu doesn't need title bar
  if (![_attachedMenu _ownedByPopUp])
    {
        if ([_attachedMenu supermenu] != nil)
        {
//             @try
//             {
//                 NSMenuItemCell *msr = [[[_attachedMenu supermenu] menuRepresentation] 
//                                           menuItemCellForItemAtIndex:
//                                               [[_attachedMenu supermenu] indexOfItemWithTitle: [_attachedMenu title]]];
//                 neededImageAndTitleWidth += [msr titleWidth] + GSCellTextImageXDist;
//             }
//             @catch(id e)
//             {
                neededImageAndTitleWidth += 100;
//             }
        }
    }

  for (i = 0; i < howMany; i++)
    {
      float aStateImageWidth;
      float aTitleWidth;
      float anImageWidth;
      float anImageAndTitleWidth;
      float aKeyEquivalentWidth;
      NSMenuItemCell *aCell = [_itemCells objectAtIndex: i];
     
      // State image area.
      aStateImageWidth = [aCell stateImageWidth];
     
      // Title and Image area.
      aTitleWidth = [aCell titleWidth];
      anImageWidth = [aCell imageWidth]; 
     
      // Key equivalent area.
      aKeyEquivalentWidth = [aCell keyEquivalentWidth];
     
      switch ([aCell imagePosition])
        {
        case NSNoImage:  
          anImageAndTitleWidth = aTitleWidth;
          break;
      
        case NSImageOnly:
          anImageAndTitleWidth = anImageWidth;
          break;
     
        case NSImageLeft:
        case NSImageRight:
          anImageAndTitleWidth = anImageWidth + aTitleWidth + GSCellTextImageXDist;
          break;

        case NSImageBelow:
        case NSImageAbove:
        case NSImageOverlaps:
        default:
          if (aTitleWidth > anImageWidth)
            anImageAndTitleWidth = aTitleWidth;
          else  
            anImageAndTitleWidth = anImageWidth;
          break;
        }
          
      if (aStateImageWidth > neededStateImageWidth)
        neededStateImageWidth = aStateImageWidth;
        
      if (anImageAndTitleWidth > neededImageAndTitleWidth)
        neededImageAndTitleWidth = anImageAndTitleWidth;

      if (aKeyEquivalentWidth > neededKeyEquivalentWidth)
        neededKeyEquivalentWidth = aKeyEquivalentWidth;
        
      // Title view width less than item's left part width
      if ((anImageAndTitleWidth + aStateImageWidth)
          > neededImageAndTitleWidth)
        wideTitleView = 0;
      
      // Popup menu has only one item with nibble or arrow image
      if (anImageWidth)
        popupImageWidth = anImageWidth;
    }
        
  // Cache the needed widths.
  _stateImageWidth = neededStateImageWidth;
  _imageAndTitleWidth = neededImageAndTitleWidth;
  _keyEqWidth = neededKeyEquivalentWidth;
      
  accumulatedOffset = _horizontalEdgePad;
  if (howMany)
    {
      // Calculate the offsets and cache them.
      if (neededStateImageWidth)
        {
          _stateImageOffset = accumulatedOffset;
          accumulatedOffset += neededStateImageWidth += _horizontalEdgePad;
        }
        
      if (neededImageAndTitleWidth)
        {
          _imageAndTitleOffset = accumulatedOffset;
          accumulatedOffset += neededImageAndTitleWidth;
        }

      if (wideTitleView)
        {
          _keyEqOffset = accumulatedOffset = neededImageAndTitleWidth
            + (3 * _horizontalEdgePad);
        }
      else
        {
          _keyEqOffset = accumulatedOffset += (2 * _horizontalEdgePad);
        }
      accumulatedOffset += neededKeyEquivalentWidth + _horizontalEdgePad;
        
      if ([_attachedMenu supermenu] != nil && neededKeyEquivalentWidth < 8)
        {
          accumulatedOffset += 8 - neededKeyEquivalentWidth;
        }
    }
  else
    {
      accumulatedOffset += neededImageAndTitleWidth + 3 + 2;
      if ([_attachedMenu supermenu] != nil)
        accumulatedOffset += 15;
        accumulatedOffset += 15;
    }

  // Calculate frame size.
  if (![_attachedMenu _ownedByPopUp])
    {
      // Add the border width: 1 for left, 2 for right sides
      _cellSize.width = accumulatedOffset + 3;
    }
  else   
    {
      _keyEqOffset = _cellSize.width - _keyEqWidth - popupImageWidth;
    }

  if (_horizontal == YES)
    {
      [self setFrameSize: NSMakeSize(((howMany + 1) * _cellSize.width),
                                     _cellSize.height + _leftBorderOffset)];
      [_titleView setFrame: NSMakeRect (0, 0,
                                        _cellSize.width, _cellSize.height + 1)];
    }
  else
    {
      [self setFrameSize: NSMakeSize(_cellSize.width + _leftBorderOffset,
        (howMany * _cellSize.height) + [EtoileMenuTitleView height] +
        BottomBorderOffset)];
      [_titleView setFrame: NSMakeRect (0, howMany * _cellSize.height +
        BottomBorderOffset, NSWidth (_bounds), [EtoileMenuTitleView height])];
    }
     
  _needsSizing = NO;
}

- (void) update
{
  if ([self isHorizontal])
    {
      if (_titleView != nil)
        {
          [_titleView removeFromSuperview];
          _titleView = nil;
        }
    }
  else
    {
      if (![_attachedMenu _ownedByPopUp] && !_titleView)
        {
          _titleView = [[EtoileMenuTitleView alloc]
            initWithOwner:_attachedMenu];
          [self addSubview: _titleView];
          RELEASE(_titleView);
        }
      else if ([_attachedMenu _ownedByPopUp] && _titleView)
        {
          [_titleView removeFromSuperview];
          _titleView = nil;
        }

      [self sizeToFit];

      if ([_attachedMenu _ownedByPopUp] == NO)
        {
          if ([_attachedMenu isTornOff] && ![_attachedMenu isTransient])
            {
              [_titleView
                addCloseButtonWithAction: @selector(_performMenuClose:)];
              [_titleView setTitleVisible: YES];
            }
          else
            {
              [_titleView removeCloseButton];
              [_titleView setTitleVisible: NO];
            }
        }
    }
}

- (void) drawRect: (NSRect)rect
{
  NSRect myFrame;
  int        i;
  int        howMany = [_itemCells count];

  if (![_attachedMenu _ownedByPopUp])
    {
      NSDrawButton (_bounds, rect);
    }
  else
    {
      NSRectEdge sides[] = {NSMinXEdge, NSMaxYEdge};
      float      grays[] = {NSDarkGray, NSDarkGray}; 
      // Draw the dark gray upper left lines.
//      NSDrawTiledRects(_bounds, rect, sides, grays, 2);
    }

  PSsetgray(0.9);
  NSRectFill(rect);

  // Draw the menu cells.
  for (i = 0; i < howMany; i++)
    {
      NSRect            aRect;
      NSMenuItemCell    *aCell;
 
      aRect = [self rectOfItemAtIndex: i];
      if (NSIntersectsRect(rect, aRect) == YES)
        {
          aCell = [_itemCells objectAtIndex: i];
          [aCell drawWithFrame: aRect inView: self];
        }
    }

  myFrame = [self frame];

  [[NSColor whiteColor] set];
  PSmoveto(0, 0);
  PSrlineto(0, NSHeight(myFrame));
  PSrlineto(NSWidth(myFrame), 0);
  PSstroke();

  [[NSColor darkGrayColor] set];
  PSmoveto(NSMaxX(myFrame) - 1, NSMaxY(myFrame));
  PSrlineto(0, -(NSHeight(myFrame) - 1));
  PSrlineto(-NSWidth(myFrame), 0);
  PSstroke();
}

- (void) setFrame: (NSRect) r
{
  [super setFrame: r];
}

- (void) mouseDown: (NSEvent*)theEvent
{
  NSRect	currentFrame;
  NSRect	originalFrame;
  NSPoint	currentTopLeft;
  NSPoint	originalTopLeft = NSZeroPoint; /* Silence compiler.  */
  BOOL          restorePosition;
  /*
   * Only for non transient menus do we want
   * to remember the position.
   */ 
  restorePosition = ![_attachedMenu isTransient];
  if (restorePosition)
    { // store old position;
      originalFrame = [_window frame];
      originalTopLeft = originalFrame.origin;
      originalTopLeft.y += originalFrame.size.height;
    }
  
  [NSEvent startPeriodicEventsAfterDelay: 0.1 withPeriod: 0.01];
  [self trackWithEvent: theEvent];
  [NSEvent stopPeriodicEvents];

  if (restorePosition)
    {
      currentFrame = [_window frame];
      currentTopLeft = currentFrame.origin;
      currentTopLeft.y += currentFrame.size.height;

      if (NSEqualPoints(currentTopLeft, originalTopLeft) == NO)
        {
          NSPoint	origin = currentFrame.origin;
          
          origin.x += (originalTopLeft.x - currentTopLeft.x);
          origin.y += (originalTopLeft.y - currentTopLeft.y);
          [_attachedMenu nestedSetFrameOrigin: origin];
        }
    }
}

static BOOL grabbed = NO;

#define MOVE_THRESHOLD_DELTA 2.0
#define DELAY_MULTIPLIER     10

/** Overriden GNUstep version to capture mouse in order catch mouse events
    outside of menu or current application windows. We must close currently
    opened menu (and submenus) when we grab any mouse down event out of menu 
    views. */
- (BOOL) trackWithEvent: (NSEvent*)event
{
  unsigned    eventMask = NSPeriodicMask;
  NSDate        *theDistantFuture = [NSDate distantFuture];
  NSPoint    lastLocation = {0,0};
  BOOL        justAttachedNewSubmenu = NO;
  BOOL          subMenusNeedRemoving = YES;
  BOOL        shouldFinish = YES;
  int        delayCount = 0;
  int           indexOfActionToExecute = -1;
  int        firstIndex = -1;
  NSEvent    *original;
  NSEventType    type;
  NSEventType    end;

  //NSLog(@"Track event in menu %@", self);

  /*
   * The original event is unused except to determine whether the method
   * was invoked in response to a right or left mouse down.
   * We pass the same event on when we want tracking to move into a
   * submenu.
   */
  original = AUTORELEASE(RETAIN(event));

  type = [event type];

  if (type == NSRightMouseDown || type == NSRightMouseDragged)
    {
      end = NSRightMouseUp;
      eventMask |= NSRightMouseUpMask | NSRightMouseDraggedMask;
      eventMask |= NSRightMouseDownMask;
    }
  else if (type == NSOtherMouseDown || type == NSOtherMouseDragged)
    {
      end = NSOtherMouseUp;
      eventMask |= NSOtherMouseUpMask | NSOtherMouseDraggedMask;
      eventMask |= NSOtherMouseDownMask;
    }
  else if (type == NSLeftMouseDown || type == NSLeftMouseDragged)
    {
      end = NSLeftMouseUp;
      eventMask |= NSLeftMouseUpMask | NSLeftMouseDraggedMask;
      eventMask |= NSLeftMouseDownMask;
    }
  else
    {
      NSLog (@"Unexpected event: %d during event tracking in NSMenuView", type);
      end = NSLeftMouseUp;
      eventMask |= NSLeftMouseUpMask | NSLeftMouseDraggedMask;
      eventMask |= NSLeftMouseDownMask;
    }

// The window on which we call _releaseMouse: doesn't matter, it could be 
// different than the one we use as _captureMouse receiver.
  if (grabbed)
    [[self window] _releaseMouse: self];

  // Next line result in XGrabPointer() call (Xlib function).
  [[self window] _captureMouse: self];
  grabbed = YES;

  if ([self isHorizontal] == YES)
    {
      /*
       * Ignore the first mouse up if nothing interesting has happened.
       */
      //NSLog(@"Horizontal menu view tracking");
      shouldFinish = NO;
    }
  do
    {
      if (type == end)
        {
          shouldFinish = YES;
        }
      if (type == NSPeriodic || event == original)
        {
          NSPoint    location;
          int           index;

          location     = [_window mouseLocationOutsideOfEventStream];
          index        = [self indexOfItemAtPoint: location];

      if (event == original)
        {
          firstIndex = index;
        }
      if (index != firstIndex)
        {
          shouldFinish = YES;
        }

          /*
           * 1 - if menus is only partly visible and the mouse is at the
           *     edge of the screen we move the menu so it will be visible.
           */ 
          if ([_attachedMenu isPartlyOffScreen])
            {
              NSPoint pointerLoc = [_window convertBaseToScreen: location];
              /*
               * The +/-1 in the y - direction is because the flipping
               * between X-coordinates and GNUstep coordinates let the
               * GNUstep screen coordinates start with 1.
               */
              if (pointerLoc.x == 0 || pointerLoc.y == 1
                || pointerLoc.x == [[_window screen] frame].size.width - 1
                || pointerLoc.y == [[_window screen] frame].size.height)
                [_attachedMenu shiftOnScreen];
            }


          /*
           * 2 - Check if we have to reset the justAttachedNewSubmenu
           * flag to NO.
           */
          if (justAttachedNewSubmenu && index != -1
            && index != _highlightedItemIndex)
            { 
              if (location.x - lastLocation.x > MOVE_THRESHOLD_DELTA)
                {
                  delayCount ++;
                  if (delayCount >= DELAY_MULTIPLIER)
                    {
                      justAttachedNewSubmenu = NO;
                    }
                }
              else
                {
                  justAttachedNewSubmenu = NO;
                }
            }


          // 3 - If we have moved outside this menu, take appropriate action
          if (index == -1)
            {
              NSPoint   locationInScreenCoordinates;
              NSWindow *windowUnderMouse;
              NSMenu   *candidateMenu;

              subMenusNeedRemoving = NO;

              locationInScreenCoordinates
                = [_window convertBaseToScreen: location];

              /*
               * 3a - Check if moved into one of the ancester menus.
               *      This is tricky, there are a few possibilities:
               *          We are a transient attached menu of a
               *          non-transient menu
               *          We are a non-transient attached menu
               *          We are a root: isTornOff of AppMenu
               */
              candidateMenu = [_attachedMenu supermenu];
              while (candidateMenu  
                && !NSMouseInRect (locationInScreenCoordinates, 
                [[candidateMenu window] frame], NO) // not found yet
                && (! ([candidateMenu isTornOff] 
                && ![candidateMenu isTransient]))  // no root of display tree
                && [candidateMenu isAttached]) // has displayed parent
                {
                  candidateMenu = [candidateMenu supermenu];
                }

              if (candidateMenu != nil
                && NSMouseInRect (locationInScreenCoordinates,
                [[candidateMenu window] frame], NO))
                {
                  BOOL candidateMenuResult;

                  // The call to fetch attachedMenu is not needed. But putting
                  // it here avoids flicker when we go back to an ancestor 
                  // menu and the attached menu is already correct.
                  [[[candidateMenu attachedMenu] menuRepresentation]
                    detachSubmenu];

                  // Reset highlighted index for this menu.
                  // This way if we return to this submenu later there 
                  // won't be a highlighted item.
                  [[[candidateMenu attachedMenu] menuRepresentation]
                    setHighlightedItemIndex: -1];

                  candidateMenuResult = [[candidateMenu menuRepresentation]
                           trackWithEvent: original];

                  return candidateMenuResult;
                }

              // 3b - Check if we enter the attached submenu
              windowUnderMouse = [[_attachedMenu attachedMenu] window];
              if (windowUnderMouse != nil
                && NSMouseInRect (locationInScreenCoordinates,
                [windowUnderMouse frame], NO))
                {
                  BOOL wasTransient = [_attachedMenu isTransient];
                  BOOL subMenuResult;

                  subMenuResult
                    = [[self attachedMenuView] trackWithEvent: original];
                  if (subMenuResult
                    && wasTransient == [_attachedMenu isTransient])
                    {
                      [self detachSubmenu];
                    }
                  return subMenuResult;
                }
            }

          // 4 - We changed the selected item and should update.
          if (!justAttachedNewSubmenu && index != _highlightedItemIndex)
            {
              subMenusNeedRemoving = NO;
              [self detachSubmenu];
              [self setHighlightedItemIndex: index];

              // WO: Question?  Why the ivar _items_link
              if (index >= 0 && [[_items_link objectAtIndex: index] submenu])
                {
                  [self attachSubmenuForItemAtIndex: index];
                  justAttachedNewSubmenu = YES;
                  delayCount = 0;
                }
            }

          // Update last seen location for the justAttachedNewSubmenu logic.
          lastLocation = location;
        }

  //if ([event type] != NSPeriodic)
    //NSLog(@"In menu view pick %@", event);

      event = [NSApp nextEventMatchingMask: eventMask
        untilDate: theDistantFuture
        inMode: NSEventTrackingRunLoopMode
        dequeue: YES];
      type = [event type];
    }
  while (type != end || shouldFinish == NO);

  /*
   * Ok, we released the mouse
   * There are now a few possibilities:
   * A - We released the mouse outside the menu.
   *     Then we want the situation as it was before
   *     we entered everything.
   * B - We released the mouse on a submenu item
   *     (i) - this was highlighted before we started clicking:
   *           Remove attached menus
   *     (ii) - this was not highlighted before pressed the mouse button;
   *            Keep attached menus.
   * C - We released the mouse above an ordinary action:
   *     Execute the action.
   *
   *  In case A, B and C we want the transient menus to be removed
   *  In case A and C we want to remove the menus that were created
   *  during the dragging.
   *
   *  So we should do the following things:
   * 
   * 1 - Stop periodic events,
   * 2 - Determine the action.
   * 3 - Remove the Transient menus from the screen.
   * 4 - Perform the action if there is one.
   */

  [NSEvent stopPeriodicEvents];

  if (grabbed)
    [[self window] _releaseMouse: self];

  //NSLog(@"Finished menu tracking %@", self);

  /*
   * We need to store this, because _highlightedItemIndex
   * will not be valid after we removed this menu from the screen.
   */
  indexOfActionToExecute = _highlightedItemIndex;

  // remove transient menus. --------------------------------------------
    {
      NSMenu *currentMenu = _attachedMenu;

      while (currentMenu && ![currentMenu isTransient])
        {
          currentMenu = [currentMenu attachedMenu];
        }

      while ([currentMenu isTransient] && [currentMenu supermenu])
        {
          currentMenu = [currentMenu supermenu];
        }

      [[currentMenu menuRepresentation] detachSubmenu];

      if ([currentMenu isTransient])
        {
          [currentMenu closeTransient];
        }
    }

  // ---------------------------------------------------------------------
  if (indexOfActionToExecute == -1)
    {
      return YES;
    }

  if (indexOfActionToExecute >= 0
    && [_attachedMenu attachedMenu] != nil && [_attachedMenu attachedMenu] ==
    [[_items_link objectAtIndex: indexOfActionToExecute] submenu])
    {
#if 1
      //if (NSInterfaceStyleForKey(@"NSMenuInterfaceStyle", self)
    //== NSMacintoshInterfaceStyle)
    {
      /*
       * FIXME ... always remove submenus in mac mode ... this is not
       * quite the way the mac behaves, but it's closer than the normal
       * behavior.
       */
          subMenusNeedRemoving = YES;
    }
#endif
      if (subMenusNeedRemoving)
        {
          [self detachSubmenu];
        }
      // Clicked on a submenu.
      return NO;
    }

  //if (NSInterfaceStyleForKey(@"NSMenuInterfaceStyle", self)
  //  == NSMacintoshInterfaceStyle)
    {
      NSMenu    *tmp = _attachedMenu;

      do
    {
      if ([tmp isEqual: [NSApp mainMenu]] == NO)
        {
          [tmp close];
        }
      tmp = [tmp supermenu];
    }
      while (tmp != nil);
    }

  [_attachedMenu performActionForItemAtIndex: indexOfActionToExecute];

  /*
   * Remove highlighting.
   * We first check if it still highlighted because it could be the
   * case that we choose an action in a transient window which
   * has already dissappeared.  
   */
  if (_highlightedItemIndex >= 0)
    {
      [self setHighlightedItemIndex: -1];
    }
  return YES;
}

@end
