/* All Rights reserved */

#include <AppKit/AppKit.h>

@class OgreTextFinder;

@interface Delegate : NSObject
{
  id scrollView;
  id textView;

  OgreTextFinder *textFinder;
}
- (void) findPanelAction: (id)sender;
@end
