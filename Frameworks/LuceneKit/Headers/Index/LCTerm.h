#ifndef __LUCENE_INDEX_TERM__
#define __LUCENE_INDEX_TERM__

#include <Foundation/Foundation.h>

@interface LCTerm: NSObject
{
  NSString *field;
  NSString *text;
}

- (id) initWithField: (NSString *) fld text: (NSString *) txt;
- (NSString *) field;
- (NSString *) text;
- (NSComparisonResult) compareTo: (LCTerm *) other;
- (void) setField: (NSString *) fld text: (NSString *) txt;

@end

#endif /* __LUCENE_INDEX_TERM__ */
