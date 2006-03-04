
#import "GSTitleView+Hackery.h"

@implementation GSTitleView (EtoileMenusHackery)

+ (float) height
{
  static float height = 0.0;

  if (height == 0.0)
    {
      NSFont *font = [NSFont boldSystemFontOfSize: [NSFont smallSystemFontSize]];

      /* Minimum title height is 16 */
      height = ([font boundingRectForFont].size.height) + 4;
      if (height < 16)
        {
          height = 16;
        }

      NSLog(@"computed: %f", height);
    }

  return height;
}

@end
