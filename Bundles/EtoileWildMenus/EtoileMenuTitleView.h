#import <GNUstepGUI/GSTitleView.h>
#import <GNUstepGUI/GSTheme.h>

@interface EtoileMenuTitleView : GSTitleView
{
  float fontHeight;
  BOOL titleVisible;

  NSDictionary * titleDrawingAttributes;
}

- (BOOL) isTitleVisible;
- (void) setTitleVisible: (BOOL)visible;

@end

// TODO: Move to Nesedah and Narcissus themes probably
@interface GSTheme (GSTitleView)
- (Class) titleViewClassForMenuView: (NSMenuView *)aMenuView;
@end
