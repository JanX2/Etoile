#include "LuceneKit/Index/LCTermInfo.h"

/** A TermInfo is the record of information stored for a term.*/
@implementation LCTermInfo

- (id) init
{
  self = [super init];
  docFreq = 0;
  freqPointer = 0;
  proxPointer = 0;
  return self;
}

- (id) initWithDocFreq: (int) df freqPointer: (long) fp proxPointer: (long) pp
{
  self = [self init];
  docFreq = df;
  freqPointer = fp;
  proxPointer = pp;
  return self;
}

- (id) initWithTermInfo: (LCTermInfo *) ti
{
  self = [self initWithDocFreq: [ti docFreq]
                   freqPointer: [ti freqPointer]
		   proxPointer: [ti proxPointer]];
  skipOffset = [ti skipOffset];
  return self;
}

- (int) docFreq
{
  return docFreq;
}

- (long) freqPointer
{
  return freqPointer;
}

- (long) proxPointer
{
  return proxPointer;
}

- (int) skipOffset
{
  return skipOffset;
}

- (void) setDocFreq: (int) df freqPointer: (long) fp
            proxPointer: (long) pp skipOffset: (int) so
{
  docFreq = df;
  freqPointer = fp;
  proxPointer = pp;
  skipOffset = so;
}

- (void) setTermInfo: (LCTermInfo *) ti
{
  docFreq = [ti docFreq];
  freqPointer = [ti freqPointer];
  proxPointer = [ti proxPointer];
  skipOffset = [ti skipOffset];
}

- (void) setDocFreq: (int) doc
{
  docFreq = doc;
}

- (void) setFreqPointer: (long) freq
{
  freqPointer = freq;
}

- (void) setProxPointer: (long) prox
{
  proxPointer = prox;
}

- (void) setSkipOffset: (int) skip
{
  skipOffset = skip;
}

@end
