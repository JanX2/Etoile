#ifndef __LUCENE_SEARCH_SORT__
#define __LUCENE_SEARCH_SORT__

#include <Foundation/Foundation.h>

@interface LCSort: NSObject // Serializable
{
  LCSort *RELEVANCE;
  LCSort *INDEXORDER;
  NSArray *fields;
}
- (id) initWithField: (NSString *) field;
- (id) initWithField: (NSString *) field reverse: (BOOL) reverse;
- (id) initWithFields: (NSString *) fields;
- (id) initWithSortField: (LCSortField *) field;
- (id) initWithSortFields: (LCSortFields *) fields;
- (void) setField: (NSString *) field;
- (void) setField: (NSString *) field reverse: (BOOL) reverse;
- (void) setFields: (NSArray *) fields;
- (void) setSortField: (LCSortField *) field;
- (void) setSortFields: (NSArray *) fields;
- (NSArray *) sort;
@end
#endif /* __LUCENE_SEARCH_SORT__ */
