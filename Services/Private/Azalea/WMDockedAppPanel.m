#include "WMDockedAppPanel.h"

static WMDockedAppPanel *sharedInstance;

@interface WMDockedAppPanel (WMPrivate)
- (void) createInterface;
@end

@implementation WMDockedAppPanel

+ (WMDockedAppPanel *) sharedPanel
{
  if (sharedInstance == nil)
  {
    sharedInstance = [[WMDockedAppPanel alloc] init];
  }
  return sharedInstance;
}

- (id) init
{
  [self createInterface];

  return self;
}

- (void) dealloc
{
  [super dealloc];
}

- (void) createInterface
{
  NSRect rect;
  NSSize size;
  size = NSMakeSize(600, 250);
  rect = NSMakeRect(300, 100, size.width, size.height);

  self = [super initWithContentRect: rect
	                  styleMask: (NSTitledWindowMask | NSClosableWindowMask)
			  backing: NSBackingStoreBuffered
			  defer: YES];
  [self setTitle: @"Docked Application Settings"];
  [self setHidesOnDeactivate: NO];

#if 0
  /* apply button */
  rect = NSMakeRect(NSMaxX(rect)+10, 10, 60, button_height);
  applyButton = [[NSButton alloc] initWithFrame: rect];
  [applyButton setStringValue: @"Apply"];
  [applyButton setTarget: self];
  [applyButton setAction: @selector(applyButtonAction:)];
  [[self contentView] addSubview: applyButton];

  /* save button */
  rect = NSMakeRect(NSMaxX(rect)+10, 10, 60, button_height);
  saveButton = [[NSButton alloc] initWithFrame: rect];
  [saveButton setStringValue: @"Save"];
  [saveButton setTarget: self];
  [saveButton setAction: @selector(saveButtonAction:)];
  [[self contentView] addSubview: saveButton];
#endif

  [self setDelegate: self];
}

/** delegate */
- (void) windowWillClose: (NSNotification *) not
{
//  [self setWindow: NULL];
}

@end

