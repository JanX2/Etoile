
#import "OSDateView.h"

#import <AppKit/AppKit.h>

@interface OSDateView (Private)

- (void) loadImages;

@end

@implementation OSDateView (Private)

- (void) loadImages
{
        NSBundle * bundle;
        NSMutableArray * array;
        unsigned int i;

        bundle = [NSBundle bundleForClass: [self class]];

        array = [NSMutableArray arrayWithCapacity: 10];
        for (i=0; i<10; i++)
                [array addObject: [[[NSImage alloc]
                  initByReferencingFile: [bundle pathForResource: [NSString
                  stringWithFormat: @"OSDate-%d", i]
                                                          ofType: @"tiff"]]
                  autorelease]];
        dates = [array copy];

        array = [NSMutableArray arrayWithCapacity: 10];
        for (i=0; i<10; i++)
                [array addObject: [[[NSImage alloc]
                  initByReferencingFile: [bundle pathForResource: [NSString
                  stringWithFormat: @"OSLED-%d", i]
                                                          ofType: @"tiff"]]
                  autorelease]];
        leds = [array copy];

        tile = [[NSImage alloc]
          initByReferencingFile: [bundle pathForResource: @"OSDateViewTile"
                                                  ofType: @"tiff"]];

        ledColon = [[NSImage alloc]
          initByReferencingFile: [bundle pathForResource: @"OSLED-Colon"
                                                  ofType: @"tiff"]];
        ledAM = [[NSImage alloc]
          initByReferencingFile: [bundle pathForResource: @"OSLED-AM"
                                                  ofType: @"tiff"]];
        ledPM = [[NSImage alloc]
          initByReferencingFile: [bundle pathForResource: @"OSLED-PM"
                                                  ofType: @"tiff"]];

        array = [NSMutableArray arrayWithCapacity: 12];
        for (i=1; i<=12; i++)
                [array addObject: [[[NSImage alloc]
                  initByReferencingFile: [bundle pathForResource: [NSString
                  stringWithFormat: @"OSMonth-%d", i]
                                                          ofType: @"tiff"]]
                  autorelease]];
        months = [array copy];

        array = [NSMutableArray arrayWithCapacity: 7];
        for (i=0; i<7; i++)
                [array addObject: [[[NSImage alloc]
                  initByReferencingFile: [bundle pathForResource: [NSString
                  stringWithFormat: @"OSWeekday-%d", i]
                                                          ofType: @"tiff"]]
                  autorelease]];
        weekdays = [array copy];
}

@end

@implementation OSDateView

- (void) dealloc
{
        [[NSNotificationCenter defaultCenter] removeObserver: self];

        TEST_RELEASE(yearField);
        TEST_RELEASE(date);

        TEST_RELEASE(dates);

        TEST_RELEASE(tile);

        TEST_RELEASE(leds);
        TEST_RELEASE(ledColon);
        TEST_RELEASE(ledAM);
        TEST_RELEASE(ledPM);

        TEST_RELEASE(months);
        TEST_RELEASE(weekdays);

        [super dealloc];
}

- initWithFrame: (NSRect) r
{
        showsLEDColon = YES;
        shows12HourFormat = [[NSUserDefaults standardUserDefaults]
          boolForKey: @"OSDateViewShows12HourFormat"];

        [self loadImages];

        [self setTracksDefaultsDatabase: YES];


        return [super initWithFrame: r];
}

- init
{
        return [self initWithFrame: NSMakeRect(0, 0, 55, 57)];
}

- (void) sizeToFit
{
        NSRect myFrame = [self frame];

        if (showsYear)
                myFrame.size.height = 70;
        else
                myFrame.size.height = 57;

        myFrame.size.width = 55;

        [self setFrame: myFrame];
}

