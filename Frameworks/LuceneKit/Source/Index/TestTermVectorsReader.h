#ifndef __LUCENE_INDEX_TEST_TERM_VECTORS_READER__
#define __LUCENE_INDEX_TEST_TERM_VECTORS_READER__

#include <Foundation/Foundation.h>
#include <UnitKit/UnitKit.h>

@class LCTermVectorsWriter;
@class LCRAMDirectory;
@class LCFieldInfos;

@interface TestTermVectorsReader: NSObject <UKTest>
{
  LCTermVectorsWriter *writer;
  //Must be lexicographically sorted, will do in setup, versus trying to maintain here
  NSArray *testFields;
  NSArray *testFieldsStorePos;
  NSArray *testFieldsStoreOff;
  NSArray *testTerms;
  NSMutableArray *positions;
  NSMutableArray *offsets;
  LCRAMDirectory *dir;
  NSString *seg;
  LCFieldInfos *fieldInfos;
}
@end

#endif /* __LUCENE_INDEX_TEST_TERM_VECTORS_READER__ */
