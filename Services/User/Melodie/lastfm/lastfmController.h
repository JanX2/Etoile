/* All Rights reserved */

#include <AppKit/AppKit.h>

@interface lastfmController : NSObject
{
  id album;
  id artist;
  id image;
}
- (void) get: (id)sender;
@end
