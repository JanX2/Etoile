
#import <AppKit/AppKit.h>
#import "AZClient+GNUstep.h"
#import "prop.h"
#import "gnustep.h"

@implementation AZClient (GNUstep)

- (BOOL) isGNUstep
{
  unsigned int data = 0;
  if (PROP_GET32(window, gnustep_wm_attr, gnustep_wm_attr, &data))
    return YES;
  return NO;
}

- (void) updateGNUstepWMAttributes
{
  unsigned long *data;
  unsigned int num;
  GNUstepWMAttributes attr;
  if (!prop_get_array32(window, prop_atoms.gnustep_wm_attr,
		  prop_atoms.gnustep_wm_attr, (unsigned int **)&data, &num))
    return;

  if (num != 9) {
	    NSLog(@"Internal Error: wrong GNUstep attributes");
	    return;
  }
  attr.flags = data[0];
  attr.window_style = data[1];
  attr.window_level = data[2];
  attr.reserved = data[3];
  attr.miniaturize_pixmap = data[4];
  attr.close_pixmap = data[5];
  attr.miniaturize_mask = data[6];
  attr.close_mask = data[7];
  attr.extra_flags = data[8];

  XFree(data);

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
  if (attr.flags & GSWindowStyleAttr) {

      functions = 0;
      decorations = OB_FRAME_DECOR_ICON;

      if (!(attr.window_style & NSBorderlessWindowMask)) {
	decorations |= OB_FRAME_DECOR_BORDER;
      }
      if (attr.window_style & NSTitledWindowMask) {
	decorations |= OB_FRAME_DECOR_TITLEBAR |
		       OB_FRAME_DECOR_SHADE;
	functions |= OB_CLIENT_FUNC_MOVE |
	       	     OB_CLIENT_FUNC_SHADE;
      }
      if (attr.window_style & NSClosableWindowMask) {
	decorations |= OB_FRAME_DECOR_CLOSE;
	functions |= OB_CLIENT_FUNC_CLOSE;
      }
      if (attr.window_style & NSMiniaturizableWindowMask) {
	decorations |= OB_FRAME_DECOR_ICONIFY;
	functions |= OB_CLIENT_FUNC_ICONIFY;
      }
      if (attr.window_style & NSResizableWindowMask) {
	decorations |= OB_FRAME_DECOR_HANDLE |
		       OB_FRAME_DECOR_GRIPS |
		       OB_FRAME_DECOR_MAXIMIZE;
	functions |= OB_CLIENT_FUNC_RESIZE |
		     OB_CLIENT_FUNC_MAXIMIZE;
      }

#if 0 /* For some reason, decorations is correct without reconfigure */
      [self changeAllowedActions];

      if (frame) {
        /* adjust the client's decorations, etc. */
        [self reconfigure];
      }
#endif
  }
}

@end
