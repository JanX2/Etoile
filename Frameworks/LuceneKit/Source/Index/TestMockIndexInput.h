#ifndef __LUCENE_INDEX_TEST_MOCK_INDEX_INPUT__
#define __LUCENE_INDEX_TEST_MOCK_INDEX_INPUT__

#include "LuceneKit/Store/LCIndexInput.h"
#include <UnitKit/UnitKit.h>

@interface TestMockIndexInput: LCIndexInput <UKTest>
{
  NSData *data;
  unsigned long long pointer;
}
- (id) initWithData: (NSData *) data;
@end

#endif /* __LUCENE_INDEX_TEST_MOCK_INDEX_INPUT__ */
