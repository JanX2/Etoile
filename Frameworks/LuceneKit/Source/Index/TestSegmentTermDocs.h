#ifndef __LUCENE_INDEX_TEST_SEGMENT_TERM_DOCS__
#define __LUCENE_INDEX_TEST_SEGMENT_TERM_DOCS__

#include <Foundation/Foundation.h>
#include <UnitKit/UnitKit.h>
#include "Store/LCDirectory.h"

@class LCDocument;

@interface TestSegmentTermDocs: NSObject <UKTest>
{
  LCDocument *testDoc;
  id <LCDirectory> dir;
}
@end

#endif /* __LUCENE_INDEX_TEST_SEGMENT_TERM_DOCS__ */
