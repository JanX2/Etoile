#ifndef __LUCENE_INDEX_FIELDS_READER__
#define __LUCENE_INDEX_FIELDS_READER__

#include <Foundation/Foundation.h>
#include "LuceneKit/Store/LCDirectory.h"

@class LCFieldInfos;
@class LCIndexInput;
@class LCDocument;

@interface LCFieldsReader: NSObject
{
  LCFieldInfos *fieldInfos;
  LCIndexInput *fieldsStream;
  LCIndexInput *indexStream;
  int size;
}

- (id) initWithDirectory: (id <LCDirectory>) d
                  segment: (NSString *) segment
              fieldInfos: (LCFieldInfos *) fn;
- (void) close;
- (int) size;
- (LCDocument *) doc: (int) n;

@end

#endif /* __LUCENE_INDEX_FIELDS_READER__ */
