
#import <AppKit/AppKit.h>
#import "AZClient+GNUstep.h"
#import "prop.h"
#import "gnustep.h"

@implementation AZClient (GNUstep)

- (BOOL) isGNUstepMenuWindowLevel
{
  if (gnustep_attr.flags & GSWindowLevelAttr) {
    if ((gnustep_attr.window_level == NSMainMenuWindowLevel) || 
        (gnustep_attr.window_level == NSPopUpMenuWindowLevel)) 
    {
      return YES;
    }
  }
  return NO;
}

- (BOOL) isGNUstep
{
  if ([class isEqualToString: @"GNUstep"] == YES)
    return YES;
  else
    return NO;
}

- (void) updateGNUstepWMAttributes
{
  unsigned long *data;
  unsigned int num;
  if (!prop_get_array32(window, prop_atoms.gnustep_wm_attr,
		  prop_atoms.gnustep_wm_attr, (unsigned long **)&data, &num))
    return;

  if (num != 9) {
	    NSLog(@"Internal Error: wrong GNUstep attributes");
	    return;
  }
  gnustep_attr.flags = data[0];
  gnustep_attr.window_style = data[1];
  gnustep_attr.window_level = data[2];
  gnustep_attr.reserved = data[3];
  gnustep_attr.miniaturize_pixmap = data[4];
  gnustep_attr.close_pixmap = data[5];
  gnustep_attr.miniaturize_mask = data[6];
  gnustep_attr.close_mask = data[7];
  gnustep_attr.extra_flags = data[8];

  XFree(data);

  return;

#if 0
  NSMutableString *ms = [[NSMutableString alloc] init];
  if (attr.flags & GSWindowLevelAttr) {
      [ms appendFormat: @"(level %d) ", attr.window_level];
  }

  if (attr.flags & GSExtraFlagsAttr) {
      if (attr.extra_flags & GSDocumentEditedFlag)
	[ms appendString: @"\"Edited\""];
  }
  NSLog(@"%@", ms);
  DESTROY(ms);
#endif

  /* Override the decoration */
  if (gnustep_attr.flags & GSWindowStyleAttr) {

      functions = 0;
      decorations = OB_FRAME_DECOR_ICON;

      if (!(gnustep_attr.window_style & NSBorderlessWindowMask)) {
	decorations |= OB_FRAME_DECOR_BORDER;
      }
      if (gnustep_attr.window_style & NSTitledWindowMask) {
	decorations |= OB_FRAME_DECOR_TITLEBAR |
		       OB_FRAME_DECOR_SHADE;
	functions |= OB_CLIENT_FUNC_MOVE |
	       	     OB_CLIENT_FUNC_SHADE;
      }
      if (gnustep_attr.window_style & NSClosableWindowMask) {
	decorations |= OB_FRAME_DECOR_CLOSE;
	functions |= OB_CLIENT_FUNC_CLOSE;
      }
      if (gnustep_attr.window_style & NSMiniaturizableWindowMask) {
	decorations |= OB_FRAME_DECOR_ICONIFY;
	functions |= OB_CLIENT_FUNC_ICONIFY;
      }
      if (gnustep_attr.window_style & NSResizableWindowMask) {
	decorations |= OB_FRAME_DECOR_HANDLE |
		       OB_FRAME_DECOR_GRIPS |
		       OB_FRAME_DECOR_MAXIMIZE;
	functions |= OB_CLIENT_FUNC_RESIZE |
		     OB_CLIENT_FUNC_MAXIMIZE;
      }

#if 0
      [self changeAllowedActions];

      if (frame) {
        /* adjust the client's decorations, etc. */
        [self reconfigure];
      }
#endif
  }
}

@end
