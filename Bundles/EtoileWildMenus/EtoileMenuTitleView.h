
#import <GNUstepGUI/GSTitleView.h>

@interface EtoileMenuTitleView : GSTitleView
{
  float fontHeight;
  BOOL titleVisible;

  NSDictionary * titleDrawingAttributes;
}

- (BOOL) isTitleVisible;
- (void) setTitleVisible: (BOOL)visible;

@end
