#ifndef __LUCENE_STORE_RAM_INPUT_STREAM__
#define __LUCENE_STORE_RAM_INPUT_STREAM__

#include "LCIndexInput.h"
#include "LCRAMFile.h"

@interface LCRAMInputStream: LCIndexInput
{
  LCRAMFile *file;
  unsigned long long pointer;
}

- (id) initWithFile: (LCRAMFile *) file;
@end

#endif /* __LUCENE_STORE_RAM_INPUT_STREAM__ */
