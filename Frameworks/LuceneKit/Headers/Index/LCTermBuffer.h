#ifndef __LUCENE_INDEX_TERM_BUFFER__
#define __LUCENE_INDEX_TERM_BUFFER__

#include <Foundation/Foundation.h>

@class LCTerm;
@class LCIndexInput;
@class LCFieldInfos;

@interface LCTermBuffer: NSObject <NSCopying>
{
  NSString *field;
  NSMutableString *text;
  int textLength;
  LCTerm *term;
}

- (int) compareTo: (LCTermBuffer *) other;
- (NSComparisonResult) compareTo: (LCTermBuffer *) other;
- (NSComparisonResult) compareChars: (NSString *) v1 to: (NSString *) v2;
- (void) setTextLength: (int) newLength;
- (void) read: (LCIndexInput *) input
         fieldInfos: (LCFieldInfos *) fieldInfos;
- (void) setTerm: (LCTerm *) term;
- (void) setTermBuffer: (LCTermBuffer *) other;
- (int) textLength;
- (NSString *) text;
- (NSString *) field;
- (LCTerm *) term;
- (void) reset;
- (LCTerm *) toTerm;
- (void) setField: (NSString *) field text: (NSString *) text;

@end

#endif /* __LUCENE_INDEX_TERM_BUFFER__ */
