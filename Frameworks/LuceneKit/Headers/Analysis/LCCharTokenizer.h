#ifndef __LUCENE_ANALYSIS_CHAR_TOKENIZER__
#define __LUCENE_ANALYSIS_CHAR_TOKENIZER__

#include "LCTokenizer.h"

#define MAX_WORD_LEN 256
#define IO_BUFFER_SIZE 1024

@interface LCCharTokenizer: LCTokenizer
{
  int offset, bufferIndex, dataLen;
  unichar buffer[MAX_WORD_LEN], ioBuffer[IO_BUFFER_SIZE];
}

- (BOOL) isTokenChar: (char) c;
- (char) normalize: (char) c;

@end

#endif /* __LUCENE_ANALYSIS_CHAR_TOKENIZER__ */
