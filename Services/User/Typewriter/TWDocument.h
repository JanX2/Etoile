/* All Rights reserved */

#include <AppKit/AppKit.h>

@class TWTextView;

@interface TWDocument : NSDocument
{
  NSAttributedString *aString;
  NSScrollView *scrollView;
  TWTextView *textView;
}
@end
