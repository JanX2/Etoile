#ifndef __LUCENE_ANALYSIS_TOKEN_FILTER__
#define __LUCENE_ANALYSIS_TOKEN_FILTER__

#include <Foundation/Foundation.h>
#include "LCTokenStream.h"

@interface LCTokenFilter: LCTokenStream
{
  LCTokenStream *input;
}

- (id) initWithTokenStream: (LCTokenStream *) input;

@end

#endif /* __LUCENE_ANALYSIS_TOKEN_FILTER__ */
