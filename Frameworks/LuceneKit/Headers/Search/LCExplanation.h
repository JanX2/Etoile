#ifndef __LUCENE_SEARCH_EXPLANATION__
#define __LUCENE_SEARCH_EXPLANATION__

#include <Foundation/Foundation.h> // Serializable
@interface LCExplanation: NSObject
{
  float value;
  NSString *description;
  NSArray *details
}

- (id) initWithValue: (float) v description: (NSString *) d;
- (float) value;
- (void) setDescription: (NSString *) d;
- (NSArray *) details;
- (void) addDetails: (LCExplanation *) details;
- (NSString *) descriptionWithDepth: (int) depth;
- (NSString *) descriptionWithHTML;
@end
#endif /* __LUCENE_SEARCH_EXPLANATION__ */
