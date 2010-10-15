/* All Rights reserved */

#include <AppKit/AppKit.h>

@class TWTextView;
@class OgreTextFinder;
@class IDESyntaxHighlighter;

@interface TWDocument : NSDocument
{
  NSAttributedString *aString;
  NSScrollView *scrollView;
  TWTextView *textView;
  OgreTextFinder *textFinder;
  IDESyntaxHighlighter *highlighter;
}

- (void) showFindPanel: (id) sender;

/* This add string straight into document */
- (void) appendString: (NSString *) string;
@end
