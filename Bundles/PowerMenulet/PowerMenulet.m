#import "PowerMenulet.h"

@implementation PowerMenulet
- (void) checkPower: (NSTimer *) t
{
  /* Check /proc/apm (For Linux with APM) */
  if ([fm fileExistsAtPath: @"/proc/apm"])
  {
    NSString *apm = [NSString stringWithContentsOfFile: @"/proc/apm"];
    NSArray *array = [apm componentsSeparatedByString: @" "];
    /* This is what I gather:
       0: Driver-version, string
       1: BIOS-version, string
       2: APM flag, 0x01: bit16
                    0x02: bits32
                    0x04: idle-slows-clock
                    0x10: disabled
                    0x20: disengaged
       3: AC line status, 0x00: off
                          0x01: on
                          0x02: backup
                          0xff: unknown (#f)
       4: Battery status, 0x00: high
                          0x01: low
                          0x02: critical
                          0x03: charging
                          0x04: absent
                          0xff: unknown (#f)
       5: Battery flag, 0x01: high
                        0x02: low
                        0x04: critical
                        0x08: charging
                        0x80: absent
       6: Battery percent, could be '0x??', '??%'
       7: Battery time, number
       8: Battery time unit, string
    */
    if ([[array objectAtIndex: 3] isEqualToString: @"0x01"])
    {
      /* We are charging */
      [view setTitle: @"AC line"];
      return;
    }
    else if ([[array objectAtIndex: 3] isEqualToString: @"0x00"])
    {
      /* We are not on power */
      if ([[array objectAtIndex: 6] hasSuffix: @"\%"])
      {
        /* We are in format of '56%', luckly !! */
        [view setTitle: [array objectAtIndex: 6]];
        return;
      }
    }
  }
  /* Unknown */
  [view setTitle: @"Power Unknwon"];
}

- (void) dealloc
{
  if (timer)
  {
    [timer invalidate];
    DESTROY(timer);
  }
  DESTROY(view);
  [super dealloc];
}

- (id) init
{
  NSRect rect = NSZeroRect;

  self = [super init];

  rect.size.height = 22;
  rect.size.width = 50;
  view = [[NSButton alloc] initWithFrame: rect];
  [view setBordered: NO];
  [view setTitle: @"Power ?"];

  fm = [NSFileManager defaultManager];

  /* Start timer for every 5 seconds */
  ASSIGN(timer, [NSTimer scheduledTimerWithTimeInterval: 5
                         target: self
                         selector: @selector(checkPower:)
                         userInfo: nil
                         repeats: YES]);
  [self checkPower: timer];

  return self;
}

- (NSView *) menuletView
{
  return (NSView *)view;
}

@end
