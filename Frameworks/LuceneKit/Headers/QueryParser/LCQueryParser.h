#ifndef __LuceneKit_LCQuery_Parser__
#define __LuceneKit_LCQuery_Parser__

#include <Foundation/Foundation.h>
#include "LCQuery.h"

/** It parse a query string into LCQuery.
 * Since there is JavaCC for GNUstep,
 * It is written from scratch to 
 * match Apache Lucene specification when it is done..
 */
@interface LCQueryParser: NSObject
+ (LCQuery *) parse: (NSString *) query;
@end

#endif /* __LuceneKit_LCQuery_Parser__ */

