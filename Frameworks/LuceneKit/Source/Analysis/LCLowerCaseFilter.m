#include "LuceneKit/Analysis/LCLowerCaseFilter.h"

/**
 * Normalizes token text to lower case.
 *
 * @version $Id$
 */
@implementation LCLowerCaseFilter

- (LCToken *) next
{
  LCToken *t = [input next];

  if (t == nil)
    return nil;

  NSString *s = [[t termText] lowercaseString];
  [t setTermText: s];

  return t;
}

@end
