#ifndef __LUCENE_INDEX_TEST_MOCK_INDEX_OUTPUT__
#define __LUCENE_INDEX_TEST_MOCK_INDEX_OUTPUT__

#include "Store/LCIndexOutput.h"
#include <UnitKit/UnitKit.h>

@interface TestMockIndexOutput: LCIndexOutput <UKTest>
{
  NSMutableData *data;
  unsigned long long pointer;
}
@end

#endif /* __LUCENE_INDEX_TEST_MOCK_INDEX_OUTPUT__ */
