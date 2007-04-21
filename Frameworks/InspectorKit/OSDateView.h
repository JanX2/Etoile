
#import <AppKit/NSView.h>

@class NSTextField, NSCalendarDate;

/** @class OSDateView
    @brief This class is a classic NeXT-style clock.


    This class represents a classic NeXT-style clock as we know it
    from the Preferences app.
    
    Date views use one value in the defaults database (which they
    watch for changes if configured to do so): "OSDateViewShows12HourFormat".
    If this key is set to "YES", then they display 12-hour AM/PM format.
    Otherwise they display 24-hour format time.

 @author Saso Kiselkov
*/
@interface OSDateView : NSView
{
         /// The text field used to display the year.
        NSTextField * yearField;

        BOOL showsYear;
        BOOL shows12HourFormat;
        BOOL showsLEDColon;
        BOOL tracksDefaults;

         /// The currently displayed date.
        NSCalendarDate * date;

         /// An array of images containing the date numbers.
        NSArray * dates;
         /// The mask of the clock.
        NSImage * tile;
         /// An array of images containing the LED digits.
        NSArray * leds;
        NSImage * ledColon,
                * ledAM,
                * ledPM;
         /// An array of images containing the month names.
        NSArray * months;
         /// An array of images containing the weekday names.
        NSArray * weekdays;
}

 /** @brief The designated initializer for OSDateView objects.

   Initializes the receiver to a default size of 55x57 points. */
- init;

 /// Sizes the receiver to fit it's contents.
- (void) sizeToFit;

 /** Sets whether the receiver displays the year information in a small
     text field at it's bottom. */
- (void) setShowsYear: (BOOL) flag;
 /// Returns YES if the receiver shows the year, and NO otherwise.
- (BOOL) showsYear;

 /** Sets whether the receiver is to display 12-hour AM/PM format or full
     24-hour format. */
- (void) setShows12HourFormat: (BOOL) flag;
 /** Returns YES if the receiver displays 12-hour AM/PM format,
     and NO otherwise. */
- (BOOL) shows12HourFormat;

 /** Sets whether the receiver is to display a colon between the hour
     and minute fields. */
- (void) setShowsLEDColon: (BOOL) flag;
 /** Returns YES when the receiver displays a colon between the hour
     and minute fields. */
- (BOOL) showsLEDColon;

 /// Sets the calendar date the receiver is to display.
- (void) setCalendarDate: (NSCalendarDate *) aDate;
 /// Returns the calendar date displayed by the receiver.
- (NSCalendarDate *) calendarDate;

 /** Sets whether the receiver is tracking the defaults database for
     defaults changes about the receiver's appearance. */
- (void) setTracksDefaultsDatabase: (BOOL) flag;
 /** Returns YES if the receiver is tracking the defaults database,
     and NO otherwise. */
- (BOOL) tracksDefaultsDatabase;

@end
