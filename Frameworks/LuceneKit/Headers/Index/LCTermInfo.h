#ifndef __LUCENE_INDEX_TERM_INFO__
#define __LUCENE_INDEX_TERM_INFO__

#include <Foundation/Foundation.h>

@interface LCTermInfo: NSObject
{
  int docFreq;
  long freqPointer;
  long proxPointer;
  int skipOffset;
}

- (id) initWithDocFreq: (int) df freqPointer: (long) fq proxPointer: (long) pp;
- (id) initWithTermInfo: (LCTermInfo *) ti;
- (int) docFreq;
- (long) freqPointer;
- (long) proxPointer;
- (int) skipOffset;
- (void) setDocFreq: (int) df freqPointer: (long) fp
            proxPointer: (long) pp skipOffset: (int) so;
- (void) setTermInfo: (LCTermInfo *) ti;
- (void) setDocFreq: (int) doc;
- (void) setFreqPointer: (long) freq;
- (void) setProxPointer: (long) prox;
- (void) setSkipOffset: (int) skip;

@end

#endif /* __LUCENE_INDEX_TERM_INFO__ */
