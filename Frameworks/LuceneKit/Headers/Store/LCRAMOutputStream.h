#ifndef __LUCENE_STORE_RAM_OUTPUT_STREAM__
#define __LUCENE_STORE_RAM_OUTPUT_STREAM__

#include "Store/LCIndexOutput.h"

@class LCRAMFile;

@interface LCRAMOutputStream: LCIndexOutput
{
  LCRAMFile *file;
  int pointer;
}

- (id) initWithFile: (LCRAMFile *) f;
- (void) writeTo: (LCIndexOutput *) o;
- (void) reset;

@end

#endif /* __LUCENE_STORE_RAM_OUTPUT_STREAM__ */
