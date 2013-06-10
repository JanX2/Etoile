/*
    ClockMenulet.m

    Implementation of the ClockMenulet class for the EtoileMenuServer
    application.

    Copyright (C) 2005, 2006  Saso Kiselkov

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import "ClockMenulet.h"
#import "CalendarView.h"

#import <AppKit/NSButton.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSWindow.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSInvocation.h>
#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSCalendar.h>
#import <Foundation/NSDateFormatter.h>

@implementation ClockMenulet

- (void) buttonAction: (id) sender
{
  if (calendarWindow == nil) {
    CalendarView *cView = [[CalendarView alloc] initWithFrame: NSZeroRect];
    [cView setDate: [NSCalendarDate calendarDate]];

    /* Try to get right position */
    int w = [CalendarView size].width;
    int h = [CalendarView size].height;
    int y = NSMinY([[view window] frame])-h;
//    int x = NSMinX([view frame]);
    int x = NSMinX([view frame]) + NSMinX([[view window] frame]);
    /* Make sure the window is inside the screen */
    x = (x+w > NSMaxX([[view window] frame])) ? NSMaxX([[view window] frame])-w : x;
    NSRect rect = NSMakeRect(x, y, w, h);
    calendarWindow = [[NSWindow alloc] initWithContentRect: rect
                                      styleMask: NSBorderlessWindowMask
                                        backing: NSBackingStoreRetained
                                          defer: NO];
    [calendarWindow setContentView: cView];
    DESTROY(cView);
  }
  if ([calendarWindow isVisible]) {
    [calendarWindow orderOut: self];
  } else {
    [calendarWindow makeKeyAndOrderFront: self];
  }
}

- (void) dealloc
{
  [timer invalidate];
  [gregorian release];
  [dateFormatter release];
  [shortDayName release];
  TEST_RELEASE(view);
  DESTROY(calendarWindow);

  [super dealloc];
}

- (id) init
{
  if ((self = [super init]) != nil)
    {
      NSInvocation * inv;
      NSFont * font = [NSFont systemFontOfSize: 0];

      view = [[NSButton alloc] initWithFrame:
        NSMakeRect(0, 0, [font widthOfString: @"Mon XX:XX PM"] + 5, 20)];

      [view setFont: font];
      [view setBordered: NO];
      [view setTarget: self];
      [view setAction: @selector(buttonAction:)];

      inv = [NSInvocation invocationWithMethodSignature: [self
        methodSignatureForSelector: @selector(updateClock)]];
      [inv setTarget: self];
      [inv setSelector: @selector(updateClock)];
      timer = [NSTimer scheduledTimerWithTimeInterval: 1.0
                                           invocation: inv
                                              repeats: YES];
      gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
      dateFormatter = [[NSDateFormatter alloc] init];
      [dateFormatter setDateFormat:@"dd/MM/yyyy HH:mm"];
      shortDayName = [[dateFormatter shortWeekdaySymbols] retain];
      [self updateClock];
    }

  return self;
}

- (void) updateClock
{
  NSDate * date = [NSDate date];
  NSDateComponents *dateComponents = [gregorian components:NSWeekdayCalendarUnit fromDate:date];
  
  NSInteger weekDayNum = [dateComponents weekday];
  NSString *strDate = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle];
  NSString *dayNum =  [dateFormatter stringFromDate:date];
  [view setTitle: [NSString stringWithFormat:@"%@ %@ %@", [shortDayName objectAtIndex:weekDayNum], [dayNum substringToIndex:2], strDate]];
}

- (NSView *) menuletView
{
  return (NSView *)view;
}

@end