- (void) drawRect: (NSRect) r
{
        float offset;
        float hoffset;
        int dayOfMonth;
        int hourOfDay;
        int minuteOfHour;
        BOOL morning = NO;

        if (showsYear)
                offset = 13;
        else
                offset = 0;

        [tile compositeToPoint: NSMakePoint(0, offset)
                     operation: NSCompositeSourceOver];

        if (date == nil)
                return;

        [[weekdays objectAtIndex: [date dayOfWeek]]
          compositeToPoint: NSMakePoint(17, offset + 30)
                 operation: NSCompositeSourceOver];
        [[months objectAtIndex: [date monthOfYear]-1]
          compositeToPoint: NSMakePoint(15, offset + 6)
                 operation: NSCompositeSourceOver];

        dayOfMonth = [date dayOfMonth];
        if (dayOfMonth > 9) {
                [[dates objectAtIndex: (dayOfMonth - (dayOfMonth % 10)) / 10]
                  compositeToPoint: NSMakePoint(17, 14 + offset)
                         operation: NSCompositeSourceOver];

                [[dates objectAtIndex: dayOfMonth % 10]
                  compositeToPoint: NSMakePoint(27, 14 + offset)
                         operation: NSCompositeSourceOver];
        } else {
                [[dates objectAtIndex: dayOfMonth]
                  compositeToPoint: NSMakePoint(23, 14 + offset)
                         operation: NSCompositeSourceOver];
        }

        hourOfDay = [date hourOfDay];
        minuteOfHour = [date minuteOfHour];

        if (shows12HourFormat) {
                if (hourOfDay == 0) {
                        hourOfDay = 12;
                        morning = YES;
                } else if (hourOfDay < 12) {
                        morning = YES;
                } else {
                        if (hourOfDay > 12)
                                hourOfDay -= 12;
                        morning = NO;
                }

                hoffset = 0;
        } else
                hoffset = 7;

        if (hourOfDay > 9) {
                [[leds objectAtIndex: (hourOfDay - (hourOfDay % 10)) / 10]
                  compositeToPoint: NSMakePoint(hoffset, 43 + offset)
                         operation: NSCompositeSourceOver];
                hoffset += 8;
        } else
                hoffset += 5;

        [[leds objectAtIndex: hourOfDay % 10]
          compositeToPoint: NSMakePoint(hoffset, 43 + offset)
                 operation: NSCompositeSourceOver];
        hoffset += 10;

        if (showsLEDColon)
                [ledColon compositeToPoint: NSMakePoint(hoffset, 43 + offset)
                                 operation: NSCompositeSourceOver];
        hoffset += 4;

        [[leds objectAtIndex: (minuteOfHour - (minuteOfHour % 10)) / 10]
          compositeToPoint: NSMakePoint(hoffset, 43 + offset)
                 operation: NSCompositeSourceOver];
        hoffset += 9;
        [[leds objectAtIndex: minuteOfHour % 10]
          compositeToPoint: NSMakePoint(hoffset, 43 + offset)
                 operation: NSCompositeSourceOver];

        if (shows12HourFormat) {
                if (morning)
                        [ledAM compositeToPoint: NSMakePoint(40, 48 + offset)
                                      operation: NSCompositeSourceOver];
                else
                        [ledPM compositeToPoint: NSMakePoint(40, 43 + offset)
                                      operation: NSCompositeSourceOver];
        }
}

- (void) setShowsYear: (BOOL) flag
{
        if (showsYear == NO && flag == YES) {
                if (yearField == nil) {
                        yearField = [[NSTextField alloc]
                          initWithFrame: NSMakeRect(0, 0, 55, 12)];
                        [yearField setFont: [NSFont systemFontOfSize: [NSFont
                          smallSystemFontSize]]];
                        [yearField setEditable: NO];
                        [yearField setSelectable: NO];
                        [yearField setBordered: NO];
                        [yearField setBezeled: NO];
                        [yearField setDrawsBackground: NO];
                        [yearField setAlignment: NSCenterTextAlignment];
                }

                if (date != nil)
                        [yearField setIntValue: [date yearOfCommonEra]];
                else
                        [yearField setStringValue: nil];

                [self addSubview: yearField];
        } else if (showsYear == YES && flag == NO) {
                [yearField removeFromSuperview];
        }
        showsYear = flag;
}

- (BOOL) showsYear
{
        return showsYear;
}

- (void) setShows12HourFormat: (BOOL) flag
{
        if (shows12HourFormat != flag) {
                shows12HourFormat = flag;
                [self setNeedsDisplay: YES];
        }
}

- (BOOL) shows12HourFormat
{
        return shows12HourFormat;
}

- (void) setShowsLEDColon: (BOOL) flag
{
        if (showsLEDColon != flag) {
                showsLEDColon = flag;
                [self setNeedsDisplay: YES];
        }
}

- (BOOL) showsLEDColon
{
        return showsLEDColon;
}

- (void) setCalendarDate: (NSCalendarDate *) aDate
{
        ASSIGN(date, aDate);

        if (yearField != nil)
                [yearField setIntValue: [date yearOfCommonEra]];

        [self setNeedsDisplay: YES];
}

- (NSCalendarDate *) calendarDate
{
        return date;
}

- (void) setTracksDefaultsDatabase: (BOOL) flag
{
        if (flag != tracksDefaults) {
                NSNotificationCenter * nc = [NSNotificationCenter
                  defaultCenter];

                if (flag == YES)
                        [nc addObserver: self
                               selector: @selector(defaultsChanged:)
                                   name: NSUserDefaultsDidChangeNotification
                                 object: [NSUserDefaults standardUserDefaults]];
                else
                        [nc removeObserver: self];
        }
}

- (BOOL) tracksDefaultsDatabase
{
        return tracksDefaults;
}

- (void) defaultsChanged: (NSNotification *) notif
{
        BOOL flag;

        flag = [[NSUserDefaults standardUserDefaults]
          boolForKey: @"OSDateViewShows12HourFormat"];

        if (flag != shows12HourFormat) {
                shows12HourFormat = flag;
                [self setNeedsDisplay: YES];
        }
}

@end
