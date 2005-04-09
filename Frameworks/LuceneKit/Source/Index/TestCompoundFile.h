#ifndef __LUCENE_INDEX_TEST_COMPOUND_FILE__
#define __LUCENE_INDEX_TEST_COMPOUND_FILE__

#include <Foundation/Foundation.h>
#include <UnitKit/UnitKit.h>
#include "Store/LCDirectory.h"

@interface TestCompoundFile: NSObject <UKTest>
{
  id <LCDirectory> dir;
}

@end

#endif /* __LUCENE_INDEX_TEST_COMPOUND_FILE__ */
