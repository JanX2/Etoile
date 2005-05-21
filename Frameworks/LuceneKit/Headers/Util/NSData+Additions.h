#ifndef __LuceneKit_Util_NSData_Additions__
#define __LuceneKit_Util_NSData_Additions__


#include <Foundation/Foundation.h>

@interface NSData (LuceneKit_Util)
/* LuceneKit: NSData have no idea whether the data is compressed.
 * Users are responsible for tracking it.
 * Decompress an un-compressedData give a unpredictable result.
 * zlib is used for compression.
 */
- (NSData *) compressedData;
- (NSData *) decompressedData;

@end

#endif /* __LuceneKit_Util_NSData_Additions__ */
