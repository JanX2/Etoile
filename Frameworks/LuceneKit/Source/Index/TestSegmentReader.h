#ifndef __LUCENE_INDEX_TEST_SEGMENT_READER__
#define __LUCENE_INDEX_TEST_SEGMENT_READER__

#include <Foundation/Foundation.h>
#include <UnitKit/UnitKit.h>
#include "Index/LCSegmentReader.h"
#include "Document/LCDocument.h"
#include "Store/LCRAMDirectory.h"
#include "TestDocHelper.h"

@interface TestSegmentReader: NSObject <UKTest>
{
  LCRAMDirectory *dir;
  LCDocument *testDoc;
  LCSegmentReader *reader;
}
@end

#endif /* __LUCENE_INDEX_TEST_SEGMENT_READER__ */
