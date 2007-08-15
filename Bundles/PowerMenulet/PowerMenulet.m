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
			[view setImagePosition: NSImageOnly];
			if ([[array objectAtIndex: 4] isEqualToString: @"0x03"])
			{
				/* We are charging */
				[view setImage: p4];
			}
			else
			{
				/* Full ? */
				[view setImage: p5];
			}
			return;
		}
		else if ([[array objectAtIndex: 3] isEqualToString: @"0x00"])
		{
			/* We are not on power */
			NSString *s = [array objectAtIndex: 6];
			if ([s hasSuffix: @"\%"])
			{
				/* We are in format of '56%', luckly !! */
				s = [s substringToIndex: [s length]-1];
				int percent = [s intValue];
//NSLog(@"Power Level: %d\%", percent);
				[view setImagePosition: NSImageOnly];
				if (percent > 75)
				{
					[view setImage: p3];
				}
				else if (percent > 50)
				{
					[view setImage: p2];
				}
				else if (percent > 25)
				{
					[view setImage: p1];
				}
				else if (percent > 0)
				{
					[view setImage: p0];
				}
				else
				{
					/* If percent is 0, the computer dies.
					   So it is probably due to the failure of 
					   parsing power level.
					 */
					[view setTitle: @"Power Unknwon"];
					[view setImagePosition: NSNoImage];
				}
				return;
			}
		}
	}
	/* Unknown */
	[view setTitle: @"??"];
	[view setImagePosition: NSNoImage];
}

- (void) dealloc
{
	if (timer)
	{
		[timer invalidate];
		DESTROY(timer);
	}
	DESTROY(p0);
	DESTROY(p1);
	DESTROY(p2);
	DESTROY(p3);
	DESTROY(view);
	[super dealloc];
}

- (id) init
{
	NSRect rect = NSZeroRect;

	self = [super init];

	rect.size.height = 22;
	rect.size.width = 29;
	view = [[NSButton alloc] initWithFrame: rect];
	[view setBordered: NO];
	[view setTitle: @"Power ?"];

	fm = [NSFileManager defaultManager];

    /* Cache image */
    NSBundle *bundle = [NSBundle bundleForClass: [self class]];
    NSString *path = nil;
    path = [bundle pathForResource: @"Power_0" ofType: @"tiff"];
    if (path)
        p0 = [[NSImage alloc] initWithContentsOfFile: path];
    path = [bundle pathForResource: @"Power_1" ofType: @"tiff"];
    if (path)
        p1 = [[NSImage alloc] initWithContentsOfFile: path];
    path = [bundle pathForResource: @"Power_2" ofType: @"tiff"];
    if (path)
        p2 = [[NSImage alloc] initWithContentsOfFile: path];
    path = [bundle pathForResource: @"Power_3" ofType: @"tiff"];
    if (path)
        p3 = [[NSImage alloc] initWithContentsOfFile: path];
    path = [bundle pathForResource: @"Power_4" ofType: @"tiff"];
    if (path)
        p4 = [[NSImage alloc] initWithContentsOfFile: path];
    path = [bundle pathForResource: @"Power_5" ofType: @"tiff"];
    if (path)
        p5 = [[NSImage alloc] initWithContentsOfFile: path];

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
