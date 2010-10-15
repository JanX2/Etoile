/* All Rights reserved */

#include <AppKit/AppKit.h>

@class TWTextView;
@class OgreTextFinder;

@interface TWDocument : NSDocument
{
  NSAttributedString *aString;
  NSScrollView *scrollView;
  TWTextView *textView;
  OgreTextFinder *textFinder;
}

- (void) showFindPanel: (id) sender;

/* This add string straight into document */
- (void) appendString: (NSString *) string;
@end
