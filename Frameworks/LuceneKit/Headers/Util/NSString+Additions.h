#ifndef __LUCENE_UTIL_STRING_HELPER__
#define __LUCENE_UTIL_STRING_HELPER__

#include <Foundation/NSString.h>

@interface NSString (LuceneKit_Util)
- (int) positionOfDifference: (NSString *) other;
@end

#endif /* __LUCENE_UTIL_STRING_HELPER__ */
