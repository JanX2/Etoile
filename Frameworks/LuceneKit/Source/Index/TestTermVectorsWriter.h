#ifndef __LUCENE_INDEX_TEST_TERM_VECTORS_WRITER__
#define __LUCENE_INDEX_TEST_TERM_VECTORS_WRITER__

#include <Foundation/Foundation.h>
#include <Unitkit/UnitKit.h>

@class LCRAMDirectory;
@class LCFieldInfos;

@interface TestTermVectorsWriter: NSObject <UKTest>
{
  NSArray *testTerms;
  NSArray *testFields;
  NSMutableArray *positions;
  LCRAMDirectory *dir;
  NSString *seg;
  LCFieldInfos *fieldInfos;
}

@end
#endif /* __LUCENE_INDEX_TEST_TERM_VECTORS_WRITER__ */
