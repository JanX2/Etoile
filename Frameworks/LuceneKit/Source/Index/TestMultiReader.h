#ifndef __LUCENE_INDEX_TEST_MULTI_READER__
#define __LUCENE_INDEX_TEST_MULTI_READER__

#include <Foundation/Foundation.h>
#include <UnitKit/UnitKit.h>
#include "Store/LCDirectory.h"

@class LCDocument;
@class LCSegmentReader;
@class LCSegmentInfos;

@interface TestMultiReader: NSObject <UKTest>
{
  id <LCDirectory> dir;
  LCDocument *doc1;
  LCDocument *doc2;
  LCSegmentReader *reader1;
  LCSegmentReader *reader2;
  NSMutableArray *readers;
  LCSegmentInfos *sis;
}

@end
  
#endif /* __LUCENE_INDEX_TEST_MULTI_READER__ */
