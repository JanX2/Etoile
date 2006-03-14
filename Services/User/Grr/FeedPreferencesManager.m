/* Guenther Noack, GPL */

#import <AppKit/AppKit.h>
#import "FeedPreferencesManager.h"
#import "FeedSelection.h"

#import <math.h>

NSString* secondsToString ( int intInterval )
{
  NSString* result = @"Error";
  int months;
  int days;
  int hours;
  int minutes;
  
  // Calculate months, days and hours from seconds...
  months = intInterval;
  intInterval %= 2592000;
  months = (months - intInterval)/2592000;
  
  days = intInterval;
  intInterval %= 86400;
  days = (days-intInterval)/86400;
  
  hours = intInterval;
  intInterval %= 3600;
  hours = (hours-intInterval)/3600;
  
  minutes = intInterval / 60;
  
  if (months > 0)
    {
      result = [NSString stringWithFormat: @"%d months, %d days",
			 months, days];
    }
  else if (days > 0)
    {
      result = [NSString stringWithFormat: @"%d days, %d hours",
			 days, hours];
    }
  else if (hours > 0)
    {
      result = [NSString stringWithFormat: @"%d hours, %d minutes",
			 hours, minutes];
    }
  else if (minutes > 0)
    {
      result = [NSString stringWithFormat: @"%d minutes", minutes];
    }
  
  return AUTORELEASE(RETAIN(result));
}



static FeedPreferencesManager* instance = nil;


@implementation FeedPreferencesManager

-(id) init
{
  if (instance != nil)
    {
      [self dealloc];
      return instance;
    }
  
  if (self = [super init])
    {
      instance = self;
    }
  
  NSLog(@"init FPM intern");
  return self;
}

+(FeedPreferencesManager*) instance
{
  if (instance == nil)
    {
      instance = [[FeedPreferencesManager alloc] init];
    }
  
  return instance;
}

- (void) clearFeedUpdated: (id) sender
{
  int state = [clearFeedControl state];
  
  switch (state) {
  case NSOnState:
    [[RSSFeed selectedFeed] setAutoClear: YES];
    break;
    
  case NSOffState:
    [[RSSFeed selectedFeed] setAutoClear: NO];
    break;
  }
}

- (void) selectedFeedUpdated: (RSSFeed*) feed
{
  BOOL enableWidgets;
  double draggerVal;
  
  if (feed == nil ||
      ![feed isSubclassedFeed])
    {
      enableWidgets = NO;
      [prefPanelHeadline setStringValue: @"Feed preferences (no feed selected)"];
    }
  else
    {
      double minVal;
      double maxVal;
      double actualValue;
      
      RSSReaderFeed* rFeed;
      
      rFeed = (RSSReaderFeed*) feed;
      
      enableWidgets = YES;
      
      // Update Slider (Dragger)
      draggerVal = sqrt([rFeed minimumUpdateInterval]);
      
      minVal = [minUpdateIntervalDragger minValue];
      maxVal = [minUpdateIntervalDragger maxValue];
      
      if (draggerVal < minVal)
	{
	  draggerVal = minVal;
	}
      else if (draggerVal > maxVal)
	{
	  draggerVal = maxVal;
	}
      
      [minUpdateIntervalDragger setDoubleValue: draggerVal];
      
      // Update the text belonging to the dragger.
      [minUpdateIntervalText
	setStringValue: secondsToString((int)(draggerVal*draggerVal))];
      
      // Update URL text
      [urlTextField setStringValue: [[rFeed feedURL] description]];
      
      // Update panel headline
      [prefPanelHeadline
	setStringValue:
	  [NSString stringWithFormat: @"Preferences for %@", rFeed] ];
      
      // Update autocleaning
      [clearFeedControl
	setState: [rFeed autoClear] ? NSOnState : NSOffState];
    }
  
  [minUpdateIntervalDragger setEnabled: enableWidgets];
  
  [urlTextField setEnabled: enableWidgets];
  [urlTextField setEditable: enableWidgets];
}

- (void) minUpdateIntervalUpdated: (id)sender
{
  double doubleValue;
  NSTimeInterval interval;
  
  NSString* description;
  int intInterval;
  
  RSSFeed* selectedFeed;
  
  selectedFeed = [RSSFeed selectedFeed];
  
  if (selectedFeed == nil)
    {
      NSLog(@"No feed selected when changing feed URL. "
	    @"This is not supposed to happen.");
      return;
    }
  
  doubleValue = [minUpdateIntervalDragger doubleValue];  
  interval = (NSTimeInterval)(doubleValue*doubleValue);
  
  if ([selectedFeed isSubclassedFeed])
    {
      RSSReaderFeed* feed = (RSSReaderFeed*) selectedFeed;
      [feed setMinimumUpdateInterval: interval];
    }
  else
    {
      NSLog(@"Selected feed was not a subclassed one. "
	    @"This is not supposed to happen.");
      return;
    }
  
  // update date view...
  [minUpdateIntervalText setStringValue: secondsToString((int)interval)];
}


- (void) newFeedURL: (id)sender
{
  RSSFeed* selFeed;
  RSSReaderFeed* feed;
  
  selFeed = [RSSFeed selectedFeed];
  
  if (selFeed == nil)
    {
      NSLog(@"No feed selected when changing feed URL. "
	    @"This is not supposed to happen.");
      return;
    }
  
  if ([selFeed isSubclassedFeed] == NO)
    {
      NSLog(@"Selected feed was not a subclassed one. "
	    @"This is not supposed to happen.");
      return;
    }
  
  feed = (RSSReaderFeed*) selFeed;
  
  if ([feed setURLString: [urlTextField stringValue]] == NO)
    {
      // snap back if it wasn't a URL...
      [urlTextField setStringValue: [[feed feedURL] description]];
    }
}

@end
